//
//  TPTwinPushRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 04/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPRESTJSONRequest.h"

@interface TPTwinPushRequest : TPRESTJSONRequest

+ (void)setServerURL:(NSString*)serverURL;

@property (strong, nonatomic) NSString* deviceId;
@property (strong, nonatomic) NSString* appId;
@property (strong, nonatomic) NSString* apiKey;

@end
