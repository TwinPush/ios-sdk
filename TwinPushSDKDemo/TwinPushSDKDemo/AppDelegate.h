//
//  AppDelegate.h
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwinPushManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, TwinPushManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
