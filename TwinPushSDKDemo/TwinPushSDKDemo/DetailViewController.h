//
//  DetailViewController.h
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TwinPushManager.h"

@interface DetailViewController : TPNotificationDetailViewController

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) IBOutlet UIView *webViewContainerView;
@property (strong, nonatomic) IBOutlet UIView *detailsContainerView;

@end
