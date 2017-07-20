//
//  TPGetAliasNotificationsRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPGetAliasNotificationsRequest.h"
#import "NSDictionary+ArrayForKey.h"

/* Request info */
static NSString* const kResourceName = @"inbox";
static NSString* const kPerPage = @"per_page";
static NSString* const kPage = @"page";

/* Response parameters */
static NSString* const kObjectsResponseWrapper = @"objects";
static NSString* const kReferencesResponseWrapper = @"references";

@implementation TPGetAliasNotificationsRequest

- (id)initGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
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
