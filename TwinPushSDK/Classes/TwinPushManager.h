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

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

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
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
/** Called when a notification is delivered to a foreground app. Return UNNotificationPresentationOptionNone to silcence it **/
-(UNNotificationPresentationOptions)presentationOptionsForNotification:(UNNotification *)notification;
/** Called to let your app know which action was selected by the user for a given notification.
    At the end of your implementation, you must call the completionHandler block to let the system know that you 
    are done processing the notification.
    Default implementation will call `showNotification:` regardless of the selected action */
-(void)didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler;
/** Called to let your app know which action was selected by the user for a given notification.
    Default implementation will call `showNotification:` regardless of the selected action */
-(void)didReceiveNotificationResponse:(UNNotificationResponse *)response;
#endif
/** Implement to override default storage implementation using NSUserDefaults */
- (NSString*)fetchValueForKey:(NSString*)key;
- (void)storeValue:(NSString*)value forKey:(NSString*) key;
@end

typedef enum {
    TPLocationAccuracyFine,
    TPLocationAccuracyHigh,
    TPLocationAccuracyMedium,
    TPLocationAccuracyLow,
    TPLocationAccuracyCoarse
} TPLocationAccuracy;

/** Callback to tell TwinPushManager when the external register has finished. */
typedef void(^TPRegisterCompletedBlock)(TPDevice* device);
/** Block to intercept standard TwinPush register and replace it with a custom external register.
    It receives all the register information contained in a TPRegisterInformation object and a callback to
    invoke when the external register has completed and a TPDevice object is obtained */
typedef void(^TPExternalRegisterBlock)(TPRegisterInformation* info, TPRegisterCompletedBlock onComplete);

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
/** Current TwinPush SDK version number */
@property (nonatomic, readonly) NSString* versionNumber;
/** Automatically request notification permissions to the user on application startup.
    Set to NO if you want to manually control permission request. Defaults to 'YES' */
@property (nonatomic) BOOL autoRegisterForRemoteNotifications;
/** Automatically reset local and remote application badge number when the application is opened or a notification is received with the application open
    Set to NO if you want to manually control the application badge number. Defaults to 'YES' */
@property (nonatomic) BOOL autoResetBadgeNumber;


#pragma mark - Shared instance
+ (TwinPushManager*) manager;
+ (TwinPushManager*) singleton; // Required for swift compatibility. Equivalent to [TwinPushManager manager]

#pragma mark - Public methods
/** Setup TwinPush SDK with the provided App ID and the API Key. This will also trigger a register if the device hasn't been
    registered yet. This method must be called before any other TwinPushManager method, but after changing the server URL
    if that is required. */
- (void)setupTwinPushManagerWithAppId:(NSString*)appId apiKey:(NSString*)apiKey delegate:(id<TwinPushManagerDelegate>)delegate;
/** Convenience method for setting the push token. It strips '<' and '>' symbols and set the 'pushToken' property */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
/** Changes the application badge count in both the current application and the server.
    Usually the badge count is reset to zero when the application goes to background */
- (void)setApplicationBadgeCount:(NSUInteger)badgeCount;
/** Device is already registered on setup, when a new alias is set or the push token changes. Call this method explicitly if
    you require to refresh the register manually. It's usually required if you disabled a register by implementing
    the method 'shouldRegisterDeviceWithAlias:token:'. This call is also interceptable by 'shouldRegisterDeviceWithAlias:token:' */
- (void)registerDevice;
/** Requests permission to the user to receive remote push notifications.
    Calling this method is only required if `autoRequestNotificationPermission` is set to NO */
- (void)registerForRemoteNotifications;


/** These methods are deprecated and will be removed in a future SDK release **/
- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions DEPRECATED_MSG_ATTRIBUTE("Calling this method is no longer required");
- (void)applicationDidBecomeActive:(UIApplication *)application DEPRECATED_ATTRIBUTE DEPRECATED_MSG_ATTRIBUTE("Calling this method is no longer required");
- (void)applicationWillResignActive:(UIApplication *)application DEPRECATED_ATTRIBUTE DEPRECATED_MSG_ATTRIBUTE("Calling this method is no longer required");
- (void)applicationDidEnterBackground:(UIApplication *)application DEPRECATED_ATTRIBUTE DEPRECATED_MSG_ATTRIBUTE("Calling this method is no longer required");

#pragma mark - Certificate pinning
- (void)enableCertificateNamePinningWithDefaultValues;
- (void)enableCertificateNamePinningWithCertificateNames:(NSArray*)certificateNames;
- (void)disableCertificateNamePinning;

#pragma mark Notifications
- (void)getDeviceNotificationsWithFilters:(TPNotificationsFilters*)filters andPagination:(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)getAliasNotificationsWithFilters:(TPNotificationsFilters*)filters andPagination:(TPNotificationsPagination*)pagination onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)getAliasNotificationsWithPagination:(TPNotificationsPagination*)pagination onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)getDeviceNotificationWithId:(NSString*)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)userDidOpenNotificationWithId:(NSString*)notificationId;
- (void)deleteNotificationWithId:(NSString*)notificationId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)getInboxSummaryOnComplete:(GetInboxSummaryResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
- (void)getApplicationBadgeOnComplete:(GetApplicationBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError;

#pragma mark Custom properties
- (void)setProperty:(NSString*)name withStringValue:(NSString*)value;
- (void)setProperty:(NSString*)name withBooleanValue:(NSNumber*)value;
- (void)setProperty:(NSString*)name withIntegerValue:(NSNumber*)value;
- (void)setProperty:(NSString*)name withFloatValue:(NSNumber*)value;
- (void)setProperty:(NSString*)name withEnumValue:(NSString*)value;
- (void)setProperty:(NSString*)name withEnumListValue:(NSArray<NSString*>*)value;
/** Clears all the custom properties set for the device */
- (void)clearAllProperties;

#pragma mark Location
/** Updates the current user location in TwinPush using the desired accuracy. It will initialize a CLLocationManager,
    ask for 'when in use' location permissions, start the location service, wait for a valid location, stop the location service
    and send the location to TwinPush when a new valid location is obtained.
    This requires a valid 'NSLocationWhenInUseUsageDescription' entry in your Plist file. */
- (void)updateLocation:(TPLocationAccuracy)accuracy;
/** Send the specified location to TwinPush servers */
- (void)setLocation:(CLLocation*)location;
/** Send the specified location to TwinPush servers */
- (void)setLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;

/** Starts the significant location changes listener for obtaining location changes while in background. It will ask
    for 'always' location permissions. It will persist between application restarts.
    It requires a valid 'NSLocationAlwaysUsageDescription' entry in your Plist file.
    'stopMonitoringLocationChanges' must be called in order to stop the listener. */
- (void)startMonitoringLocationChanges;
/** Stops the significant location changes listener to stop receiving background updates of the user location */
- (void)stopMonitoringLocationChanges;
- (BOOL)isMonitoringSignificantChanges;
/** Convenience method for asking 'when in use' location permission. It's automatically called by 'updateLocation:' method */
- (void)askForInUseLocationPermission;
/** Convenience method for asking 'always' location permission. It's automatically called by
    'startMonitoringLocationChanges' method */
- (void)askForAlwaysLocationPermission;

#pragma mark Usage statistics
/** Sends the Application OPEN Event so the server can calculate the usage time matching open & close events */
- (void)sendApplicationOpenedEvent;
/** Sends the Application CLOSE Event so the server can calculate the usage time matching open & close events */
- (void)sendApplicationClosedEvent;

#pragma mark External register
/** Set this property to replace standard TwinPush register with a custom method. The external register is used
    to delegate the register of the devices to an external platform. Invoke the onComplete block with the returned
    device, mandatory for the rest of the requests to work */
@property (nonatomic, copy) TPExternalRegisterBlock externalRegisterBlock;

@end
