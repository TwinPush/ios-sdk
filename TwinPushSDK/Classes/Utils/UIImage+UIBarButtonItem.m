//
//  UIImage+UIBarButtonItem.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 23/6/17.
//  Copyright © 2017 TwinCoders. All rights reserved.
//

#import "UIImage+UIBarButtonItem.h"

@implementation UIImage(UIBarButtonItem)

+ (UIImage *)imageFromSystemBarButton:(UIBarButtonSystemItem)systemItem {
    UIBarButtonItem* tempItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:nil action:nil];
    
    // Add to toolbar and render it
    [[[UIToolbar alloc] init] setItems:@[tempItem] animated:false];
    
    // Ger image from real UIButton
    UIView *itemView = [(id)tempItem view];
    for (UIView* view in itemView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            return [(UIButton*)view imageForState:UIControlStateNormal];
        }
    }
    
    return nil;
}

@end
