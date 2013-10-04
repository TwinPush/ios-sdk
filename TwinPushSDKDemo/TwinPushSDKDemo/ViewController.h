//
//  ViewController.h
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwinPushManager.h"

@interface ViewController : UIViewController <UITextFieldDelegate>

#pragma mark - Properties
@property (nonatomic, copy) NSString* errorMessage;

#pragma mark - IBOutlets
@property (weak, nonatomic) IBOutlet UITextField *aliasTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerDeviceButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *containerImageView;
@property (weak, nonatomic) IBOutlet UILabel *deviceAliasLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UITextField *ageTextField;
@property (weak, nonatomic) IBOutlet UIImageView *ageTextFieldBackground;
@property (weak, nonatomic) IBOutlet UILabel *buttonTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *textFieldImageView;
@property (weak, nonatomic) IBOutlet UILabel *registerConfirmationLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *locationSegmentedControl;

#pragma mark - IBActions
- (IBAction)registerDevice:(id)sender;
- (IBAction)hideKeyboard:(id)sender;
- (IBAction)locationSegmentChanged:(id)sender;

#pragma mark - Public methods
- (void)showError:(NSString*)errorMessage;
- (void)registerCompleteWithDeviceId:(NSString*)deviceId andAlias:(NSString*)alias;
- (void)showInbox;
- (void)showInbox:(TPNotification*)notification;

@end
