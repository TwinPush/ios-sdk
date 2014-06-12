//
//  TPGetDeviceNotificationsRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 13/12/12.
//
//

#import "TPGetDeviceNotificationsRequest.h"
#import "NSDictionary+ArrayForKey.h"
#import "TPNotification.h"
#import "TPRequestParam.h"

static NSString* const kNotificationTypeDelivery = @"Delivery";
static NSString* const kNotificationTypeTag = @"Tag";

/* Request info */
static NSString* const kResourceName = @"devices";
static NSString* const kSegmentParamNotifications = @"search_notifications";
static NSString* const kTags = @"tags";
static NSString* const kNoTags = @"no_tags";
static NSString* const kPerPage = @"per_page";
static NSString* const kPage = @"page";

/* Response parameters */
static NSString* const kObjectsResponseWrapper = @"objects";
static NSString* const kReferencesResponseWrapper = @"references";

@implementation TPGetDeviceNotificationsRequest

#pragma mark - Init

- (id)initGetDeviceNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        [self addSegmentParam:deviceId];
        [self addSegmentParam:kSegmentParamNotifications];
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.appId = appId;
        self.apiKey = apiKey;
        // Add param tags
        if (filters.tags.count > 0) {
            [self addParam:[TPRequestParam paramWithKey:kTags andArrayValue:filters.tags]];
        }
        if (filters.noTags.count > 0) {
            [self addParam:[TPRequestParam paramWithKey:kNoTags andArrayValue:filters.noTags]];
        }
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

#pragma mark - Private methods

- (NSArray*)notificationsFromDictionary:(NSDictionary*)dictionary {
    NSMutableArray* notifications = [NSMutableArray array];
    NSArray* notificationsDict = [dictionary arrayForKey:kObjectsResponseWrapper];
    
    for (NSDictionary* dict in notificationsDict) {
        TPNotification* notification = [TPNotification notificationFromDictionary:dict];
        [notifications addObject:notification];
    }
    return notifications;
}

@end
