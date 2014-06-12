//
//  TPTwinPushRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 04/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"

static NSString* kServerURLKey = @"https://app.twinpush.com/api/v2/";
static NSString* kBaseResourceName = @"apps";

@implementation TPTwinPushRequest

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (NSMutableURLRequest *)createRequest {
    if (self.appId != nil) {
        NSString* appIdSegment = self.appId != nil ? [NSString stringWithFormat:@"%@/%@/", kBaseResourceName, self.appId] : @"";
        self.baseServerUrl = [NSString stringWithFormat:@"%@%@", kServerURLKey, appIdSegment];
    }
    else {
        self.baseServerUrl = kServerURLKey;
    }
    TCLog(@"URL: %@", self.baseServerUrl);
    
    NSMutableURLRequest* request = [super createRequest];
    [request addValue:self.apiKey forHTTPHeaderField:@"X-TwinPush-REST-API-Token"];
    return request;
}

@end
