//
//  TPCreateDeviceRequest.m
//  TwinPushSDK
//
//  Created by Diego Prados on 13/12/12.
//
//

#import "TPCreateDeviceRequest.h"
#import "NSDictionary+ArrayForKey.h"

static NSString* const kDateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

/* Request info */
static NSString* const kResourceName = @"devices/register";

// Content dictionary
static NSString* const kTokenKey = @"push_token";
static NSString* const kDeviceAliasKey = @"alias_device";
static NSString* const kUDIDKey = @"udid";
static NSString* const kPlatformKey = @"platform";
static NSString* const kPlatformValue = @"ios";

/* Response parameters */
static NSString* const kResponseWrapper = @"objects";
static NSString* const kResponseDeviceIdKey = @"id";
static NSString* const kResponseTokenKey = @"push_token";
static NSString* const kResponseDeviceAliasKey = @"alias_device";
static NSString* const kResponseCreationDateKey = @"created_at";
static NSString* const kResponseUpdateDateKey = @"updated_at";
static NSString* const kResponseLastRegistrationDateKey = @"last_registered_at";
static NSString* const kResponseAppIdKey = @"app_id";

@implementation TPCreateDeviceRequest

#pragma mark - Init

- (id)initCreateDeviceRequestWithToken:(NSString*)token deviceAlias:(NSString*)deviceAlias UDID:(NSString*)udid appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    self = [super init];
    if (self) {
        self.requestMethod = kTPRequestMethodPOST;
        // Set resource name
        self.resource = kResourceName;
        self.apiKey = apiKey;
        self.appId = appId;
        // Add request content
        if (token != nil) {
            [self addParam:token forKey:kTokenKey];
        }
        if (deviceAlias != nil) {
            [self addParam:deviceAlias forKey:kDeviceAliasKey];
        }
        [self addParam:udid forKey:kUDIDKey];
        [self addParam:kPlatformValue forKey:kPlatformKey];

        // Set response handler blocks
        self.onError = onError;
        id __weak request = self;
        self.onComplete = ^(NSDictionary* responseDictionary) {
            onComplete([request deviceFromDictionary:responseDictionary]);
        };
    }
    return self;
}

#pragma mark - Private methods

static NSDateFormatter* sDateFormatter = nil;
- (TPDevice*)deviceFromDictionary:(NSDictionary*)dictionary {
    NSArray* deviceArray = [dictionary arrayForKey:kResponseWrapper];
    TPDevice* device = nil;
    if (deviceArray.count > 0) {
        device = [[TPDevice alloc] init];
        if (sDateFormatter == nil) {
            sDateFormatter = [[NSDateFormatter alloc] init];
            [sDateFormatter setDateFormat:kDateFormat];
        }
        
        NSDictionary* deviceDict = deviceArray[0];
        device.deviceId = [deviceDict objectForKey:kResponseDeviceIdKey];
        device.token = [deviceDict objectForKey:kResponseTokenKey];
        device.deviceAlias = [deviceDict objectForKey:kResponseDeviceAliasKey];
        device.creationDate = [sDateFormatter dateFromString:[deviceDict objectForKey:kResponseCreationDateKey]];
        device.updateDate = [sDateFormatter dateFromString:[deviceDict objectForKey:kResponseUpdateDateKey]];
        device.lastRegistrationDate = [sDateFormatter dateFromString:[deviceDict objectForKey:kResponseLastRegistrationDateKey]];
        device.appId = [deviceDict objectForKey:kResponseAppIdKey];
    }
    return device;
}

@end
