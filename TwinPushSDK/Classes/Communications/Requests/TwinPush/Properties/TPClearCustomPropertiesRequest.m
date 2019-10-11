//
//  TPClearCustomPropertiesRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 11/10/2019.
//  Copyright © 2019 TwinCoders. All rights reserved.
//

#import "TPClearCustomPropertiesRequest.h"

/* Request info */
static NSString* const kResourceName = @"clear_custom_properties";

@implementation TPClearCustomPropertiesRequest

- (instancetype)initClearCustomPropertiesRequestWithDeviceId:(NSString *)deviceId appId:(NSString *)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodDELETE;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete();
        };
    }
    return self;
}

@end
