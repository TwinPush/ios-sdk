//
//  TPUserOpenNotificationRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 01/07/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPUserOpenNotificationRequest.h"


//curl -X POST \
//-H "X-TwinPush-REST-API-Token: ${REST_API_TOKEN}" \
//-H "Content-Type: application/json" \
//-d '{ "device_id": 12, "notification_id": 10, "open_at": 1372665442 }' \
//http://app.twinpush.com/api/v1/open_notification


/* Request info */
static NSString* const kResourceName = @"open_notification";

/* Request parameters */
static NSString* const kNotificationIdKey = @"notification_id";
static NSString* const kOpenAtKey = @"open_at";

@implementation TPUserOpenNotificationRequest

- (id)initUserOpenNotificationRequestWithNotificationId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError {
    if (( self = [super init] )) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.appId = appId;
        self.deviceId = deviceId;
        // Set request parameters
        [self addParam:notificationId forKey:kNotificationIdKey];
        [self addParam:[NSString stringWithFormat:@"%ld", (long)NSTimeIntervalSince1970] forKey:kOpenAtKey];
        // Set response handler blocks
        self.onComplete = onComplete;
        self.onError = onError;
    }
    return self;
}

@end
