//
//  TPCloseAppRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 25/06/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPCloseAppRequest.h"

/* Request info */
static NSString* const kResourceName = @"close_app";
static NSString* const kTimestampKey = @"closed_at";

@implementation TPCloseAppRequest

#pragma mark - Init

-(id) initCloseAppRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        // Add param tags
        NSNumber* timestamp = @((long) [[NSDate date] timeIntervalSince1970]);
        [self addParam:timestamp forKey:kTimestampKey];
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete();
        };
    }
    return self;
}


@end
