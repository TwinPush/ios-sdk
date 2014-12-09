//
//  TwinPushManager.h
//  TwinPushSDK
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TPNotification.h"
#import "TPNotificationsFilters.h"
#import "TPNotificationsPagination.h"
#import "TPNotificationsInboxViewController.h"
#import "TPRequestFactory.h"
#import <CoreLocation/CoreLocation.h>

@protocol TwinPushManagerDelegate <NSObject>

@optional
- (BOOL)shouldRegisterDeviceWithAlias:(NSString*)alias token:(NSString*)token;
- (void)didFinishRegisteringDevice;
- (void)didFailRegisteringDevice:(NSString*)error;
- (void)didFinishGettingNotifications;
- (void)didReceiveNotification:(TPNotification*)notification whileActive:(BOOL)active;
- (void)showNotification:(TPNotification*)notification;

@end

typedef enum {
    TPLocationAccuracyFine,
    TPLocationAccuracyHigh,
    TPLocationAccuracyMedium,
    TPLocationAccuracyLow,
    TPLocationAccuracyCoarse
} TPLocationAccuracy;

@interface TwinPushManager : NSObject <UIAlertViewDelegate, TPNotificationsInboxViewControllerDelegate, TPNotificationDetailViewControllerDelegate, TPRequestEndDelegate, CLLocationManagerDelegate>

#pragma mark - Properties
@property (nonatomic, weak) id<TwinPushManagerDelegate> delegate;
/** Identifier of the device provided by the app at the moment of registering for receiving remote notifications */
@property (nonatomic, copy) NSString* pushToken;
/** Device identifier provided by the service when registering the device */
@property (nonatomic, copy) NSString* deviceId;
@property (nonatomic, copy) NSString* alias;
/** App identifier, provided by the web portal */
@property (nonatomic, copy, readonly) NSString* appId;
/** Security token provided by the web portal. It is included in the header of all the API TwinPush requests */
@property (nonatomic, copy, readonly) NSString* apiKey;
/** Unique identifier of the device. Defaults to [[[UIDevice currentDevice] identifierForVendor] UUIDString] if not set */
@property (nonatomic, copy) NSString* deviceUDID;
/** TwinPush Server URL. Change this URL if you have a custom URL for Enterprise hosted applications, including the version tag */
@property (nonatomic, copy) NSString* serverURL;

#pragma mark - Shared instance
+ (TwinPushManager*) manager;
+ (TwinPushManager*) singleton; // Required for swift compatibility. Equivalent to [TwinPushManager manager]

#pragma mark - Public methods
- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)setupTwinPushManagerWithAppId:(NSString*)appId apiKey:(NSString*)apiKey delegate:(id<TwinPushManagerDelegate>)delegate;
- (void)setApplicationBadgeCount:(NSUInteger)badgeCount;

#pragma mark - Certificate pinning
- (void)enableCertificateNamePinningWithDefaultValues;
- (void)enableCertificateNamePinningWithCertificateNames:(NSArray*)certificateNames;
- (void)disableCertificateNamePinning;

#pragma mark Notifications
- (void)getDeviceNotificationsWithFilters:(TPNotificationsFilters*)filters andPagination:(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete;
- (void)getDeviceNotificationWithId:(NSInteger)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete;
- (void)userDidOpenNotificationWithId:(NSString*)notificationId;
#pragma mark Custom properties
- (void)setProperty:(NSString*)name withStringValue:(NSString*)value;
- (void)setProperty:(NSString*)name withBooleanValue:(NSNumber*)value;
- (void)setProperty:(NSString*)name withIntegerValue:(NSNumber*)value;
- (void)setProperty:(NSString*)name withFloatValue:(NSNumber*)value;
#pragma mark Location
- (void)updateLocation:(TPLocationAccuracy)accuracy;
- (void)startMonitoringLocationChanges;
- (void)stopMonitoringLocationChanges;
- (void)setLocation:(CLLocation*)location;
- (void)setLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
- (void)startMonitoringRegionChangesWithAccuracy:(TPLocationAccuracy)accuracy;
- (void)stopMonitoringRegionChanges;
- (BOOL)isMonitoringRegion;
- (BOOL)isMonitoringSignificantChanges;

@end
