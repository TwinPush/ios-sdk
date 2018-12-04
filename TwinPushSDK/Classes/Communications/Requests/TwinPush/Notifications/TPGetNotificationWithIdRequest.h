//
//  TPGetNotificationWithIdRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 07/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"
#import "TPNotification.h"

typedef void(^GetDeviceNotificationWithIdResponseBlock)(TPNotification* notification);

@interface TPGetNotificationWithIdRequest : TPTwinPushRequest

/**
 @brief Constructor for GetDeviceNotificationWithId
 @param notificationId The notification's ID of the notification we are asking for
 @param onComplete Block that will be executed if we obtain the notification with the specified id
 @param onError Block that will be executed if the device is not correct
 */
- (id)initGetDeviceNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
