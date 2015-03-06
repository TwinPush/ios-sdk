//
//  TPTwinPushRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 04/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

static NSString* ServerURLKey = nil;
static NSString* kBaseResourceName = @"apps";
static NSString* kDeviceResourceName = @"devices";
static NSString* kNotificationResourceName = @"notifications";

@implementation TPTwinPushRequest

#pragma mark - Init

+ (void)setServerURL:(NSString*)serverURL {
    ServerURLKey = [serverURL copy];
}

- (NSMutableURLRequest *)createRequest {
    NSString* baseUrl = ServerURLKey;
    if ([baseUrl characterAtIndex:baseUrl.length - 1] != '/') {
        baseUrl = [baseUrl stringByAppendingString:@"/"];
    }
    if (self.appId != nil) {
        baseUrl = [NSString stringWithFormat:@"%@%@/%@/", baseUrl, kBaseResourceName, self.appId];
    }
    if (self.deviceId != nil) {
        baseUrl = [NSString stringWithFormat:@"%@%@/%@/", baseUrl, kDeviceResourceName, self.deviceId];
    }
    if (self.notificationId != nil) {
        baseUrl = [NSString stringWithFormat:@"%@%@/%@/", baseUrl, kNotificationResourceName, self.notificationId];
    }
    self.baseServerUrl = baseUrl;
    TCLog(@"URL: %@", self.baseServerUrl);
    
    NSMutableURLRequest* request = [super createRequest];
    if (self.apiKey != nil) {
        [request addValue:self.apiKey forHTTPHeaderField:@"X-TwinPush-REST-API-Token"];
    }
    return request;
}

@end
