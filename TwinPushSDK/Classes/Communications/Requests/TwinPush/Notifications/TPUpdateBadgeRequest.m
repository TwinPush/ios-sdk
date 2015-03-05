//
//  TPUpdateBadgeRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 19/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPUpdateBadgeRequest.h"

/* Request info */
static NSString* const kResourceName = @"update_badge";

/* Request parameters */
static NSString* const kBadgeCountKey = @"badge";

@implementation TPUpdateBadgeRequest

- (id)initUpdateBadgeRequestWithCount:(NSUInteger)badgeCount forDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(UpdateBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError {
    if (( self = [super init] )) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        // Set request parameters
        [self addParam:[@(badgeCount) stringValue] forKey:kBadgeCountKey];
        // Set response handler blocks
        self.onComplete = ^(NSDictionary* dict){
            onComplete();
        };
        self.onError = onError;
    }
    return self;
}

@end
