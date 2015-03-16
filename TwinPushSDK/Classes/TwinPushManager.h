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
/** Called just before registering the device. Implement this method to intercept the registration and return 'false' to cancel it */
- (BOOL)shouldRegisterDeviceWithAlias:(NSString*)alias token:(NSString*)token;
/** Called after the registration has finished. Implement this method if you need to perform some operation after the registration has finished. For example, setting custom properties or device tags. */
- (void)didFinishRegisteringDevice;
/** If the device has already registered and the push token and device alias haven't changed, the registration will be skipped.
    This method will be called in this case instead of 'didFinishRegisteringDevice'*/
- (void)didSkipRegisteringDevice;
/** Called when the registration fails. Usually due to a connection error */
- (void)didFailRegisteringDevice:(NSString*)error;
/** Called when the device receives a notification. The default behavior is to show an alert view if the application has
    been received while the app was in foreground and call 'showNotification:' otherwise */
- (void)didReceiveNotification:(TPNotification*)notification whileActive:(BOOL)active;
/** Called to open the notification. The default behavior is to show a modal webview with the rich content
    if the notification has any and do nothing otherwise */
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
/** TwinPushManager delegate. This is required to customize the default behavior of TwinPushManager */
@property (nonatomic, weak) id<TwinPushManagerDelegate> delegate;
/** Identifier of the device provided by the app at the moment of registering for receiving remote notifications */
@property (nonatomic, copy) NSString* pushToken;
/** Device identifier provided by the service when registering the device */
@property (nonatomic, copy) NSString* deviceId;
@property (nonatomic, copy) NSString* alias;
/** App identifier, provided by the web portal */
@property (nonatomic, copy, readonly) NSString* appId;
/** Returns true if the device has been already registered in TwinPush */
@property (nonatomic, readonly, getter=isRegistered) BOOL registered;
/** Security token provided by the web portal. It is included in the header of all the API TwinPush requests */
@property (nonatomic, copy, readonly) NSString* apiKey;
/** Unique identifier of the device. Defaults to [[[UIDevice currentDevice] identifierForVendor] UUIDString] if not set */
@property (nonatomic, copy) NSString* deviceUDID;
/** TwinPush Server URL. Change this URL if you have a custom URL for Enterprise hosted applications, including the version tag. Defaults to 'https://app.twinpush.com/api/v2' */
@property (nonatomic, copy) NSString* serverURL;
/** TwinPush Server Subdomain. Convenience property for setting the server URL subdomain. Defaults to 'app'  */
@property (nonatomic, copy) NSString* serverSubdomain;

#pragma mark - Shared instance
+ (TwinPushManager*) manager;
+ (TwinPushManager*) singleton; // Required for swift compatibility. Equivalent to [TwinPushManager manager]

#pragma mark - Public methods
/** Setup TwinPush SDK with the provided App ID and the API Key. This will also trigger a register if the device hasn't been
    registered yet. This method must be called before any other TwinPushManager method, but after changing the server URL
    if that is required. */
- (void)setupTwinPushManagerWithAppId:(NSString*)appId apiKey:(NSString*)apiKey delegate:(id<TwinPushManagerDelegate>)delegate;
- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillResignActive:(UIApplication *)application;
/** Changes the application badge count in both the current application and the server.
    Usually the badge count is reset to zero when the application goes to background */
- (void)setApplicationBadgeCount:(NSUInteger)badgeCount;
/** Device is already registered on setup, when a new alias is set or the push token changes. Call this method explicitly if
    you require to refresh the register manually. It's usually required if you disabled a register by implementing
    the method 'shouldRegisterDeviceWithAlias:token:'. This call is also interceptable by 'shouldRegisterDeviceWithAlias:token:' */
- (void)registerDevice;

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
