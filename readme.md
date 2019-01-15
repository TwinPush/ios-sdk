TwinPush SDK Library
==================

[![Badge w/ Version](https://cocoapod-badges.herokuapp.com/v/TwinPushSDK/badge.png)](https://cocoapods.org/pods/TwinPushSDK)
[![Badge w/ Platform](https://cocoapod-badges.herokuapp.com/p/TwinPushSDK/badge.svg)](https://cocoapods.org/pods/TwinPushSDK)
[![License MIT](https://go-shields.herokuapp.com/license-MIT-blue.png)](https://github.com/TwinPush/ios-sdk/blob/master/LICENSE)

Native iOS SDK for [TwinPush platform](http://twinpush.com).

## Installation

To start using TwinPush you have to integrate the TwinPush SDK in your iOS application. You can download a working sample with the [TwinPush SDK sources](https://github.com/TwinPush/ios-sdk/archive/master.zip).

### Using CocoaPods

[CocoaPods](http://cocoapods.org/) is the easiest and most maintainable way to install TwinPush SDK. If you are using CocoaPods (that you should) just follow these steps:

1. Add a reference to the [TwinPush SDK pod](http://cocoapods.org/?q=twinpushsdk) to your `Podfile`.

	~~~
	pod 'TwinPushSDK'
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

To use TwinPush SDK in a Swift project, you can use any of the methods described above to install the SDK. When using CocoaPods you will have a `TwinPushSDK` module available to import, if you copied the sources you have to import TwinPushManager.h in your bridging header file to make it accessible from Swift code.

For more information check [Swift and Objective-C in the Same Project](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

## Basic TwinPush SDK Integration

Basic integration includes everything required to receive simple push notificaions.

Make your application delegate (usually named AppDelegate) to implement TwinPushManagerDelegate and add these methods:

~~~objective-c
// Objective-C
#import "TwinPushManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, TwinPushManagerDelegate> 

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
     [TwinPushManager manager].serverSubdomain = SUBDOMAIN;
    [[TwinPushManager manager] setupTwinPushManagerWithAppId:TWINPUSH_APP_ID apiKey:TWINPUSH_API_KEY delegate:self];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog("Registered for remote notifications with token: %@", deviceToken)
    [[TwinPushManager manager] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
    // Stuff to do in this method
    [[TwinPushManager manager] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Application did fail registering for remote notifications: %@", error);
}

@end
~~~

~~~swift
// Swift
class AppDelegate: UIResponder, UIApplicationDelegate, TwinPushManagerDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TwinPushManager.singleton().serverSubdomain = SUBDOMAIN;
        TwinPushManager.singleton().setupTwinPushManagerWithAppId(TWINPUSH_APP_ID, apiKey: TWINPUSH_API_KEY, delegate: self)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("Registered for remote notifications with token: %@", deviceToken.base64EncodedString())
        TwinPushManager.singleton().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        TwinPushManager.singleton().application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register for remote notifications with error: %@", (error as NSError).localizedDescription)
    }
}
~~~
Replace `SUBDOMAIN`, `TWINPUSH_APP_ID` and `TWINPUSH_API_KEY` with the configuration values for your application in [app.twinpush.com](http://app.twinpush.com). The method `setupTwinPushManagerWithAppId` must be called before any other TwinPushSDK method other than setting the subdomain or changing the server URL (see below).

At this point you should be able to register correctly to TwinPush and you should be able to receive push notifications if both the application and the server certificates have been configured correctly. If not, check the Troubleshooting section.


## Advanced SDK integration
If you followed the previous steps successfully you should be able to receive push notifications through TwinPush. To get the most out of TwinPush you can improve the SDK integration within your application to get user location, custom rich notification viewer or notification inbox.

Remember that you can check the source code of the Demo project included in the SDK sources to see a working sample.

### Updating badge count

The server badge count is used for auto incremental badge counts. TwinPush SDK will automatically reset the application and server badge count to zero when the application starts or a remote notification is received with the application open. You can deactivate this behavior by setting the `autoResetBadgeNumber` property of `TwinPushManager` to `NO`.

Additionally, you can update the local and server badge count of your application by calling `setApplicationBadgeCount:` method of `TwinPushManager` anywhere in your application:

~~~objective-c
// Objective-C
// Disable auto reset badge number on application startup
[TwinPushManager manager].autoResetBadgeNumber = NO;
// Update application badge count
[[TwinPushManager manager] setApplicationBadgeCount:0];
~~~
~~~swift
// Swift
// Disable auto reset badge number on application startup
TwinPushManager.singleton().autoResetBadgeNumber = false
// Update application badge count
TwinPushManager.singleton().setApplicationBadgeCount(0)
~~~

#### Obtaining server badge count

The server will update the badge count when sending a new notification. You can fetch the remote server badge count using the `getApplicationBadge` method of `TwinPushManager`:

~~~objective-c
// Objective-C
[[TwinPushManager manager] getApplicationBadgeOnComplete:^(NSInteger badge) {
    NSLog(@"Obtained remote badge count: %d", (int)badge);
} onError:^(NSError *error) {
    NSLog(@"Received error: %@", error);
}];
~~~
~~~swift
// Swift
TwinPushManager.singleton().getApplicationBadge(
    onComplete: { badge in print("Obtained remote badge count: \(badge)") },
    onError: { error in print("Received error: \(error!)") }
)
~~~

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

TwinPush SDK will automatically send information about the user device, like the operating system version, device model or the current locale. You can send additional information about your application users that you can use later for segmenting push targets or generate statistics. `TwinPushManager` offers methods for sending text, enum, boolean, integer and float values.

The name that you to assign to every property will be visible from the TwinPush web portal.

~~~objective-c
// Objective-C
TwinPushManager* twinPush = [TwinPushManager manager];
[twinPush setProperty: @"name" withStringValue: @"Bruce Banner"];
[twinPush setProperty: @"gender" withEnumValue: @"Male"];
[twinPush setProperty: @"allow notifications" withBooleanValue: @(YES)];
[twinPush setProperty: @"age" withIntegerValue: @(45)];
[twinPush setProperty: @"rating" withIntegerValue: @(7.45)];
~~~
~~~swift
// Swift
let twinPush: TwinPushManager = TwinPushManager.singleton()
twinPush.setProperty("name", withStringValue: "Bruce Banner")
twinPush.setProperty("gender", withEnumValue: "Male")
twinPush.setProperty("allow notifications", withBooleanValue: true)
twinPush.setProperty("age", withIntegerValue: 45)
twinPush.setProperty("rating", withFloatValue: 7.45)
~~~

Use `nil` as the property value to delete that property for the current device.

### Conditional register

Sometimes you don't want to register devices to TwinPush right after starting the application. Common scenarios are waiting for a successful login to set the alias or skip registers with no push token. `TwinPushManagerDelegate` offers a way to control when a device should be registered with the method `shouldRegisterDeviceWithAlias`. To skip the register of a device, simply return `NO` (or `false` in Swift) and the device won't be registered.

Devices not registered in the platform won't send usage statistics and will be unable to receive push notifications by any mean.

This sample shows how to avoid registration of devices with no alias:

~~~objective-c
// Objective-C
- (BOOL)shouldRegisterDeviceWithAlias:(NSString *)alias token:(NSString *)token {
    return alias.length > 0;
}
~~~
~~~swift
// Swift
func shouldRegisterDevice(withAlias alias: String!, token: String!) -> Bool {
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

### Notification Attachments

iOS 10 brings the hability to [mutate notification content](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ModifyingNotifications.html) before displaying it to the user. We're gonna use it to attach image, audio or video files to a notification, and it will be shown without opening the application.

![](http://i.imgur.com/fRkUqkH.gif)

First you have to create a new [Notification Service Extension](https://developer.apple.com/reference/usernotifications/unnotificationserviceextension). In XCode go to `File` -> `New` -> `Target` and select **Notification Service Extension**.

![](http://i.imgur.com/G34LtGh.png)

Enter a name for the extension and make sure to embed it to your application.

![](http://i.imgur.com/6ZCGEuq.png)

It will create a new target with a single class named `NotificationService`. Open it and replace it with the content of [the sample code provided](https://github.com/TwinPush/ios-sdk/blob/user-notification-framework/TwinPushSDKDemo/RichNotificationService/NotificationService.m) in the demo application. This reference code will download the attachment (defined in the `attachment` field of the payload) of the notification prior to showing the notification to the user.

To test this functionality make sure that `mutable-content` is set to `1` in the notification payload for the extension to be called. Check [`UNNotificationAttachment` reference](https://developer.apple.com/reference/usernotifications/unnotificationattachment) for supported file types and maximum file sizes.

#### Allowing non-secure attachment URL's
Notification Service Extension is a separate binary and **has its own Info.plist** file. To download the content from non-https URL (ex: http://) you have to add `App Transport Security Settings` with `Allow Arbitrary Loads` flag set to YES to **extension's Info.plist** file.

![](http://i.imgur.com/m7JlJ5N.png)

### Interactive notification actions

Custom actions allow the user to choose the action to take with a notification without having to open the application first. It requires a small integration in the application source code before they can be sent from the platform.

![](http://i.imgur.com/jCgoJUhl.jpg)

#### Register action categories

In order to show actionable notifications in your application, you have to register your actions associated to a category.

The following code is extracted from the SDK Demo.

~~~objective-c
// Objective-C
if (![UNNotificationAction class]) {
    // Requires iOS 10 or higher
    return;
}

UNNotificationAction* openAction = [UNNotificationAction
                                    actionWithIdentifier:@"OPEN"
                                    title:@"Open"
                                    options:UNNotificationActionOptionForeground];
UNNotificationAction* openInSafariAction = [UNNotificationAction
                                            actionWithIdentifier:@"SAFARI"
                                            title:@"Open in Safari"
                                            options:UNNotificationActionOptionForeground];

UNNotificationCategory* richNotificationCategory = [UNNotificationCategory
                                           categoryWithIdentifier:@"RICH"
                                           actions:@[openAction, openInSafariAction]
                                           intentIdentifiers:@[]
                                           options:UNNotificationCategoryOptionNone];

// Register the notification categories.
UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
[center setNotificationCategories:[NSSet setWithObjects: richNotificationCategory, nil]];
~~~
~~~swift
// Swift
guard #available(iOS 10, *) else { return }

let openAction = UNNotificationAction(identifier: "OPEN", title: "Open", options: .foreground)
let openInSafariAction = UNNotificationAction(identifier: "SAFARI", title: "Open in Safari", options: [])

let richNotificationCategory = UNNotificationCategory(
    identifier: "RICH",
    actions: [openAction, openInSafariAction],
    intentIdentifiers: [],
    options: [])

// Register the notification categories.
UNUserNotificationCenter.current().setNotificationCategories(Set([richNotificationCategory]))
~~~

The registered actions will appear like this when sending a notification with category set to `RICH`:

![](http://i.imgur.com/ywms3Z0l.png)

For further information check [_Configuring Categories and Actionable Notifications_](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SupportingNotificationsinYourApp.html#//apple_ref/doc/uid/TP40008194-CH4-SW26).

#### Handling notification action responses

Once the categories and actions are setup, you can handle the action responses from your application by implementing the method `didReceiveNotificationResponse:` of your `TwinPushManagerDelegate` and checking for the notification action identifier.

This code is extracted from the SDK Demo and will open the notification URL in Safari when _Open in Safari_ button is selected:

~~~objective-c
// Objective-C
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response {
    TPNotification* notification = [TPNotification notificationFromUserNotification:response.notification];
    NSURL* richURL = [NSURL URLWithString:notification.contentUrl];
    if ([response.actionIdentifier isEqualToString:@"SAFARI"] && richURL != nil) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            [[UIApplication sharedApplication] openURL:richURL];
        });
    }
    else {
        [self showNotification:notification];
    }
}
~~~
~~~swift
// Swift
@available(iOS 10.0, *)
func didReceive(_ response: UNNotificationResponse!) {
    let notification = TPNotification(fromUserNotification: response.notification)
    if response.actionIdentifier == "SAFARI", let urlString = notification?.contentUrl, let richUrl = URL(string: urlString) {
        DispatchQueue.global(qos: .background).async {
            UIApplication.shared.openURL(richUrl)
        }
    }
    else {
        show(notification)
    }
}
~~~

Notice how we check for `response.actionIdentifier` in order to know exactly which action was selected. In this scenario, if the user selected _Open in Safari_ (`SAFARI` identifier) in a rich notification, it will open Safari with the specified URL.

### Custom rich notification viewer

TwinPush allows sending rich notifications to the device, that consists in a URL that is displayed in a web view. By default TwinPush SDK will show a full screen modal view containing the webview and a navigation bar. You can customize the navigation bar using [`UIAppearance`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAppearance_Protocol/) proxy. For further customization you can create your own rich notification viewer.

The most common scenario is creating the interface for a `TPNotificationDetailViewController` and assign the already created `IBOutlet` properties and `IBAction` methods. `TPNotificationDetailViewController` already provides some common functionality like loading notification details from TwinPush or handling `UIWebView` errors. 

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
func show(_ notification: TPNotification!) {
    // Only show content viewer for rich notifications
    if let notification = notification, notification.isRich {
        let customViewer = TPNotificationDetailViewController(nibName: "CustomNotificationViewer", bundle: nil)
        customViewer.notification = notification
        self.window?.rootViewController?.present(customViewer, animated: true, completion: nil)
    }
}
~~~

### User notification inbox

TwinPush also offers a Notification Inbox View Controller to let users browse through received rich notifications. This view controller can be integrated anywhere inside your application as a normal `UIViewController`. You can also define a custom appearance for the view controller to match the _look&feel_ of your App.

Users with push notifications disabled will be able to browse through the notifications even when they didn't received the push alert. This allows your users to not miss any important information even when they rejected to receive push notifications.

To include the inbox in your application, instantiate the class (or your custom subclass) of `TPAliasInboxViewController ` and present it whenever you want. Common scenarios include showing the inbox inside a `UINavigationController`, as one more tab in a `UITabBarController` or presented modally. This sample shows how to present it modally:

~~~objective-c
// Objective-C
TPAliasInboxViewController* inboxVC = [[TPAliasInboxViewController alloc] initWithNibName:@"CustomInboxVC" bundle:nil];
[self.window.rootViewController presentViewController:inboxVC animated:YES completion:nil];
~~~
~~~swift
// Swift
let inboxVC = TPAliasInboxViewController(nibName: "CustomInboxVC", bundle: nil)
self.window?.rootViewController?.presentViewController(inboxVC, animated: true, completion: nil)
~~~

#### Delete inbox notification

Inbox notification can be removed by calling the `deleteNotification:` method of `TPAliasInboxViewController`. This sample shows how to show the swipe-to-delete option of the notification table rows and call the appropiate delete method. In your `TPAliasInboxViewController` subclass, implement the following methods:

~~~objective-c
// Objective-C
- (void)viewDidLoad {
    [super viewDidLoad];
    self.inboxTableView.allowsMultipleSelectionDuringEditing = NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        TPNotification* notification = self.notifications[indexPath.row];
        [self deleteNotification:notification];
    }
}
~~~
~~~swift
// Swift
override func viewDidLoad() {
    super.viewDidLoad()
    self.inboxTableView.allowsMultipleSelectionDuringEditing = false
}
override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if (editingStyle == .delete) {
        let notification = self.notifications[indexPath.row] as! TPNotification
        self.deleteNotification(notification)
    }
}
~~~

#### Device-based notification inbox

User inbox requires that the alias is assigned before presenting the inbox. Users without alias will receive an error when trying to show the alias inbox. If your application is not using alias you can use `TPNotificationInboxViewController` instead of `TPAliasInboxViewController` for inbox based on device instead of user alias.

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
TwinPushManager.singleton().setLocationWithLatitude(40.383, longitude: -3.717)
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

### Custom domain

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


### Custom data storage

TwinPushManager by default stores some data in `NSUserDefaults` to avoid unnecessary duplicated requests to the remote services. This storage can be overriden by implementing `storeValue:forKey` and `fetchValue` methods in `TwinPushManagerDelegate`.

This sample implementation uses [`SimpleKeychain`](https://github.com/auth0/SimpleKeychain) library to store the data encrypted in the iOS keychain:

~~~objective-c
// Objective-C
- (void)storeValue:(NSString *)value forKey:(NSString *)key {
    if (value != nil) {
        [[A0SimpleKeychain keychain] setString:value forKey:key];
    }
    else {
        [[A0SimpleKeychain keychain] deleteEntryForKey:key];
    }
}

- (NSString *)fetchValueForKey:(NSString *)key {
    return [[A0SimpleKeychain keychain] stringForKey:key];
}
~~~
~~~swift
// Swift
func storeValue(_ value: String!, forKey key: String!) {
    if (value != nil) {
        A0SimpleKeychain().setString(value, forKey: key)
    }
    else {
        A0SimpleKeychain().deleteEntry(forKey: key)
    }
}
    
func fetchValue(forKey key: String!) -> String! {
    return A0SimpleKeychain().string(forKey: key)
}
~~~

Please note that `value` might be `nil`.


### Handling different environments

It's a common practice to have different application registered in TwinPush for different environments. To handle the API keys gracefully in your application you can use preprocessor directives to distinguish between environments at compile time:

~~~objective-c
// Objective-C
#ifdef DEBUG
#define TWINPUSH_APP_ID @"<DEVEL_APP_ID>"
#define TWINPUSH_API_KEY @"<DEVEL_API_KEY>"
#else
#define TWINPUSH_APP_ID @"<PROD_APP_ID>"
#define TWINPUSH_API_KEY @"<PROD_API_KEY>"
#endif

[[TwinPushManager manager] setupTwinPushManagerWithAppId:TWINPUSH_APP_ID apiKey:TWINPUSH_API_KEY delegate:self];
~~~
~~~swift
// Swift
#if DEBUG
    let tpApiKey = "<DEVEL_API_KEY>"
    let tpAppId = "<DEVEL_APP_ID>"
#else
    let tpApiKey = "<PROD_API_KEY>"
    let tpAppId = "<PROD_APP_ID>"
#endif

TwinPushManager.singleton().setupTwinPushManager(withAppId: tpAppId, apiKey: tpApiKey, delegate: self)
~~~

In order for this to work properly, make sure that `DEBUG` is correctly defined in your project build settings:

![](https://i.imgur.com/NFm60iz.png)

You can change these names or add more configurations to the project. By default, `Debug` configuration will be used for debugging and `Release` configuration will be used when archiving. You can change the build configuration in `Product -> Scheme -> Edit Scheme` view:

![](https://i.imgur.com/cRODNwc.png)


### External device register

The external register mechanism allows you to replace the standard call to [/devices/register](http://developers.twinpush.com/developers/api#post-register) with a custom register method. This provides you full control over the registration and is useful if you want to perform the operation through another platform, to collect user information or to inject additional information.

To implement this functionality you simply have to provide a custom registration block in the `TwinPushManager` instance before the `setup`:

~~~objective-c
// Objective-C
[TwinPushManager manager].externalRegisterBlock = ^(TPRegisterInformation *info, TPRegisterCompletedBlock onComplete) {
    // Perform the registration manually and create a TPDevice from the TwinPush response
    TPDevice* device; // Obtain this device from the /devices/register result
    
    // Invoke onComplete block when the operation has been successful
    onComplete(device);
};
~~~
~~~swift
// Swift
TwinPushManager.singleton().externalRegisterBlock = { info, onComplete in
    // Perform the registration manually and create a TPDevice from the TwinPush response
    let device = TPDevice(); // Obtain this device from the /devices/register result
    
    // Invoke onComplete block when the operation has been successful
    onComplete!(device);
}
~~~