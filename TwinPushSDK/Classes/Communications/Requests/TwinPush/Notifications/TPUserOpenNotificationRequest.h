//
//  TPUserOpenNotificationRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 01/07/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

@interface TPUserOpenNotificationRequest : TPTwinPushRequest

/**
 @brief Constructor for TPUserOpenNotificationRequest
 @param notificationId The ID of the notification opened
 @param deviceId The device in which the user has opened the notification
 @param appId The ID of the application
 @param timeStamp The timestamp of the moment when the user opened the notification
 @param onError Block that will be executed if the device is not correct
 */
- (id)initUserOpenNotificationRequestWithNotificationId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
