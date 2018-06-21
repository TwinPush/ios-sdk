//
//  TPGetNotificationWithIdRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 07/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPGetNotificationWithIdRequest.h"
#import "NSDictionary+ArrayForKey.h"

static NSString* const kErrorDomain  = @"com.twincoders.TCBaseRequest";

/* Request info */
static NSString* const kSegmentParamNotifications = @"notifications";

@implementation TPGetNotificationWithIdRequest

- (id)initGetDeviceNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        [self addSegmentParam:kSegmentParamNotifications];
        [self addSegmentParam:notificationId];
        self.requestMethod = kTPRequestMethodGET;
        // Set resource name
        self.appId = appId;
        self.deviceId = deviceId;
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            TPNotification* notification = [TPNotification notificationFromDictionary:responseDictionary];
            onComplete(notification);
        };
    }
    return self;
}

@end
