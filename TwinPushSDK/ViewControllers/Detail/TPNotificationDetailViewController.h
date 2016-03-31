//
//  TPNotificationDetailViewController.h
//  TwinPushSDK
//
//  Created by Diego Prados on 25/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPNotification.h"

@protocol TPNotificationDetailViewControllerDelegate <NSObject>

@optional
- (void)dismissModalView;

@end

@interface TPNotificationDetailViewController : UIViewController <UIWebViewDelegate>

#pragma mark - Properties
@property (nonatomic, strong) TPNotification* notification;
@property (nonatomic, weak) id<TPNotificationDetailViewControllerDelegate> delegate;
@property (nonatomic, getter = isLoading) BOOL loading;
@property (nonatomic) BOOL requiresInitialization; // Set to NO if you are creating the GUI by yourself to avoid unwanted elements

#pragma mark - IBOutlets
@property (strong, nonatomic) IBOutlet UILabel *notificationTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *notificationDateLabel;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

#pragma mark - Public methods
- (void)webViewLoadFailedWithErrorCode:(NSString*)errorDescription;
- (void)fetchNotificationDetails;

#pragma mark - Actions
- (IBAction)dismissButtonTapped:(id)sender;

@end
