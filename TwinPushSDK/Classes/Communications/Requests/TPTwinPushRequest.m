//
//  TPTwinPushRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 04/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"
#import "ASIHTTPRequest.h"

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

- (ASIHTTPRequest *)createAsiRequest {
    if (self.appId != nil) {
        NSString* appIdSegment = self.appId != nil ? [NSString stringWithFormat:@"%@/%@/", kBaseResourceName, self.appId] : @"";
        self.baseServerUrl = [NSString stringWithFormat:@"%@%@", kServerURLKey, appIdSegment];
    }
    else {
        self.baseServerUrl = kServerURLKey;
    }
    TCLog(@"URL: %@", self.baseServerUrl);
    
    ASIHTTPRequest* request = [super createAsiRequest];
    [request addRequestHeader:@"X-TwinPush-REST-API-Token" value:self.apiKey];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    return request;
}

@end
