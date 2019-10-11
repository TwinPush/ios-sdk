//
//  TPClearCustomPropertiesRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 11/10/2019.
//  Copyright © 2019 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

NS_ASSUME_NONNULL_BEGIN

/** Clears all custom properties for the current device */
@interface TPClearCustomPropertiesRequest : TPTwinPushRequest

- (instancetype)initClearCustomPropertiesRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end

NS_ASSUME_NONNULL_END
