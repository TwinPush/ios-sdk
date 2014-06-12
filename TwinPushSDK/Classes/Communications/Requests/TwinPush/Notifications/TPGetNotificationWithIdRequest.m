//
//  TPGetNotificationWithIdRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 07/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPGetNotificationWithIdRequest.h"
#import "NSDictionary+ArrayForKey.h"

/* Request info */
static NSString* const kSegmentParamNotifications = @"notifications";

/* Response parameters */
static NSString* const kObjectsResponseWrapper = @"objects";

@implementation TPGetNotificationWithIdRequest

- (id)initGetDeviceNotificationWithId:(NSInteger)notificationId appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        [self addSegmentParam:kSegmentParamNotifications];
        [self addSegmentParam:[NSString stringWithFormat:@"%ld", (long)notificationId]];
        self.requestMethod = kTPRequestMethodGET;
        // Set resource name
        self.apiKey = apiKey;
        self.appId = appId;
        // Set response handler blocks
        self.onError = onError;
        id __weak wself = self;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            TPNotification* notification = [wself notificationFromDictionary:responseDictionary];
            onComplete(notification);
        };
    }
    return self;
}

#pragma mark - Private methods

- (TPNotification*)notificationFromDictionary:(NSDictionary*)dictionary {
    NSArray* objectsDict = [dictionary arrayForKey:kObjectsResponseWrapper];
    NSDictionary* notificationDict = [objectsDict objectAtIndex:0];
    
    TPNotification* notification = [TPNotification notificationFromDictionary:notificationDict];
    return notification;
}

@end
