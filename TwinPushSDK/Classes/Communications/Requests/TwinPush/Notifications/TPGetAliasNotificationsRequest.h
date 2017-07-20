//
//  TPGetAliasNotificationsRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"
#import "TPNotificationsPagination.h"
#import "TPInboxNotification.h"

typedef void(^GetAliasNotificationsResponseBlock)(NSArray<TPInboxNotification*>* array, BOOL hasMore);

@interface TPGetAliasNotificationsRequest : TPTwinPushRequest

/**
 @brief Constructor for TPGetAliasNotificationsRequest
 @param deviceId The Device id for which we want to get the notifications
 @param pagination The pagination to apply in the results of the notification search
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (id)initGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
