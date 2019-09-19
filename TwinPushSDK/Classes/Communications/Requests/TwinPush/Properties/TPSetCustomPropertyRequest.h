//
//  TPSetCustomPropertyRequest.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 31/05/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

typedef enum {
    TPPropertyTypeString,
    TPPropertyTypeBoolean,
    TPPropertyTypeInteger,
    TPPropertyTypeFloat,
    TPPropertyTypeEnum,
    TPPropertyTypeEnumList
} TPPropertyType;

@interface TPSetCustomPropertyRequest : TPTwinPushRequest

/**
 @brief Constructor for SetCustomPropertyRequest
 @param deviceId The Device id for which we want to get the notifications
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (id)initSetCustomPropertyRequestWithName:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
