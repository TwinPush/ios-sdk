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

@implementation TPTwinPushRequest

#pragma mark - Init

+ (void)setServerURL:(NSString*)serverURL {
    ServerURLKey = [serverURL copy];
}

- (NSMutableURLRequest *)createRequest {
    if (self.appId != nil) {
        NSString* appIdSegment = self.appId != nil ? [NSString stringWithFormat:@"%@/%@/", kBaseResourceName, self.appId] : @"";
        self.baseServerUrl = [NSString stringWithFormat:@"%@%@", ServerURLKey, appIdSegment];
    }
    else {
        self.baseServerUrl = ServerURLKey;
    }
    TCLog(@"URL: %@", self.baseServerUrl);
    
    NSMutableURLRequest* request = [super createRequest];
    [request addValue:self.apiKey forHTTPHeaderField:@"X-TwinPush-REST-API-Token"];
    return request;
}

@end
