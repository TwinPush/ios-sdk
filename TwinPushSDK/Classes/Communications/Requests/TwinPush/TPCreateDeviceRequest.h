//
//  TPCreateDeviceRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 13/12/12.
//
//

#import "TPDevice.h"
#import "TPTwinPushRequest.h"
#import "TPBaseRequest.h"
#import "TPRegisterInformation.h"

@interface TPCreateDeviceRequest : TPTwinPushRequest

/** Block that will be executed if login is successful */
typedef void(^CreateDeviceResponseBlock)(TPDevice* device);

/**
 @brief Constructor for CreateDeviceRequest
 @param info Device registration information
 @param appId Application identifier
 @param apiKey Application API key
 @param onComplete Block that will be executed if the token is correct
 @param onError Block that will be executed if the token is not correct
 */
- (id)initCreateDeviceRequestWithInfo:(TPRegisterInformation*)info appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
