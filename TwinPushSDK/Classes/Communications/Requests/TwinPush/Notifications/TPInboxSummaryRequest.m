//
//  TPInboxSummaryRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 4/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import "TPInboxSummaryRequest.h"

@implementation TPInboxSummaryRequest

static NSString* const kResourceName = @"inbox_summary";

- (id)initWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetInboxSummaryResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    if (( self = [super init] )) {
        self.requestMethod = kTPRequestMethodGET;
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            TPInboxSummary* result = [[TPInboxSummary alloc] init];
            result.totalCount = [responseDictionary[@"total_count"] integerValue];
            result.unopenedCount = [responseDictionary[@"unopened_count"] integerValue];
            onComplete(result);
        };
    }
    return self;
}

@end
