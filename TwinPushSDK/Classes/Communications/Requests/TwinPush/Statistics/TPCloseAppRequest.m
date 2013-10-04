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
static NSString* const kDeviceIdKey = @"id";

@implementation TPCloseAppRequest

#pragma mark - Init

-(id) initCloseAppRequestWithDeviceId:(NSString*)deviceId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.apiKey = apiKey;
        // Add param tags
        [self addParam:deviceId forKey:kDeviceIdKey];
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
