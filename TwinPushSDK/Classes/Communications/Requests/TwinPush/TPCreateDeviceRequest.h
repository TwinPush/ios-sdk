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

@interface TPCreateDeviceRequest : TPTwinPushRequest

/** Block that will be executed if login is successful */
typedef void(^CreateDeviceResponseBlock)(TPDevice* device);

/**
 @brief Constructor for CreateDeviceRequest
 @param token Token for getting the device id
 @param deviceAlias (Optional)
 @param onComplete Block that will be executed if the token is correct
 @param onError Block that will be executed if the token is not correct
 */
- (id)initCreateDeviceRequestWithToken:(NSString*)token deviceAlias:(NSString*)deviceAlias UDID:(NSString*)udid appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
