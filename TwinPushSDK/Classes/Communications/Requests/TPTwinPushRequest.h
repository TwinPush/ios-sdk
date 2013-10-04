//
//  TPTwinPushRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 04/04/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPRESTJSONRequest.h"

@interface TPTwinPushRequest : TPRESTJSONRequest

@property (strong, nonatomic) NSString* appId;
@property (strong, nonatomic) NSString* apiKey;

@end
