//
//  TPUpdateBadgeRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 19/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

typedef void(^UpdateBadgeResponse)();

@interface TPUpdateBadgeRequest : TPTwinPushRequest

/**
 @brief Constructor for TPUpdateBadgeRequest
 @param badgeCount Badge count to be stored in the server
 @param deviceId The ID of the device which is asking for the notification
 @param onComplete Block that will be executed if we obtain the notification with the specified id
 @param onError Block that will be executed if the device is not correct
 */
- (id)initUpdateBadgeRequestWithCount:(NSUInteger)badgeCount forDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(UpdateBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError;

@end
