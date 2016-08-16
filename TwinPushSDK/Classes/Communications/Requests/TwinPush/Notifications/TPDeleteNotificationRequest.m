//
//  TPDeleteNotificationRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 12/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPDeleteNotificationRequest.h"

/* Request info */
static NSString* const kSegmentParamNotifications = @"notifications";


@implementation TPDeleteNotificationRequest

- (id)initDeleteNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        [self addSegmentParam:kSegmentParamNotifications];
        [self addSegmentParam:notificationId];
        self.requestMethod = kTPRequestMethodDELETE;
        // Set resource name
        self.appId = appId;
        self.deviceId = deviceId;
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = onComplete;
    }
    return self;
}

@end
