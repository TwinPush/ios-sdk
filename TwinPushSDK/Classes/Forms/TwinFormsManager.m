//
//  TwinFormsManager.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/07/14.
//  Copyright (c) 2014 TwinCoders. All rights reserved.
//

#import "TwinFormsManager.h"
#import "TwinPushManager.h"
#import "TPRequestLauncher.h"
#import "TPTwinFormsRequest.h"

static NSString* const kDefaultServerUrl = @" https://forms.twinpush.com/";
#define kDefaultCertificateNames @[@"*.twinpush.com", @"Starfield Secure Certificate Authority - G2", @"Starfield Root Certificate Authority - G2"]

@interface TwinFormsManager()
@property (nonatomic, copy) NSString* appId;
@property (nonatomic, copy) NSString* reporterToken;
@property (nonatomic, strong) TPRequestLauncher* requestLauncher;
@property (nonatomic, strong) NSMutableArray* activeRequests;
@end

@implementation TwinFormsManager

static TwinFormsManager *_sharedInstance;

- (id)init
{
    self = [super init];
    if (self) {
        self.requestLauncher = [[TPRequestLauncher alloc] init];
        _activeRequests = [NSMutableArray array];
        self.serverURL = kDefaultServerUrl;
    }
    return self;
}

#pragma mark - Shared instance

+ (TwinFormsManager*) manager {
    if (_sharedInstance == nil) {
        _sharedInstance = [[TwinFormsManager alloc] init];
    }
    return _sharedInstance;
}

- (void)setupTwinPushManagerWithAppId:(NSString *)appId reporterToken:(NSString *)token {
    self.appId = appId;
    self.reporterToken = token;
}

#pragma mark - Form requests
- (void)sendFormRequestWithUserId:(NSString*)userId deviceId:(NSString*)deviceId notification:(TPNotification*)notification formContents:(NSDictionary*)formContents {
    if (![self hasAppIdAndToken])
        return;
    
    TPBaseRequest* request = [[TPTwinFormsRequest alloc] initFormRequestWithUserId:userId
                                                                          deviceId:deviceId
                                                                      notification:notification
                                                                             appId:self.appId
                                                                     reporterToken:self.reporterToken
                                                                      formContents:formContents
                                                                        onComplete:^{
                                                                            TCLog(@"TwinForms request success");
                                                                        } onError:^(NSError *error) {
                                                                            TCLog(@"TwinForms request error: %@", error);
                                                                        }];
    [self enqueueRequest:request];
}

- (void)sendFormRequestWithUserId:(NSString*)userId notification:(TPNotification*)notification formContents:(NSDictionary*)formContents {
    NSString* deviceId = [TwinPushManager manager].deviceId;
    [self sendFormRequestWithUserId:userId deviceId:deviceId notification:notification formContents:formContents];
}

#pragma mark - Certificate pinning
- (void)enableCertificateNamePinningWithDefaultValues {
    [self enableCertificateNamePinningWithCertificateNames:kDefaultCertificateNames];
}

- (void)enableCertificateNamePinningWithCertificateNames:(NSArray*)certificateNames {
    self.requestLauncher.expectedCertNames = certificateNames;
}

- (void)disableCertificateNamePinning {
    [self enableCertificateNamePinningWithCertificateNames:nil];
}

#pragma mark - Private methods
-(void) enqueueRequest:(TPBaseRequest*)request {
    request.requestLauncher = self.requestLauncher;
    [request addRequestEndDelegate:self];
    [self.activeRequests addObject:request];
    [request start];
}

- (BOOL)hasAppIdAndToken {
    if (_appId == nil || _reporterToken == nil) {
        [self displayAlert:NSLocalizedStringWithDefaultValue(@"APPID_APIKEY_MISSING_MESSAGE", nil, [NSBundle mainBundle], @"You have to set the values for the AppId and the ApiKey", nil) withTitle:NSLocalizedStringWithDefaultValue(@"APPID_APIKEY_MISSING_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
        return  NO;
    }
    return YES;
}

- (void)displayAlert:(NSString*)alert withTitle:(NSString*)title {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:alert delegate:self cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"DEVICE_REGISTERED_ALERT_ACCEPT_BUTTON", nil, [NSBundle mainBundle], @"Accept", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - TPRequestEndDelegate

- (void) requestDidFinish:(TPBaseRequest *)aRequest {
    if ([self.activeRequests containsObject:aRequest]) {
        [self.activeRequests removeObject:aRequest];
    }
}

@end
