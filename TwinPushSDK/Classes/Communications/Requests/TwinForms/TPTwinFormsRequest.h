//
//  TPTwinFormsRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/07/14.
//  Copyright (c) 2014 TwinCoders. All rights reserved.
//

#import "TPRESTJSONRequest.h"
#import "TPNotification.h"

@interface TPTwinFormsRequest : TPRESTJSONRequest

+ (void)setServerURL:(NSString*)serverURL;

- (id)initFormRequestWithUserId:(NSString*)userId
                       deviceId:(NSString*)deviceId
                   notification:(TPNotification*)notification
                          appId:(NSString*)appId
                  reporterToken:(NSString*)reporterToken
                   formContents:(NSDictionary*)formContents
                     onComplete:(TPRequestSuccessBlock)onComplete
                        onError:(TPRequestErrorBlock)onError;

@end
