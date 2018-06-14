//
//  TPRegisterInformation.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 14/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import "TPRegisterInformation.h"
#import "TwinPushManager.h"
#import <sys/utsname.h>

static NSString* const kTokenKey = @"push_token";
static NSString* const kDeviceAliasKey = @"alias_device";
static NSString* const kUDIDKey = @"udid";
static NSString* const kPlatformKey = @"platform";
static NSString* const kPlatformValue = @"ios";
static NSString* const kLanguageKey = @"language";
static NSString* const kDeviceCodeKey = @"device_code";
static NSString* const kDeviceModelKey = @"device_model";
static NSString* const kDeviceManufacturerKey = @"device_manufacturer";
static NSString* const kDeviceManufacturerValue = @"Apple";
static NSString* const kSDKVersionKey = @"sdk_version";
static NSString* const kAppVersionKey = @"app_version";
static NSString* const kOSVersionKey = @"os_version";
static NSString* const kOSNameKey = @"os_name";
static NSString* const kBundleIdentifierKey = @"bundle_identifier";

@implementation TPRegisterInformation

- (id)initWithToken:(NSString*)token deviceAlias:(NSString*)deviceAlias UDID:(NSString*)udid {
    if (( self = [super init] )) {
        self.token = token;
        self.deviceAlias = deviceAlias;
        self.udid = udid;
    }
    return self;
}

- (NSString *)platform {
    return kPlatformValue;
}

- (NSString *)language {
    return [NSLocale currentLocale].localeIdentifier;
}

- (NSString *)deviceCode {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString: systemInfo.machine encoding: NSUTF8StringEncoding];
}

- (NSString *)deviceModel {
    return [UIDevice currentDevice].model;
}

- (NSString *)deviceManufacturer {
    return kDeviceManufacturerValue;
}

- (NSString *)sdkVersion {
    return [TwinPushManager manager].versionNumber;
}

- (NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)osName {
    return [UIDevice currentDevice].systemName;
}

- (NSString *)osVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSDictionary*) toDictionary {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    if (_token != nil) {
        dict[kTokenKey] = _token;
    }
    if (_deviceAlias != nil) {
        dict[kDeviceAliasKey] = _deviceAlias;
    }
    dict[kUDIDKey] = _udid;
    
    // Add SDK, App and OS static properties
    dict[kAppVersionKey] = self.appVersion;
    dict[kSDKVersionKey] = self.sdkVersion;
    dict[kBundleIdentifierKey] = self.bundleIdentifier;
    dict[kLanguageKey] = self.language;
    
    dict[kPlatformKey] = self.platform;
    dict[kDeviceManufacturerKey] = self.deviceManufacturer;
    dict[kDeviceModelKey] = self.deviceModel;
    dict[kDeviceCodeKey] = self.deviceCode;
    dict[kOSVersionKey] = self.osVersion;
    dict[kOSNameKey] = self.osName;
    return dict;
}

@end
