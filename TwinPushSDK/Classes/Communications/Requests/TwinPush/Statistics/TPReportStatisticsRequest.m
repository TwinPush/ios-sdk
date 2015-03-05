//
//  TPReportStatisticsRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 25/06/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPReportStatisticsRequest.h"

/* Request info */
static NSString* const kResourceName = @"report_statistics";
static NSString* const kLatitudeKey = @"latitude";
static NSString* const kLongitudeKey = @"longitude";
static NSString* const kDeviceKey = @"device";

@implementation TPReportStatisticsRequest

#pragma mark - Init

-(id) initReportStatisticsRequestWithCoordinate:(CLLocationCoordinate2D)coordinate deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        // Add param tags
        NSMutableDictionary* deviceStats = [NSMutableDictionary dictionaryWithCapacity:2];
        deviceStats[kLatitudeKey] = @(coordinate.latitude);
        deviceStats[kLongitudeKey] = @(coordinate.longitude);
        [self addParam:deviceStats forKey:kDeviceKey];
        
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete();
        };
    }
    return self;
}

@end
