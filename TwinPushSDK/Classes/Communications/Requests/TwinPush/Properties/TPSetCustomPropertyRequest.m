//
//  TPSetCustomPropertyRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 13/12/12.
//
//

#import "TPSetCustomPropertyRequest.h"
#import "NSDictionary+ArrayForKey.h"
#import "TPNotification.h"
#import "TPRequestParam.h"

/* Request info */
static NSString* const kResourceName = @"set_custom_property";
static NSString* const kNameKey = @"name";
static NSString* const kTypeKey = @"type";
static NSString* const kValueKey = @"value";

/* Value types */
static NSString* const kTypeString = @"string";
static NSString* const kTypeBoolean = @"boolean";
static NSString* const kTypeInteger = @"integer";
static NSString* const kTypeFloat = @"float";
static NSString* const kTypeEnum = @"enum";

@implementation TPSetCustomPropertyRequest

#pragma mark - Init

- (id)initSetCustomPropertyRequestWithName:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.deviceId = deviceId;
        self.appId = appId;
        // Add param tags
        [self addParam:name forKey:kNameKey];
        [self addParam:[self stringForType:type] forKey:kTypeKey];
        [self addParam:(value != nil ? value : [NSNull null]) forKey:kValueKey];
        
        // Set response handler blocks
        self.onError = onError;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete();
        };
    }
    return self;
}

#pragma mark - Private methods

- (NSString*)stringForType:(TPPropertyType)type {
    NSString* value = nil;
    switch (type) {
        case TPPropertyTypeString:  value = kTypeString; break;
        case TPPropertyTypeBoolean: value = kTypeBoolean; break;
        case TPPropertyTypeInteger: value = kTypeInteger; break;
        case TPPropertyTypeFloat:   value = kTypeFloat; break;
        case TPPropertyTypeEnum:   value = kTypeEnum; break;
    }
    return value;
}

@end
