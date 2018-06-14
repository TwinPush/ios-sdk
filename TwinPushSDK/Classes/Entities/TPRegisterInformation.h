//
//  TPRegisterInformation.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 14/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPRegisterInformation : NSObject

@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSString* deviceAlias;
@property (nonatomic, copy) NSString* udid;

@property (readonly) NSString* platform;
@property (readonly) NSString* language;
@property (readonly) NSString* deviceCode;
@property (readonly) NSString* deviceModel;
@property (readonly) NSString* deviceManufacturer;
@property (readonly) NSString* sdkVersion;
@property (readonly) NSString* appVersion;
@property (readonly) NSString* osName;
@property (readonly) NSString* osVersion;
@property (readonly) NSString* bundleIdentifier;

- (id)initWithToken:(NSString*)token deviceAlias:(NSString*)deviceAlias UDID:(NSString*)udid;
- (NSDictionary*) toDictionary;

@end
