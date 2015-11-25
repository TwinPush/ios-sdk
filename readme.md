TwinPush SDK Library
==================

Native iOS SDK for TwinPush platform.

For detailed information see TwinPush [oficial documentation](http://developers.twinpush.com/quickstart?platform=ios).

## Installation

To start using TwinPush you have to integrate the TwinPush SDK in your iOS application. You can download a working sample with the [TwinPush SDK sources](https://github.com/TwinPush/ios-sdk/archive/master.zip).

### Using CocoaPods

[CocoaPods](http://cocoapods.org/) is the easiest and most maintainable way to install TwinPush SDK. If you are using CocoaPods (that you should) just follow these steps:

1. Add a reference to the [TwinPush SDK pod](http://cocoapods.org/?q=twinpushsdk) to your `Podfile`.

	~~~
	pod 'TwinPushSDK', '~> 1.3'
	~~~

2. Install the pods executing in your command line:

	~~~
	pod install
	~~~

### Copying the sources

If you are not using CocoaPods you can copy the sources to link the SDK to your project:

1. [Download TwinPush SDK](https://github.com/TwinPush/ios-sdk/archive/master.zip) and unzip the file

2. Copy `TwinPushSDK` folder and `TwinPushSDK.xcodeproj` file to the `Frameworks/TwinPushSDK` directory of your proyect.

3. Drag and drop `TwinPushSDK.xcodeproj` to the `Frameworks` directory of your project on XCode to add a reference to TwinPush SDK project.

4. Go to "Build phases" section of your project target:

	1. Add `TwinPushSDK` to your _Target Dependencies_ subsection
	
	2. Add `libTwinPushSDK.a` to your _Link Binary With Libraries_ subsection

5. Go to "Build Settings" section of your proyect root:

	1. Add TwinPushSDK folder to 'User Header Search Paths' and set recursive to `YES`
	
	~~~
   ${PROJECT_DIR}/ProjectName/Frameworks/TwinPushSDK
   ~~~
		
	Ensure that the displayed path match with the absolute path to the TwinPush SDK framework directory
	
	2. Add the flag `-ObjC` to 'Other Linker Flags'

6. In the "General" section of your project target, in the "Linked Frameworks and Libraries" subsection, add the following frameworks:

	~~~
	MobileCoreServices.framework
	CFNetwork.framework
	SystemConfiguration.framework
	CoreLocation.framework
	libz.dylib
	~~~

#### Swift Compatibility

[Swift](https://developer.apple.com/swift/) is an innovative new programming language for Cocoa and Cocoa Touch created by Apple. TwinPush SDK is 100% compatible with Swift projects.

To use TwinPush SDK in a Swift project, you can use any of the methods described above to install the SDK and then import TwinPushManager.h in your bridging header file to make it accessible from Swift code.

For more information check [Swift and Objective-C in the Same Project](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

## Basic TwinPush SDK Integration

Basic integration includes everything required to receive simple push notificaions.

Make your application delegate (usually named AppDelegate) to implement TwinPushManagerDelegate and add these methods:

~~~objective-c
// Objective-C
#import "TwinPushManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, TwinPushManagerDelegate> 

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[TwinPushManager manager] setupTwinPushManagerWithAppId:TWINPUSH_APP_ID apiKey:TWINPUSH_API_KEY delegate:self];
    [[TwinPushManager manager] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog("Registered for remote notifications with token: %@", deviceToken)
    [[TwinPushManager manager] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    // Stuff to do in this method
    [[TwinPushManager manager] application:application didReceiveRemoteNotification:userInfo];
}

@end
~~~

~~~swift
// Swift
class AppDelegate: UIResponder, UIApplicationDelegate, TwinPushManagerDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        TwinPushManager.singleton().setupTwinPushManagerWithAppId(TWINPUSH_APP_ID, apiKey: TWINPUSH_API_KEY, delegate: self)
        TwinPushManager.singleton().application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NSLog("Registered for remote notifications with token: %@", deviceToken)
        TwinPushManager.singleton().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        TwinPushManager.singleton().application(application, didReceiveRemoteNotification: userInfo)
    }
}
~~~
Replace `TWINPUSH_APP_ID` and `TWINPUSH_API_KEY` with the configuration values for your application in [app.twinpush.com](http://app.twinpush.com). The method `setupTwinPushManagerWithAppId` must be called before any other TwinPushSDK method other than changing the server URL (see below).

At this point you should be able to register correctly to TwinPush and you should be able to receive push notifications if both the application and the server certificates have been configured correctly. If not, check the Troubleshooting section.


## Advanced SDK integration
If you followed the previous steps successfully you should be able to receive push notifications through TwinPush. To get the most out of TwinPush you can improve the SDK integration within your application to get usage statistics, user location, custom rich notification viewer or notification inbox.

Remember that you can check the source code of the Demo project included in the SDK sources to see a working sample.

### Updating badge count

You can update the local and server badge count of your application by caling `setApplicationBadgeCount:` method of TwinPushManager. The server badge count is used for auto incremental badge counts, so it has to be reset when the notifications are read. Usually the best place is on the `applicationDidEnterBackground` method, although you can update the badge count wherever you want:

~~~objective-c
// Objective-C
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[TwinPushManager manager] setApplicationBadgeCount:0];
}
~~~
~~~swift
// Swift
func applicationDidEnterBackground(application: UIApplication) {
    TwinPushManager.singleton().setApplicationBadgeCount(0)
}
~~~

### Sending usage statistics

Through TwinPush it is possible to register the time that a user uses the application, as well as the amount of times that he uses it. To send usage statistics is necessary to add a call to the methods `applicationDidBecomeActive` and `applicationWillResignActive` of TwinPush SDK in the methods of the same name of the AppDelegate of the application.

~~~objective-c
// Objective-C
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[TwinPushManager manager] applicationDidBecomeActive: application];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[TwinPushManager manager] applicationWillResignActive: application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[TwinPushManager manager] applicationDidEnterBackground: application];
}
~~~
~~~swift
// Swift
func applicationDidBecomeActive(application: UIApplication) {
    TwinPushManager.singleton().applicationDidBecomeActive(application)
}

func applicationWillResignActive(application: UIApplication) {
    TwinPushManager.singleton().applicationWillResignActive(application)
}

func applicationDidEnterBackground(application: UIApplication) {
    TwinPushManager.singleton().applicationDidEnterBackground(application)
}
~~~

Through these calls, TwinPush can determine the periods of activity of the user with the application and will show statistics reports in the web portal.

### Assigning an alias to a device

The _alias_ is a way to identify a user rather than a device in TwinPush. It's really useful to send a push notification to a user regardless of the device that he's using. The _alias_ is usually the user identifier, email or any other value to unequivocally identify the user. The same alias can be assigned to different devices, and the push notification sent to that alias will arrive to all its devices.

To assign an alias to the device, simply assign the `alias` property of `TwinPushManager` and it will automatically register against TwinPush with that alias.

~~~objective-c
// Objective-C
- (void)loginSuccessfulWithUsername:(NSString*)username {
    [TwinPushManager manager].alias = username;
}
~~~
~~~swift
// Swift
func loginSuccessful(username: String) {
    TwinPushManager.singleton().alias = username
}
~~~
The device will remain associated to that alias until the alias property is set to a different value. To remove the alias of a device, simply set the alias to nil.

### Sending user information

Through TwinPush SDK you can send information about application users, that you can use later for segmenting push targets or generate statistics. TwinPushManager offers methods for sending text, boolean, integer and float values.

The name that you to assign to every property will be visible from the TwinPush web portal.

~~~objective-c
// Objective-C
TwinPushManager* twinPush = [TwinPushManager manager];
[twinPush setProperty: @"gender" withStringValue: @"Male"];
[twinPush setProperty: @"allow notifications" withBooleanValue: @(YES)];
[twinPush setProperty: @"age" withIntegerValue: @(45)];
[twinPush setProperty: @"rating" withIntegerValue: @(7.45)];
~~~
~~~swift
// Swift
let twinPush = TwinPushManager.singleton()
twinPush.setProperty("gender", withStringValue: "Male")
twinPush.setProperty("allow notifications", withBooleanValue: true)
twinPush.setProperty("age", withIntegerValue: 45)
twinPush.setProperty("rating", withFloatValue: 7.45)
~~~

Use `nil` as the property value to delete that property for the current device.

### Conditional register

Sometimes you don't want to register devices to TwinPush right after starting the application. Common scenarios are waiting for a successful login to set the alias or skip registers with no push token. `TwinPushManagerDelegate` offers a way to control when a device should be registered with the method `shouldRegisterDeviceWithAlias`. To skip the register of a device, simply return `NO` (or `false` in Swift) and the device won't be registered.

This sample shows how to avoid registration of devices with no push token:

~~~objective-c
// Objective-C
- (BOOL)shouldRegisterDeviceWithAlias:(NSString *)alias token:(NSString *)token {
    return alias.length > 0;
}
~~~
~~~swift
// Swift
func shouldRegisterDeviceWithAlias(alias: String!, token: String!) -> Bool {
    return alias != nil && alias.utf16Count > 0
}
~~~

The following events will triger a device registration in TwinPush:

- Property `alias` changes from last register.

- Property `pushToken` changes from last register. Usually as a consequence of calling the convenience method `application:didRegisterForRemoteNotificationsWithDeviceToken:` of TwinPushManager.

- Method `application:didFinishLaunchingWithOptions:` of TwinPushManager is called for the first time.

- Operating system version, application version or sdk version changes from last register.

- Method `registerDevice` is explicitly called.

All events described above can be intercepted using `shouldRegisterDeviceWithAlias`.

### Register callback

To gain a fine-grained control of TwinPush the device registration status, `TwinPushManagerDelegate` offers some methods that will inform about events in the registration process. This is important because many of `TwinPushManager` will fail to send the information to the server if the device hasn't been registered yet.

These methods are:

- `shouldRegisterDeviceWithAlias:token:` allows conditionally register the device. Already discussed in the previous section.

- `didFinishRegisteringDevice` notifies when the device has been registered successfully or the alias or push token have been updated successfully

- `didFailRegisteringDevice` notifies about errors when trying to register the device and provides the details.

- `didSkipRegisteringDevice` notifies when the registration has been skipped. There are two reasons to skip a registration: the implementation for `shouldRegisterDeviceWithAlias` returned `NO` or no changes have been detected since the last successful registration.

### Custom rich notification viewer

TwinPush allows sending rich notifications to the device, that consists in a URL that is displayed in a web view. By default TwinPush SDK will show a full screen modal view containing the webview and a navigation bar. You can customize the navigation bar using [`UIAppearance`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAppearance_Protocol/) proxy. For further customization you can create your own rich notification viewer.

The most common scenario is creating the interface for a `TPNotificationDetailViewController` and assign the already created `IBOutlet` properties and `IBAction` methods. `TPNotificationDetailViewController` already provides some common functionality like loading notification details from TwinPush or handling `UIWebView` errors. 

![Custom viewer](http://developers.twinpush.com/assets/ios_step3-f6c2c34f5561e5206c37ae1df6847cf0.png)

If you need something more complex, you can subclass `TPNotificationDetailViewController` to reuse the code base or create a new rich content viewer from scratch. Either way the result will be a `UIViewController` that takes a notification object (`TPNotification`) and shows its rich content URL in a web view.

Once you have that controller, you have to override the default behavior to stop TwinPush from showing the default viewer. To achieve it, simply implement the method `showNotification`, declared in `TwinPushManagerDelegate`, in your application delegate and show your view controller. For example:

~~~objective-c
// Objective-C
#pragma mark - TwinPushManagerDelegate
- (void)showNotification:(TPNotification*)notification {
    // Only show content viewer for rich notifications
    if ([notification isRich]) {
        TPNotificationDetailViewController* customViewer = [[TPNotificationDetailViewController alloc] initWithNibName:@"CustomNotificationViewer" bundle:nil];
        customViewer.notification = notification;
        [self.window.rootViewController presentViewController:customViewer animated:YES completion:nil];
    }
}
~~~
~~~swift
// Swift
// MARK: TwinPushManagerDelegate
func showNotification(notification: TPNotification!) {
    // Only show content viewer for rich notifications
    if notification != nil && notification.rich {
        let customViewer = TPNotificationDetailViewController(nibName: "CustomNotificationViewer", bundle: nil)
        customViewer.notification = notification
        self.window?.rootViewController?.presentViewController(customViewer, animated: true, completion: nil)
    }
}
~~~

### Custom notification inbox

TwinPush also offers a Notification Inbox View Controller to let users browse through received rich notifications. This view controller can be integrated anywhere inside your application as a normal `UIViewController`. You can also define a custom appearance for the view controller to match the _look&feel_ of your App.

Users with push notifications disabled will be able to browse through the notifications even when they didn't received the push alert. This allows your users to not miss any important information even when they rejected to receive push notifications.

To include the inbox in your application, instantiate the class (or your custom subclass) of `TPNotificationsInboxViewController` and present it whenever you want. Common scenarios include showing the inbox inside a `UINavigationController`, as one more tab in a `UITabBarController` or presented modally. This sample shows how to present it modally:

~~~objective-c
// Objective-C
TPNotificationDetailViewController* inboxVC = [[TPNotificationsInboxViewController alloc] initWithNibName:@"CustomInboxVC" bundle:nil];
[self.window.rootViewController presentViewController:inboxVC animated:YES completion:nil];
~~~
~~~swift
// Swift
let inboxVC = TPNotificationsInboxViewController(nibName: "CustomInboxVC", bundle: nil)
self.window?.rootViewController?.presentViewController(inboxVC, animated: true, completion: nil)
~~~

You can also filter the notifications that are shown in the inbox view using filters. The filters are created in a `TPNotificationsFilters` object, where you can specify the tags you want to include or exclude from the inbox. You can also override the default pagination parameters usinga `TPNotificationPagination` object, specifying how many results you want per page, and the page you want to show. For example:

~~~objective-c
// Objective-C
TPNotificationsFilters* filters = [[TPNotificationsFilters alloc] init];
filters.tags = [NSArray arrayWithObjects:@"tag1", @"tag2", nil];
filters.noTags = [NSArray arrayWithObjects:@"notag1", @"notag2", nil];
self.filters = filters;

TPNotificationsPagination* pagination = [[TPNotificationsPagination alloc] init];
pagination.page = 1; // First page
pagination.resultsPerPage = 15;
self.pagination = pagination;

self.inboxOnlyRichNotifications = NO;

[self getInbox];
~~~
~~~swift
// Swift
let filters = TPNotificationsFilters()
filters.tags = ["tag1", "tag2"];
filters.noTags = ["notag1", "notag2"]
self.filters = filters

let pagination = TPNotificationsPagination()
pagination.page = 1 // First page
pagination.resultsPerPage = 15
self.pagination = pagination

self.inboxOnlyRichNotifications = false

self.getInbox()
~~~

Calling `getInbox` after the first successful load will load more pages if any exists. To reload from the first page, use `reloadInbox` method.

### Sending user location

You can send the location of your users to TwinPush to generate statistics and segment push notification targets by location.

#### Explicit location

If you have already obtained the location by other means, you can send to TwinPush it by calling the setLocation method.

~~~objective-c
// Objective-C
CLLocation* location = [[CLLocation alloc] initWithLatitude:40.383 longitude:-3.717];
[[TwinPushManager manager] setLocation:location];
// Or
[[TwinPushManager manager] setLocationWithLatitude:40.383 longitude:-3.717];
~~~
~~~swift
// Swift
let location = CLLocation(latitude: 40.383, longitude: -3.717)
TwinPushManager.singleton().setLocation(location)
// Or
TwinPushManager.singleton().setLocation(40.383, longitude: -3.717)
~~~

#### Automatic location

TwinPush can also obtain and send the location for you. In this case, you just have to specify the precision and TwinPush SDK will enable the GPS signal, obtain the user location with the specified precision, send it to TwinPush servers and disable the GPS to save battery life.

~~~objective-c
// Objective-C
// Update current location and send to TwinPush
[[TwinPushManager manager] updateLocation:kLocationPrecisionFine];
~~~
~~~swift
// Swift
// Update current location and send to TwinPush
TwinPushManager.singleton().updateLocation(TPLocationAccuracyFine)
~~~

Calling this method will ask the operating system for permissions to use the location while in use calling `requestWhenInUseAuthorization` method in `CLLocationManager` class. To configure your application for when in use location usage, you have to add the key `NSLocationWhenInUseUsageDescription` to your application plist file with a description about why your application requires the user location. This description will be shown to the user when asked about permissions, so make sure that you sound convincing ;) .

Example extracted from the demo included in the SDK:

~~~xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>TwinPush SDK Demo uses your location for demo purposes :)</string>
~~~

The service will keep running even when the application is closed or the device is restarted. To stop it:

~~~objective-c
// Objective-C
[[TwinPushManager manager] stopMonitoringLocationChanges];
~~~
~~~swift
// Swift
TwinPushManager.singleton().stopMonitoringLocationChanges()
~~~

### Custom Device UDID

The device UDID (Unique Device IDentifier) is the string that TwinPush uses to unequivocally identify every device. By default it uses the [`identifierForVendor`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIDevice_Class/#//apple_ref/occ/instp/UIDevice/identifierForVendor) based on Apple recomendation, but this can be changed to use any identifier that you want. Notable alternatives are the [`advertisingIdentifier`](advertisingIdentifier) for ad-enabled applications or [OpenUDID](https://github.com/ylechelle/OpenUDID) for AdHoc distributions.

To change the device identifier, set the property `deviceUDID` exposed in TwinPushManager __before__ calling `setupTwinPushManagerWithAppId:`.

~~~objective-c
// Objective-C
[TwinPushManager manager].deviceUDID = @"myNewID";
~~~
~~~swift
// Swift
TwinPushManager.singleton().deviceUDID = "myNewUDID"
~~~

Make sure to use a really unique identifier for each device, otherwise some devices may get overriden and will never receive push notifications.

## Custom domain

For Enterprise solutions, TwinPush offers the possibility of deploying the platform in a dedicated server. To address the requests made from the application to this new server, it is needed to specify its custom URL or domain.

`TwinPushManager` exposes the property `serverURL` for changing the server URL and a convenience property `serverSubdomain` for changing only the TwinPush subdomain. Setting the `serverURL` or `serverSubdomain` will override any previously set value to any of them.

~~~objective-c
// Objective-C
[TwinPushManager manager].serverURL = @"https://my-subdomain.twinpush.com/api/v2";
[TwinPushManager manager].serverSubdomain = @"my-subdomain";
~~~
~~~swift
// Swift
TwinPushManager.singleton().serverURL = "https://my-subdomain.twinpush.com/api/v2"
TwinPushManager.singleton().serverSubdomain = "my-subdomain"
~~~

Changing the server URL must be the very first call to `TwinPushManager`. Usually the right place is right before calling `setupTwinPushManagerWithAppId`.