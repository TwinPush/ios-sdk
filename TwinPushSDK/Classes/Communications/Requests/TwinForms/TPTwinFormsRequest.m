//
//  TPTwinFormsRequest.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/07/14.
//  Copyright (c) 2014 TwinCoders. All rights reserved.
//

#import "TPTwinFormsRequest.h"

@implementation TPTwinFormsRequest

static NSString* ServerURLKey = nil;
static NSString* kBaseResource = @"apps/%@/report";

static NSString* kReporterTokenKey = @"reporter_token";
static NSString* kNotificationIdKey = @"notification_id";
static NSString* kTitleKey = @"title";
static NSString* kMessageKey = @"message";
static NSString* kDeviceIdKey = @"device_id";
static NSString* kUserIdKey = @"alias";
static NSString* kFormKey = @"form";

#pragma mark - Init

+ (void)setServerURL:(NSString*)serverURL {
    ServerURLKey = [serverURL copy];
}

- (NSMutableURLRequest *)createRequest {
    self.baseServerUrl = ServerURLKey;
    return [super createRequest];
}

- (id)initFormRequestWithUserId:(NSString*)userId
                       deviceId:(NSString*)deviceId
                   notification:(TPNotification*)notification
                          appId:(NSString*)appId
                  reporterToken:(NSString*)reporterToken
                   formContents:(NSDictionary*)formContents
                     onComplete:(TPRequestSuccessBlock)onComplete
                        onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = [NSString stringWithFormat:kBaseResource, appId];
        
        // Add param tags
        [self addParam:reporterToken forKey:kReporterTokenKey];
        [self addParam:notification.notificationId forKey:kNotificationIdKey];
        [self addParam:notification.title forKey:kTitleKey];
        [self addParam:notification.message forKey:kMessageKey];
        [self addParam:deviceId forKey:kDeviceIdKey];
        [self addParam:userId forKey:kUserIdKey];
        [self addDictionaryParam:formContents forKey:kFormKey];
        
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete();
        };
    }
    return self;
}

@end
