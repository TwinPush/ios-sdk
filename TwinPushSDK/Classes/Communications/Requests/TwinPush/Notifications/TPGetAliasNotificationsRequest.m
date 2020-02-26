//
//  TPGetAliasNotificationsRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPGetAliasNotificationsRequest.h"
#import "NSDictionary+ArrayForKey.h"
#import "TPRequestParam.h"

/* Request info */
static NSString* const kResourceName = @"inbox";
static NSString* const kPerPage = @"per_page";
static NSString* const kPage = @"page";
static NSString* const kTags = @"tags";
static NSString* const kNoTags = @"no_tags";

/* Response parameters */
static NSString* const kObjectsResponseWrapper = @"objects";
static NSString* const kReferencesResponseWrapper = @"references";

@implementation TPGetAliasNotificationsRequest

- (id)initGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodGET;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        if (pagination == nil) {
            pagination = [[TPNotificationsPagination alloc] init];
            pagination.page = 1;
        }
        [self addParam:[NSString stringWithFormat:@"%ld", (long)pagination.resultsPerPage] forKey:kPerPage];
        [self addParam:[NSString stringWithFormat:@"%ld", (long)pagination.page] forKey:kPage];
        
        // Add param tags
        if (filters.tags.count > 0) {
            [self addParam:[TPRequestParam paramWithKey:kTags andArrayValue:filters.tags]];
        }
        if (filters.noTags.count > 0) {
            [self addParam:[TPRequestParam paramWithKey:kNoTags andArrayValue:filters.noTags]];
        }
        
        // Set response handler blocks
        self.onError = onError;
        id __weak wself = self;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            NSArray* notifications = [wself notificationsFromDictionary:responseDictionary];
            BOOL hasMore = notifications.count == pagination.resultsPerPage;
            onComplete(notifications, hasMore);
        };
    }
    return self;
}

- (id)initGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId  pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    return [self initGetAliasNotificationsRequestWithDeviceId:deviceId filters:nil pagination:pagination appId:appId onComplete:onComplete onError:onError];
}

- (NSArray*)notificationsFromDictionary:(NSDictionary*)dictionary {
    NSMutableArray* notifications = [NSMutableArray array];
    NSArray* notificationsDict = [dictionary arrayForKey:kObjectsResponseWrapper];
    
    for (NSDictionary* dict in notificationsDict) {
        TPNotification* notification = [TPInboxNotification inboxNotificationFromDictionary:dict];
        [notifications addObject:notification];
    }
    return notifications;
}

@end
