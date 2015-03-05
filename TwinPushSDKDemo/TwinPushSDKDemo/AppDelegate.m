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
#define TWINPUSH_APP_ID @"----"
#define TWINPUSH_API_KEY @"-----------------------------"
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self applyCustomAppearance];
    
    [[TwinPushManager manager] enableCertificateNamePinningWithDefaultValues];
    [[TwinPushManager manager] setupTwinPushManagerWithAppId:TWINPUSH_APP_ID apiKey:TWINPUSH_API_KEY delegate:self];
    [[TwinPushManager manager] application:application didFinishLaunchingWithOptions:launchOptions];
    [[TwinPushManager manager] setApplicationBadgeCount:0];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    /**** Application Open *****/
    [[TwinPushManager manager] applicationDidBecomeActive:application];
    [[TwinPushManager manager] updateLocation:TPLocationAccuracyMedium];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    /**** Application Close *****/
    [[TwinPushManager manager] applicationWillResignActive:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    // Reset App icon badge
    [[TwinPushManager manager] setApplicationBadgeCount:0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[TwinPushManager manager] setApplicationBadgeCount:0];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[TwinPushManager manager] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Application did fail registering for remote notifications: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
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

- (void)showNotification:(TPNotification*)notification {
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
    [vc registerCompleteWithDeviceId:[TwinPushManager manager].deviceId andAlias:[TwinPushManager manager].alias];
}

@end
