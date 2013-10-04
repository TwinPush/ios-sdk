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
 @param deviceId The device in which the user has opened the notification
 @param notificationId The ID of the notification opened
 @param timeStamp The timestamp of the moment when the user opened the notification
 @param onError Block that will be executed if the device is not correct
 */
- (id)initUserOpenNotificationRequestWithDeviceId:(NSString*)deviceId notificationId:(NSString*)notificationId apiKey:(NSString*)apiKey onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
