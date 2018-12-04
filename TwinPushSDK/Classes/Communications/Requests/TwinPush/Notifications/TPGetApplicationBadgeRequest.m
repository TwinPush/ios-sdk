//
//  TPGetApplicationBadgeRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 6/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import "TPGetApplicationBadgeRequest.h"

@implementation TPGetApplicationBadgeRequest

static NSString* const kResourceName = @"badge";

- (id)initWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetApplicationBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError {
    
    if (( self = [super init] )) {
        self.requestMethod = kTPRequestMethodGET;
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            NSInteger badgeCount = 0;
            id response = responseDictionary[@"badge"];
            if ([response isKindOfClass:[NSNumber class]] || [response isKindOfClass:[NSString class]]) {
                badgeCount = [response integerValue];
            }
            onComplete(badgeCount);
        };
    }
    return self;
}

@end
