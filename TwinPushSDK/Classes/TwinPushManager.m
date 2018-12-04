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

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface TwinPushManager()<UNUserNotificationCenterDelegate>
@end
#endif


static NSString* const kSdkVersion = @"3.7.3";

static NSString* const kDefaultServerUrl = @"https://%@.twinpush.com/api/v2";
static NSString* const kDefaultServerSubdomain = @"app";
//#define kDefaultCertificateNames @[@"*.twinpush.com", @"Go Daddy Secure Certificate Authority - G2", @"Go Daddy Root Certificate Authority - G2"]
#define kDefaultCertificateNames @[@"*.twinpush.com", @"Starfield Secure Certificate Authority - G2", @"Starfield Root Certificate Authority - G2"]

static NSString* const kPushIdKey = @"pushId";
static NSString* const kPushTokenKey = @"pushToken";
static NSString* const kAPITokenKey = @"apiToken";
static NSString* const kDeviceIdKey = @"deviceId";
static NSString* const kNSUserDefaultsDeviceIdKey = @"TPDeviceId";
static NSString* const kNSUserDefaultsAliasKey = @"TPAlias";
static NSString* const kNSUserDefaultsPushTokenKey = @"TPPushToken";
static NSString* const kNSUserDefaultsApiHashKey = @"TPApiHash";
static NSString* const kNSUserDefaultsRegisterHashKey = @"TPRegisterHash";
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
@property (nonatomic) NSUInteger lastRegisterHash;

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
        _autoRegisterForRemoteNotifications = YES;
        _autoResetBadgeNumber = YES;
        
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
    NSInteger previousApiHash = [[self fetchValueForKey:kNSUserDefaultsApiHashKey] integerValue];
    if (previousApiHash == 0 || previousApiHash == [self getApiHash]) {
        self.deviceId = [self fetchValueForKey:kNSUserDefaultsDeviceIdKey];
        self.registeredAlias = [self fetchValueForKey:kNSUserDefaultsAliasKey];
        self.registeredPushToken = [self fetchValueForKey:kNSUserDefaultsPushTokenKey];
        self.lastRegisterHash = [self fetchValueForKey:kNSUserDefaultsRegisterHashKey].integerValue;
    }
    else {
        NSLog(@"[TwinPushSDK] Info: API connection changed, ignoring previous register");
    }
    if (!self.isRegistered || [self currentRegisterHash] != self.lastRegisterHash) {
        [self registerDevice];
    }
    else {
        [self registerSkipped];
    }
    
    [self registerForApplicationEvents];
}

- (void)setApplicationBadgeCount:(NSUInteger)badgeCount {
    [self setApplicationBadgeCount:badgeCount force:NO];
}

- (void)setApplicationBadgeCount:(NSUInteger)badgeCount force:(BOOL)force {
    if (!force && [UIApplication sharedApplication].applicationIconBadgeNumber == badgeCount) {
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

- (TPRegisterInformation*)registerInfo {
    return [[TPRegisterInformation alloc] initWithToken:_pushToken deviceAlias:_alias UDID:self.deviceUDID];
}

- (NSUInteger)currentRegisterHash {
    NSDictionary* infoDictionary = [[self registerInfo] toDictionary];
    return [infoDictionary hash];
}

- (NSInteger)getApiHash {
    NSString* apiString = [NSString stringWithFormat:@"%@;;%@;;%@", self.serverURL, self.apiKey, self.appId];
    return [apiString hash];
}

#pragma mark - Application notifications
- (void)registerForApplicationEvents {
    NSArray* notificationNames = @[UIApplicationDidBecomeActiveNotification, UIApplicationDidFinishLaunchingNotification, UIApplicationWillResignActiveNotification];
    for (NSString* notificationName in notificationNames) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appNotificationReceived:) name:notificationName object:nil];
    }
}

- (void)unregisterForApplicationEvents {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)appNotificationReceived:(NSNotification*)notification {
    if ([notification.name isEqualToString: UIApplicationDidFinishLaunchingNotification]) {
        [self applicationStartedWithOptions: notification.userInfo];
    }
    else if ([notification.name isEqualToString: UIApplicationDidBecomeActiveNotification]) {
        if (self.autoResetBadgeNumber) {
            [self setApplicationBadgeCount:0];
        }
        [self sendApplicationOpenedEvent];
    }
    else if ([notification.name isEqualToString: UIApplicationWillResignActiveNotification]) {
        [self sendApplicationClosedEvent];
        if (![_delegate respondsToSelector:@selector(storeValue:forKey:)]) {
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)applicationStartedWithOptions: (NSDictionary *)launchOptions {
    TCLog(@"Started application");
    // Check if application is opened due to location change
    if (launchOptions[UIApplicationLaunchOptionsLocationKey]) {
        TCLog(@"Started application due to location event");
        
    } else {
        // Registering for remote notifications
        if (self.autoRegisterForRemoteNotifications) {
            [self registerForRemoteNotifications];
        }
        
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

- (void)dealloc {
    [self unregisterForApplicationEvents];
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

- (void)getDeviceNotificationsWithFilters:(TPNotificationsFilters*)filters andPagination:(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    [self sendGetDeviceNotificationsRequestWithFilters:filters andPagination:pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:onError];
}

- (void)getAliasNotificationsWithPagination:(TPNotificationsPagination*)pagination onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    [self sendGetAliasNotificationsRequestWithPagination: pagination onComplete:onComplete onError:onError];
}

- (void)getDeviceNotificationWithId:(NSString*)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    [self sendGetDeviceNotificationRequestWithId:notificationId onComplete:onComplete onError:onError];
}

- (void)deleteNotificationWithId:(NSString*)notificationId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    if ([self hasAppIdAndApiKey]) {
        TPBaseRequest* request = [self.requestFactory createDeleteNotificationWithId:notificationId deviceId:_deviceId appId:_appId onComplete:onComplete onError:onError];
        [self enqueueRequest:request];
    }
}

- (void)getInboxSummaryOnComplete:(GetInboxSummaryResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    if ([self hasAppIdAndApiKey]) {
        TPBaseRequest* request = [self.requestFactory createInboxSummaryRequestWithDeviceId:_deviceId appId:_appId onComplete:onComplete onError:onError];
        [self enqueueRequest:request];
    }
}

- (void)getApplicationBadgeOnComplete:(GetApplicationBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError {
    if ([self hasAppIdAndApiKey]) {
        TPBaseRequest* request = [self.requestFactory createGetApplicationBadgeRequestWithDeviceId:_deviceId appId:_appId onComplete:onComplete onError:onError];
        [self enqueueRequest:request];
    }
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
- (void)setProperty:(NSString *)name withEnumValue:(NSString *)value {
    [self setProperty:name type:TPPropertyTypeEnum value:value];
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
        NSLog(@"[TwinPushSDK] Warning: device not registered yet. Unable to send application close event");
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
/** Implement to override default storage implementation using NSUserDefaults */
- (NSString*)fetchValueForKey:(NSString*)key {
    if ([_delegate respondsToSelector:@selector(fetchValueForKey:)]) {
        return [_delegate fetchValueForKey:key];
    }
    else {
        return [[NSUserDefaults standardUserDefaults] valueForKey:key];
    }
}

- (void)storeValue:(NSString*)value forKey:(NSString*) key {
    if ([_delegate respondsToSelector:@selector(storeValue:forKey:)]) {
        [_delegate storeValue:value forKey:key];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    }
}


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
    #if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    // Use UserNotifications framework whenever possible
    if ([UNUserNotificationCenter class]) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
             if( !error ) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                 [[UIApplication sharedApplication] registerForRemoteNotifications];
                     NSLog( @"Push registration success." );
                 });
             }
             else {
                 NSLog( @"Push registration FAILED" );
                 NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
                 NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );  
             }  
         }];
    }
    else
    #endif
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



- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* stringPushToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    
    [self setPushToken:stringPushToken];
    
    TCLog(@"Push Notification tokenstring is %@", stringPushToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    TCLog(@"Application did receive remote notifications: %@", userInfo);
    [self didReceiveRemoteNotification:userInfo whileActive:application.applicationState == UIApplicationStateActive];
    if (self.autoResetBadgeNumber) {
        [self setApplicationBadgeCount:0 force:YES];
    }
}

#pragma mark - Deprecated methods
- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"Calling TwinPushManager application:didFinishLaunchingWithOptions: is no longer necessary");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"Calling TwinPushManager applicationDidBecomeActive: is no longer necessary");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"Calling TwinPushManager applicationWillResignActive: is no longer necessary");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"Calling TwinPushManager applicationWillResignActive: is no longer necessary");
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
        TPRegisterInformation* registerInfo = [self registerInfo];
        TPRegisterCompletedBlock onComplete = ^(TPDevice *device) {
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
            self.lastRegisterHash = [[((TPCreateDeviceRequest*)self.registerRequest) createBodyContent] hash];
            
            [self storeValue:@([self getApiHash]).stringValue forKey:kNSUserDefaultsApiHashKey];
            [self storeValue:_registeredAlias forKey:kNSUserDefaultsAliasKey];
            [self storeValue:_registeredPushToken forKey:kNSUserDefaultsPushTokenKey];
            [self storeValue:_deviceId forKey:kNSUserDefaultsDeviceIdKey];
            [self storeValue:@(_lastRegisterHash).stringValue forKey:kNSUserDefaultsRegisterHashKey];
            
            if ([self.delegate respondsToSelector:@selector(didFinishRegisteringDevice)]) {
                [self.delegate didFinishRegisteringDevice];
            }
            self.registerRequest = nil;
            
            [self sendBadgeCountUpdate];
        };
        
        if (self.externalRegisterBlock) {
            self.externalRegisterBlock(registerInfo, onComplete);
        }
        else {
            self.registerRequest = [self.requestFactory createCreateDeviceRequestWithInfo:registerInfo appId:_appId apiKey:_apiKey onComplete: onComplete onError:^(NSError *error) {
                if ([self.delegate respondsToSelector:@selector(didFailRegisteringDevice:)]) {
                    [self.delegate didFailRegisteringDevice:error.localizedDescription];
                }
                self.registerRequest = nil;
            }];
        [self.registerRequest start];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(didFailRegisteringDevice:)]) {
            [self.delegate didFailRegisteringDevice:@"Missing APP ID or API Key"];
        }
    }
}

- (void)sendGetDeviceNotificationsRequestWithFilters:(TPNotificationsFilters*)filters andPagination:
(TPNotificationsPagination*)pagination onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    [self.inboxRequest cancel];
    if ([self hasAppIdAndApiKey]) {
        self.inboxRequest = [self.requestFactory createGetDeviceNotificationsRequestWithDeviceId:_deviceId filters:filters pagination:pagination appId:_appId onComplete:^(NSArray *array, BOOL hasMore) {
            self.inboxRequest = nil;
            onComplete(array, hasMore);
        } onError:^(NSError *error) {
            onError(error);
            self.inboxRequest = nil;
        }];
        [self.inboxRequest start];
    } else {
        onComplete (nil, NO);
    }
}

- (void)sendGetAliasNotificationsRequestWithPagination:
(TPNotificationsPagination*)pagination onComplete:(GetAliasNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    [self.inboxRequest cancel];
    if ([self hasAppIdAndApiKey]) {
        self.inboxRequest = [self.requestFactory createGetAliasNotificationsRequestWithDeviceId:_deviceId pagination:pagination appId:_appId onComplete:^(NSArray *array, BOOL hasMore) {
            self.inboxRequest = nil;
            onComplete(array, hasMore);
        } onError:^(NSError *error) {
            onError(error);
            self.inboxRequest = nil;
        }];
        [self.inboxRequest start];
    } else {
        onComplete (nil, NO);
    }
}

- (void)sendGetDeviceNotificationRequestWithId:(NSString*)notificationId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    if ([self hasAppIdAndApiKey]) {
        [self.singleNotificationRequest cancel];
        self.singleNotificationRequest = [self.requestFactory createGetDeviceNotificationWithId:notificationId deviceId:self.deviceId appId:_appId onComplete:^(TPNotification* notification) {
            self.singleNotificationRequest = nil;
            onComplete(notification);
        } onError:^(NSError *error) {
            onError(error);
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


#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//Called when a notification is delivered to a foreground app.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSLog(@"User Info : %@", notification.request.content.userInfo);
    UNNotificationPresentationOptions options = UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge;
    if ([_delegate respondsToSelector:@selector(presentationOptionsForNotification:)]) {
        options = [_delegate presentationOptionsForNotification:notification];
    }
    completionHandler(options);
}

//Called to let your app know which action was selected by the user for a given notification.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    TPNotification* notification = [TPNotification notificationFromUserNotification:response.notification];
    [self userDidOpenNotificationWithId:notification.notificationId];
    if ([_delegate respondsToSelector:@selector(didReceiveNotificationResponse:withCompletionHandler:)]) {
        [_delegate didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    }
    else {
        if ([_delegate respondsToSelector:@selector(didReceiveNotificationResponse:)]) {
            [_delegate didReceiveNotificationResponse:response];
        }
        else {
            TPNotification* notification = [TPNotification notificationFromUserNotification: response.notification];
            [self showNotification: notification];
        }
        completionHandler();
    }
}

#endif

@end
