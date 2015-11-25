//
//  TwinPushManager.m
//  TwinPushSDK
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TwinPushManager.h"
#import "TPBaseRequest.h"
#import "TPTwinPushRequest.h"
#import "TPRequestLauncher.h"


static NSString* const kSdkVersion = @"1.4.1";

static NSString* const kDefaultServerUrl = @"https://%@.twinpush.com/api/v2";
static NSString* const kDefaultServerSubdomain = @"app";
#define kDefaultCertificateNames @[@"*.twinpush.com", @"Starfield Secure Certificate Authority - G2", @"Starfield Root Certificate Authority - G2"]

static NSString* const kPushIdKey = @"pushId";
static NSString* const kPushTokenKey = @"pushToken";
static NSString* const kAPITokenKey = @"apiToken";
static NSString* const kDeviceIdKey = @"deviceId";
static NSString* const kNSUserDefaultsDeviceIdKey = @"TPDeviceId";
static NSString* const kNSUserDefaultsAliasKey = @"TPAlias";
static NSString* const kNSUserDefaultsPushTokenKey = @"TPPushToken";
static NSString* const kNSUserDefaultsApiHashKey = @"TPApiHash";
static NSString* const kNSUserDefaultsMonitorSignificantChangesKey = @"TPIsMonitoringSignificantChanges";

@interface TwinPushManager()

@property (nonatomic, strong) TPRequestFactory* requestFactory;
@property (nonatomic, strong) TPBaseRequest* registerRequest;
@property (nonatomic, strong) TPBaseRequest* inboxRequest;
@property (nonatomic, strong) TPBaseRequest* singleNotificationRequest;
@property (nonatomic, strong) TPBaseRequest* updateBadgeRequest;
@property (nonatomic, strong) TPBaseRequest* reportStatisticsRequest;
@property (nonatomic, strong) NSMutableArray* activeRequests;
@property (nonatomic, strong) TPNotification* receivedNotification;
@property (nonatomic, strong) NSNumber* pendingBadgeCount;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, assign) TPLocationAccuracy locationAccuracy;
@property (nonatomic, copy) NSString* appId;
@property (nonatomic, copy) NSString* apiKey;
@property (nonatomic, copy) NSString* registeredAlias;
@property (nonatomic, copy) NSString* registeredPushToken;

@end

@implementation TwinPushManager

static TwinPushManager *_sharedInstance;

- (id)init
{
    self = [super init];
    if (self) {
        self.requestFactory = [[TPRequestFactory alloc] init];
        _activeRequests = [NSMutableArray array];
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        self.serverSubdomain = kDefaultServerSubdomain;
        
        // Defaults to identifierForVendor on iOS 6
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            _deviceUDID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        }
    }
    return self;
}

#pragma mark - Shared instance

+ (TwinPushManager*) manager {
    if (_sharedInstance == nil) {
        _sharedInstance = [[TwinPushManager alloc] init];
    }
    return _sharedInstance;
}

+ (TwinPushManager *)singleton {
    return [self manager];
}

#pragma mark - Setup

- (void)setupTwinPushManagerWithAppId:(NSString*)appId apiKey:(NSString*)apiKey delegate:(id<TwinPushManagerDelegate>)delegate {
    self.appId = appId;
    self.apiKey = apiKey;
    self.delegate = delegate;
    
    // If the API Hash has changed since last register, we will ignore saved values
    NSInteger previousApiHash = [[NSUserDefaults standardUserDefaults] integerForKey:kNSUserDefaultsApiHashKey];
    if (previousApiHash == 0 || previousApiHash == [self getApiHash]) {
        self.deviceId = [[NSUserDefaults standardUserDefaults] valueForKey:kNSUserDefaultsDeviceIdKey];
        self.registeredAlias = [[NSUserDefaults standardUserDefaults] valueForKey:kNSUserDefaultsAliasKey];
        self.registeredPushToken = [[NSUserDefaults standardUserDefaults] valueForKey:kNSUserDefaultsPushTokenKey];
    }
    else {
        NSLog(@"[TwinPushSDK] Info: API connection changed, ignoring previous register");
    }
    if (!self.isRegistered) {
        [self registerDevice];
    }
    else {
        [self registerSkipped];
    }
}

- (void)setApplicationBadgeCount:(NSUInteger)badgeCount {
    if ([UIApplication sharedApplication].applicationIconBadgeNumber == badgeCount) {
        return;
    }
    
    if (self.updateBadgeRequest != nil) {
        [self.updateBadgeRequest cancel];
        self.updateBadgeRequest = nil;
    }
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = badgeCount;
    self.pendingBadgeCount = @(badgeCount);
    
    [self sendBadgeCountUpdate];
}

- (void)setPushToken:(NSString *)pushToken {
    _pushToken = pushToken;
    if (![self nilEqual:pushToken other:self.registeredPushToken]) {
        [self registerDevice];
    }
    else {
        [self registerSkipped];
    }
}

- (void)setAlias:(NSString *)alias {
    _alias = alias;
    if (![self nilEqual:alias other:self.registeredAlias]) {
        [self registerDevice];
    }
    else {
        [self registerSkipped];
    }
}

- (BOOL)nilEqual:(NSString*)a  other:(NSString*)b {
    return (a == nil && b == nil) || [a isEqualToString:b];
}

- (void)registerSkipped {
    if ([self.delegate respondsToSelector:@selector(didSkipRegisteringDevice)]) {
        [self.delegate didSkipRegisteringDevice];
    }
}

- (NSInteger)getApiHash {
    NSString* apiString = [NSString stringWithFormat:@"%@;;%@;;%@", self.serverURL, self.apiKey, self.appId];
    return [apiString hash];
}

#pragma mark - Public methods

- (BOOL)isRegistered {
    return _deviceId != nil;
}

- (void)registerDevice {
    BOOL shouldRegister = YES;
    
    if ([self.delegate respondsToSelector:@selector(shouldRegisterDeviceWithAlias:token:)]) {
        shouldRegister = [self.delegate shouldRegisterDeviceWithAlias:_alias token:_pushToken];
    }
    
    if (shouldRegister) {
        [self sendCreateDeviceRequestWithPushToken:_pushToken andAlias:_alias];
    }
    else {
        [self registerSkipped];
    }
}

- (void)getDeviceNotificationsWithFilters:(TPNotificationsFilters*)filters andPagination:(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete {
    [self sendGetDeviceNotificationsRequestWithFilters:filters andPagination:pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete];
}

- (void)getDeviceNotificationWithId:(NSInteger)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete {
    [self sendGetDeviceNotificationRequestWithId:notificationId onComplete:onComplete];
}

- (void)userDidOpenNotificationWithId:(NSString*)notificationId {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to open notification");
        return;
    }
    
    TPBaseRequest* request = [self.requestFactory createUserOpenNotificationRequestWithDeviceId:self.deviceId notificationId:notificationId appId:self.appId onComplete:^(NSDictionary *response) {
        TCLog(@"User Open Notification: %@ request success", notificationId);
    } onError:^(NSError *error) {
        TCLog(@"User Open Notification: %@ request error: %@", notificationId, error);
    }];
    [self enqueueRequest:request];
}

- (void)setServerURL:(NSString *)serverURL {
    _serverURL = serverURL;
    
    [TPTwinPushRequest setServerURL:serverURL];
}

- (void)setServerSubdomain:(NSString *)serverSubdomain {
    _serverSubdomain = serverSubdomain;
    
    self.serverURL = [NSString stringWithFormat:kDefaultServerUrl, serverSubdomain];
}

- (NSString *)versionNumber {
    return kSdkVersion;
}

#pragma mark Custom properties

- (void) setProperty:(NSString*)name withStringValue:(NSString*)value {
    [self setProperty:name type:TPPropertyTypeString value:value];
}
- (void) setProperty:(NSString*)name withBooleanValue:(NSNumber*)value {
    [self setProperty:name type:TPPropertyTypeBoolean value:value];
}
- (void) setProperty:(NSString*)name withIntegerValue:(NSNumber*)value {
    [self setProperty:name type:TPPropertyTypeInteger value:value];
}
- (void) setProperty:(NSString*)name withFloatValue:(NSNumber*)value {
    [self setProperty:name type:TPPropertyTypeFloat value:value];
}

- (void) setProperty:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to set custom property");
        return;
    }
    
    TPBaseRequest* request = [[self requestFactory] createSetCustomPropertyRequestWithName:name type:type value:value deviceId:_deviceId appId:_appId onComplete:^{
        TCLog(@"Property set successfull: %@=%@", name, value);
    } onError:^(NSError *error) {
        TCLog(@"ERROR setting property: %@=%@", name, value);
    }];
    [self enqueueRequest:request];
}

#pragma mark Location

- (void)updateLocation:(TPLocationAccuracy)accuracy {
    [self askForInUseLocationPermission];
    self.locationAccuracy = accuracy;
    self.locationManager.distanceFilter = [self distanceFilterForAccuracy:accuracy];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
}
- (void)startMonitoringLocationChanges {
    [self askForAlwaysLocationPermission];
    [self setMonitoringSignificantChanges:YES];
    [[self locationManager] startMonitoringSignificantLocationChanges];
}
- (void)stopMonitoringLocationChanges {
    [self setMonitoringSignificantChanges:NO];
    [[self locationManager] stopMonitoringSignificantLocationChanges];
}

- (void)setLocation:(CLLocation*)location {
    //#warning Remove display notification after debug
    //    [self displayNotification:location];
    [self setLocationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
}

- (void)setLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to update user location");
        return;
    }
    
    TCLog(@"Current location updated: %f, %f", latitude, longitude);
    if (self.reportStatisticsRequest != nil) {
        [self.reportStatisticsRequest cancel];
    }
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    self.reportStatisticsRequest = [self.requestFactory createReportStatisticsRequestWithCoordinate:coordinate deviceId:self.deviceId appId:self.appId onComplete:^{
        TCLog(@"Location set successfull: %f, %f", latitude, longitude);
        self.reportStatisticsRequest = nil;
    } onError:^(NSError *error) {
        TCLog(@"ERROR sending location");
        self.reportStatisticsRequest = nil;
    }];
    [self.reportStatisticsRequest start];
}

- (void)askForInUseLocationPermission {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)askForAlwaysLocationPermission {
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

#pragma mark - Statistics
- (void)sendApplicationOpenedEvent {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to send application open event");
        return;
    }
    
    TPBaseRequest* request = [self.requestFactory createOpenAppRequestWithDeviceId:self.deviceId appId:self.appId onComplete:^{
        TCLog(@"Open App request success");
    } onError:^(NSError *error) {
        TCLog(@"Open App request error: %@", error);
    }];
    [self enqueueRequest:request];
}

- (void)sendApplicationClosedEvent {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to send application open event");
        return;
    }
    
    TPBaseRequest* request = [self.requestFactory createCloseAppRequestWithDeviceId:self.deviceId appId:self.appId onComplete:^{
        TCLog(@"Close App request success");
    } onError:^(NSError *error) {
        TCLog(@"Close App request error: %@", error);
    }];
    [self enqueueRequest:request];
}


#pragma mark - Private methods

- (BOOL)hasAppIdAndApiKey {
    if (_appId == nil || _apiKey == nil) {
        [self displayAlert:NSLocalizedStringWithDefaultValue(@"APPID_APIKEY_MISSING_MESSAGE", nil, [NSBundle mainBundle], @"You have to set the values for the AppId and the ApiKey", nil) withTitle:NSLocalizedStringWithDefaultValue(@"APPID_APIKEY_MISSING_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
        return  NO;
    }
    return YES;
}

- (NSString*)getNoficationAlertFromDictionary:(NSDictionary*)userInfo {
    NSString* alert = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    return alert;
}

- (void)sendBadgeCountUpdate {
    if (![self isDeviceRegistered]) {
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to update remote badge count");
        return;
    }
    
    // Send badge count update request if it's required and hasn't been sent yet
    BOOL badgeCountChanged = _pendingBadgeCount != nil && self.updateBadgeRequest == nil;
    if (badgeCountChanged) {
        self.updateBadgeRequest = [_requestFactory createUpdateBadgeRequestWithCount:_pendingBadgeCount.unsignedIntegerValue forDeviceId:_deviceId appId:_appId onComplete:^{
            self.updateBadgeRequest = nil;
            self.pendingBadgeCount = nil;
        } onError:^(NSError *error) {
            TCLog(@"Badge update cancelled. Retrying later");
            self.updateBadgeRequest = nil;
        }];
        [self.updateBadgeRequest start];
    }
}

- (void)registerForRemoteNotifications {
#ifdef __IPHONE_8_0
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)]) {
        UIUserNotificationSettings *userNotificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:userNotificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
}

#pragma mark - AppDelegate Public methods

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    TCLog(@"Started application");
    // Check if application is opened due to location change
    if (launchOptions[UIApplicationLaunchOptionsLocationKey]) {
        TCLog(@"Started application due to location event");
        
    } else {
        // Registering for remote notifications
        [self registerForRemoteNotifications];
        
        NSDictionary* remoteNotificationDict = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (remoteNotificationDict != nil) {
            [self didReceiveRemoteNotification:remoteNotificationDict whileActive:NO];
        }
    }
    // Restart monitoring significant location changes to receive pending updates
    if ([self isMonitoringSignificantChanges]) {
        [self startMonitoringLocationChanges];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* stringPushToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    
    [self setPushToken:stringPushToken];
    
    TCLog(@"Push Notification tokenstring is %@", stringPushToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    TCLog(@"Application did receive remote notifications: %@", userInfo);
    [self didReceiveRemoteNotification:userInfo whileActive:application.applicationState == UIApplicationStateActive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self sendApplicationOpenedEvent];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self sendApplicationClosedEvent];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self sendApplicationClosedEvent];
}

#pragma mark - Certificate pinning
- (void)enableCertificateNamePinningWithDefaultValues {
    [self enableCertificateNamePinningWithCertificateNames:kDefaultCertificateNames];
}

- (void)enableCertificateNamePinningWithCertificateNames:(NSArray*)certificateNames {
    self.requestFactory.requestLauncher.expectedCertNames = certificateNames;
}

- (void)disableCertificateNamePinning {
    [self enableCertificateNamePinningWithCertificateNames:nil];
}

#pragma mark - Private methods
-(void) enqueueRequest:(TPBaseRequest*)request {
    [request addRequestEndDelegate:self];
    [self.activeRequests addObject:request];
    [request start];
}

- (BOOL) isDeviceRegistered {
    return [self hasAppIdAndApiKey] && [self isRegistered];
}

- (void)didReceiveRemoteNotification:(NSDictionary*)notificationDict whileActive:(BOOL)active {
    self.receivedNotification = [TPNotification notificationFromApnsDictionary:notificationDict];
    NSString* notificationId = [NSString stringWithFormat:@"%@", self.receivedNotification.notificationId];
    [[TwinPushManager manager] userDidOpenNotificationWithId:notificationId];
    if (![_delegate respondsToSelector:@selector(didReceiveNotification:whileActive:)]) {
        if (active) {
            NSString* title = NSLocalizedStringWithDefaultValue(@"NOTIFICATION_RECEIVED_ALERT_TITLE", nil, [NSBundle mainBundle], @"Notification received", nil);
            NSString* cancelButtonTitle;
            NSString* openButtonTitle = nil;
            
            if ([_receivedNotification isRich]) {
                cancelButtonTitle = NSLocalizedStringWithDefaultValue(@"NOTIFICATION_RECEIVED_ALERT_CANCEL_BUTTON", nil, [NSBundle mainBundle], @"Cancel", nil);
                openButtonTitle = NSLocalizedStringWithDefaultValue(@"NOTIFICATION_RECEIVED_OPEN_BUTTON", nil, [NSBundle mainBundle], @"Open", nil);
            }
            else {
                cancelButtonTitle = NSLocalizedStringWithDefaultValue(@"NOTIFICATION_RECEIVED_ALERT_ACCEPT_BUTTON", nil, [NSBundle mainBundle], @"OK", nil);
            }
            
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                                message:_receivedNotification.message
                                                               delegate:self
                                                      cancelButtonTitle:cancelButtonTitle
                                                      otherButtonTitles:openButtonTitle, nil];
            [alertView show];
        }
        else {
            [self showNotification:_receivedNotification];
        }
    } else {
        [_delegate didReceiveNotification:_receivedNotification whileActive:active];
    }
}

- (void)showNotification:(TPNotification*)notification {
    if (![_delegate respondsToSelector:@selector(showNotification:)]) {
        if ([notification isRich]) {
            // TODO: Missing toolbar with close button
            TPNotificationDetailViewController* detailViewController = [[TPNotificationDetailViewController alloc] init];
            detailViewController.delegate = self;
            detailViewController.notification = notification;
            UIViewController* presenter = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [presenter presentViewController:detailViewController animated:YES completion:nil];
        }
    } else {
        [_delegate showNotification:notification];
    }
}

- (void)sendCreateDeviceRequestWithPushToken:(NSString*)pushToken andAlias:(NSString*)alias {
    if ([self hasAppIdAndApiKey]) {
        [self.registerRequest cancel];
        self.registerRequest = [self.requestFactory createCreateDeviceRequestWithToken:pushToken deviceAlias:alias UDID:self.deviceUDID appId:_appId apiKey:_apiKey onComplete:^(TPDevice *device) {
            [self willChangeValueForKey:@"alias"];
            if ([device.deviceAlias isKindOfClass:[NSString class]]) {
                _alias = device.deviceAlias;
            } else {
                _alias = @"";
            }
            [self didChangeValueForKey:@"alias"];
            
            [self willChangeValueForKey:@"deviceId"];
            _deviceId = device.deviceId;
            [self didChangeValueForKey:@"deviceId"];
            
            self.registeredAlias = alias;
            self.registeredPushToken = pushToken;
            
            [[NSUserDefaults standardUserDefaults] setInteger:[self getApiHash] forKey:kNSUserDefaultsApiHashKey];
            [[NSUserDefaults standardUserDefaults] setValue:_registeredAlias forKey:kNSUserDefaultsAliasKey];
            [[NSUserDefaults standardUserDefaults] setValue:_registeredPushToken forKey:kNSUserDefaultsPushTokenKey];
            [[NSUserDefaults standardUserDefaults] setValue:_deviceId forKey:kNSUserDefaultsDeviceIdKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if ([self.delegate respondsToSelector:@selector(didFinishRegisteringDevice)]) {
                [self.delegate didFinishRegisteringDevice];
            }
            self.registerRequest = nil;
            
            [self sendBadgeCountUpdate];
        } onError:^(NSError *error) {
            if ([self.delegate respondsToSelector:@selector(didFailRegisteringDevice:)]) {
                [self.delegate didFailRegisteringDevice:error.localizedDescription];
            }
            self.registerRequest = nil;
        }];
        [self.registerRequest start];
    } else {
        if ([self.delegate respondsToSelector:@selector(didFailRegisteringDevice:)]) {
            [self.delegate didFailRegisteringDevice:@"Missing APP ID or API Key"];
        }
    }
}

- (void)sendGetDeviceNotificationsRequestWithFilters:(TPNotificationsFilters*)filters andPagination:
(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete {
    [self.inboxRequest cancel];
    if ([self hasAppIdAndApiKey]) {
        self.inboxRequest = [self.requestFactory createGetDeviceNotificationsRequestWithDeviceId:_deviceId filters:filters pagination:pagination appId:_appId onComplete:^(NSArray *array, BOOL hasMore) {
            self.inboxRequest = nil;
            onComplete(array, hasMore);
        } onError:^(NSError *error) {
            [self displayAlert:error.localizedDescription withTitle:NSLocalizedStringWithDefaultValue(@"GET_NOTIFICATIONS_ERROR_ALERT_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
            self.inboxRequest = nil;
        }];
        [self.inboxRequest start];
    } else {
        onComplete (nil, NO);
    }
}

- (void)sendGetDeviceNotificationRequestWithId:(NSInteger)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete {
    if ([self hasAppIdAndApiKey]) {
        [self.singleNotificationRequest cancel];
        self.singleNotificationRequest = [self.requestFactory createGetDeviceNotificationWithId:notificationId deviceId:self.deviceId appId:_appId onComplete:^(TPNotification* notification) {
            self.singleNotificationRequest = nil;
            onComplete(notification);
        } onError:^(NSError *error) {
            [self displayAlert:error.localizedDescription withTitle:NSLocalizedStringWithDefaultValue(@"GET_NOTIFICATIONS_ERROR_ALERT_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
            self.singleNotificationRequest = nil;
        }];
        [self.singleNotificationRequest start];
    }
}

- (void)displayAlert:(NSString*)alert withTitle:(NSString*)title {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:alert delegate:self cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"DEVICE_REGISTERED_ALERT_ACCEPT_BUTTON", nil, [NSBundle mainBundle], @"Accept", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - TPNotificationsInboxDelegate

- (void)dismissModalView {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] dismissModalViewControllerAnimated:YES];
}

- (void)didFinishLoadingNotifications {
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex) {
		[self showNotification:self.receivedNotification];
	}
}

#pragma mark - TPRequestEndDelegate

- (void) requestDidFinish:(TPBaseRequest *)aRequest {
    if ([self.activeRequests containsObject:aRequest]) {
        [self.activeRequests removeObject:aRequest];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = [locations lastObject];
    TCLog(@"Updated locations");
    if ([self isValidLocation:location] && location.horizontalAccuracy <= [self locationAccuracyForAccuracy:self.locationAccuracy]) {
        TCLog(@"Stop updating location");
        [self.locationManager stopUpdatingLocation];
        [self setLocation:location];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    TCLog(@"Location manager failed: %@", error.localizedDescription);
}

#pragma mark - Location utils

- (CLLocationDistance) distanceFilterForAccuracy:(TPLocationAccuracy)accuracy {
    CLLocationDistance distance = 0;
    switch (accuracy) {
        case TPLocationAccuracyFine:
            distance = 5;
            break;
        case TPLocationAccuracyHigh:
            distance = 10;
            break;
        case TPLocationAccuracyMedium:
            distance = 50;
            break;
        case TPLocationAccuracyLow:
            distance = 500;
            break;
        case TPLocationAccuracyCoarse:
            distance = 1000;
            break;
    }
    return distance;
}

- (CLLocationAccuracy) locationAccuracyForAccuracy:(TPLocationAccuracy)accuracy {
    CLLocationAccuracy precision = 0;
    switch (accuracy) {
        case TPLocationAccuracyFine:
            precision = 10;
            break;
        case TPLocationAccuracyHigh:
            precision = 20;
            break;
        case TPLocationAccuracyMedium:
            precision = 100;
            break;
        case TPLocationAccuracyLow:
            precision = 500;
            break;
        case TPLocationAccuracyCoarse:
            precision = 1000;
            break;
    }
    return precision;
}

-(BOOL) isValidLocation:(CLLocation*)location {
    return location != nil && CLLocationCoordinate2DIsValid(location.coordinate) && location.coordinate.latitude != 0 && location.coordinate.longitude != 0;
}

-(void) setMonitoringSignificantChanges:(BOOL)isMonitoring {
    [[NSUserDefaults standardUserDefaults] setBool:isMonitoring forKey:kNSUserDefaultsMonitorSignificantChangesKey];
}

-(BOOL) isMonitoringSignificantChanges {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kNSUserDefaultsMonitorSignificantChangesKey];
}

-(void) displayNotification:(CLLocation*)location {
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    NSDateComponents* components = [[NSDateComponents alloc] init];
    [components setSecond:1];
    localNotif.fireDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
	// Notification details
    localNotif.alertBody = [NSString stringWithFormat:@"New location: %f, %f", location.coordinate.latitude, location.coordinate.longitude];
	// Set the action button
    localNotif.alertAction = @"OK";
    
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 1;
    
	// Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

@end
