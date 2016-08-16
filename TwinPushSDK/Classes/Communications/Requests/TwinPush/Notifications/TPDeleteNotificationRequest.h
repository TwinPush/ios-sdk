//
//  TPDeleteNotificationRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 12/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

typedef void(^DeleteNotificationResponseBlock)();

@interface TPDeleteNotificationRequest : TPTwinPushRequest

/**
 @brief Constructor for TPDeleteNotificationRequest
 @param notificationId The notification's ID of the notification we are deleting
 @param onComplete Block that will be executed after a successful deletion
 @param onError Block that will be executed if the device is not correct
 */
- (id)initDeleteNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
