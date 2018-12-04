//
//  TPGetApplicationBadgeRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 6/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

typedef void(^GetApplicationBadgeResponse)(NSInteger);

@interface TPGetApplicationBadgeRequest : TPTwinPushRequest

- (id)initWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetApplicationBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError;

@end
