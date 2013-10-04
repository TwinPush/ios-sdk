//
//  TPCloseAppRequest.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 25/06/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

@interface TPCloseAppRequest : TPTwinPushRequest

-(id) initCloseAppRequestWithDeviceId:(NSString*)deviceId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
