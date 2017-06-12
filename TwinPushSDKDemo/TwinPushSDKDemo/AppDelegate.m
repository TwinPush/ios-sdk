//
//  AppDelegate.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "AppDelegate.h"
#import "TwinPushManager.h"
#import "ViewController.h"
#import "InboxViewController.h"
#import <CoreLocation/CoreLocation.h>


#pragma mark - App ID and API Key
// Set here your API Key and APP ID. If you don't have one already, go to https://app.twinpush.com
// to obtain your own key
#define TWINPUSH_APP_ID @"YOUR APP ID HERE"
#define TWINPUSH_API_KEY @"YOUR API KEY HERE"
#pragma mark -

@implementation AppDelegate

- (void)applyCustomAppearance {
    NSDictionary* titleAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],
                                      NSFontAttributeName: [UIFont fontWithName:@"MuseoSans-500" size:13]};
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:titleAttributes forState:UIControlStateNormal];
    
    // Set the text appearance for navbar
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSFontAttributeName: [UIFont fontWithName:@"MuseoSans-700" size:26]}];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{
                                        NSFontAttributeName:[UIFont fontWithName:@"MuseoSans-500" size:13.0f]}
                                                   forState:UIControlStateNormal];
}

- (void)configureCategories {
    if (![UNNotificationAction class]) {
        // Not available on iOS 9 or lower
        return;
    }
    
    UNNotificationCategory* generalCategory = [UNNotificationCategory
                                               categoryWithIdentifier:@"GENERAL"
                                               actions:@[]
                                               intentIdentifiers:@[]
                                               options:UNNotificationCategoryOptionCustomDismissAction];
    
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
    [center setNotificationCategories:[NSSet setWithObjects:generalCategory, richNotificationCategory, nil]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self applyCustomAppearance];
    [self configureCategories];
    
    [[TwinPushManager manager] enableCertificateNamePinningWithDefaultValues];
    [[TwinPushManager manager] setupTwinPushManagerWithAppId:TWINPUSH_APP_ID apiKey:TWINPUSH_API_KEY delegate:self];
    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[TwinPushManager manager] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Application did fail registering for remote notifications: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Received notification with contents: %@", userInfo);
    [[TwinPushManager manager] application:application didReceiveRemoteNotification:userInfo];
}

#pragma mark - Utility methods
- (UINavigationController*)navigationController {
    return (UINavigationController*) self.window.rootViewController;
}

- (ViewController*)registerViewController {
    return (ViewController*)[[self navigationController] viewControllers][0];
}

#pragma mark - TwinPushManagerDelegate
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

- (void)showNotification:(TPNotification*)notification {
    NSLog(@"Showing notification %@", notification.notificationId);
    if ([notification isRich]) {
        InboxViewController* inboxVC = nil;
        BOOL isOnInbox = [[[self navigationController] topViewController] isKindOfClass:[InboxViewController class]];
        if (!isOnInbox) {
            for (UIViewController* controller in [[self navigationController] viewControllers]) {
                if ([controller isKindOfClass:[InboxViewController class]]) {
                    inboxVC = (InboxViewController*) controller;
                    [[self navigationController] popToViewController:inboxVC animated:NO];
                    break;
                }
            }
        } else {
            inboxVC = (InboxViewController*) [[self navigationController] topViewController];
        }
        if (inboxVC != nil) {
            [inboxVC openNotification:notification];
        } else {
            [[self navigationController] popToRootViewControllerAnimated:NO];
            [[self registerViewController] showInbox:notification];
        }
    }
}

- (void)didFailRegisteringDevice:(NSString *)error {
    ViewController* vc = [self registerViewController];
    [vc showError:error];
}

- (void)didFinishRegisteringDevice {
    ViewController* vc = [self registerViewController];
    BOOL finishedRegistration = [vc registerCompleteWithDeviceId:[TwinPushManager manager].deviceId andAlias:[TwinPushManager manager].alias];
    if (finishedRegistration) {
        [[TwinPushManager manager] updateLocation:TPLocationAccuracyMedium];
    }
}

- (void)didSkipRegisteringDevice {
    [self didFinishRegisteringDevice];
}

@end
