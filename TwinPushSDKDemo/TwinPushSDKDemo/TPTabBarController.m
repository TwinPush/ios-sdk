//
//  TPTabBarController.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPTabBarController.h"

@interface TPTabBarController ()

@end

@implementation TPTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self configureAppearance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private methods
- (void)configureAppearance {
    self.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"caja_seleccion"];
    [self.tabBar setBackgroundImage:[UIImage imageNamed:@"tabbar"]];
    [self.tabBar setSelectionIndicatorImage:[UIImage imageNamed:@"tabbar_h"]];
    
    NSDictionary* titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [UIFont fontWithName:@"MuseoSans-700" size:10],
                                     UITextAttributeFont,
                                     [UIColor whiteColor],
                                     UITextAttributeTextColor,
                                     nil];
    
    for (UIViewController* viewController in self.viewControllers) {
        UITabBarItem* tabbarItem = viewController.tabBarItem;
        UIImage* image = nil;
        
        [tabbarItem setImageInsets:UIEdgeInsetsMake (4, 0, -4, 0)];
        [tabbarItem setTitlePositionAdjustment:UIOffsetMake(0, 1)];
        [tabbarItem setTitleTextAttributes:titleAttributes forState:UIControlStateNormal];
        [tabbarItem setTitleTextAttributes:titleAttributes forState:UIControlStateSelected];
        
        switch (tabbarItem.tag) {
            case kTabBarItemRegister: {
                image = [UIImage imageNamed:@"icon_device"];
                break;
            }
            case kTabBarItemInbox: {
                image = [UIImage imageNamed:@"icon_inbox"];
                break;
            }
            default:
                break;
        }
        
        [tabbarItem setFinishedSelectedImage:image withFinishedUnselectedImage:image];
    }
}

@end
