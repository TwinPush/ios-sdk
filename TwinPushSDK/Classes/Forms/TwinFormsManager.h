//
//  TwinFormsManager.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/07/14.
//  Copyright (c) 2014 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPBaseRequest.h"
#import "TPNotification.h"


@interface TwinFormsManager : NSObject<TPRequestEndDelegate>

/** TwinForms Server URL. Change this URL if you have a custom URL for Enterprise hosted applications */
@property (nonatomic, copy) NSString* serverURL;
/** App identifier, provided by the web portal */
@property (nonatomic, copy, readonly) NSString* appId;
/** Security token provided by the web portal */
@property (nonatomic, copy, readonly) NSString* reporterToken;

#pragma mark - Setup
- (void)setupTwinPushManagerWithAppId:(NSString*)appId reporterToken:(NSString*)token;

#pragma mark - Shared instance
+ (TwinFormsManager*) manager;

#pragma mark - Certificate pinning
- (void)enableCertificateNamePinningWithDefaultValues;
- (void)enableCertificateNamePinningWithCertificateNames:(NSArray*)certificateNames;
- (void)disableCertificateNamePinning;

#pragma mark - Forms report methods
- (void)sendFormRequestWithUserId:(NSString*)userId deviceId:(NSString*)deviceId notification:(TPNotification*)notification formContents:(NSDictionary*)formContents;
/** Same that sendFormRequestWithUserId:deviceId:notification:formContents: but will ask for the deviceId to TwinPushManager */
- (void)sendFormRequestWithUserId:(NSString*)userId notification:(TPNotification*)notification formContents:(NSDictionary*)formContents;

@end
