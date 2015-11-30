//
//  InboxViewController.h
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 28/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPNotificationsInboxViewController.h"

@interface InboxViewController : TPNotificationsInboxViewController <TPNotificationsInboxViewControllerDelegate, UITextFieldDelegate>

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet UITextField *noTagsTextField;
@property (weak, nonatomic) IBOutlet UIButton *reloadInboxButton;
@property (weak, nonatomic) IBOutlet UIView *tableViewContainerView;
@property (weak, nonatomic) IBOutlet UIView *searchContainerView;
@property (weak, nonatomic) IBOutlet UIButton *hideSearchFieldsButton;
@property (weak, nonatomic) IBOutlet UIView *searchFieldsContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *collapseSearchSectionImageView;
@property (weak, nonatomic) IBOutlet UILabel *searchLabel;
@property (weak, nonatomic) IBOutlet UILabel *includeTagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *notIncludeTagsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tagsTextFieldImageView;
@property (weak, nonatomic) IBOutlet UIImageView *noTagsTextFieldImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBoxHeightConstraint;

#pragma mark - IBActions
- (IBAction)hideSearchFields:(id)sender;
- (IBAction)reload:(id)sender;

#pragma mark - Public methods
- (void)openNotification:(TPNotification*)notification;

@property (nonatomic, strong) TPNotification* selectedNotification;

@end
