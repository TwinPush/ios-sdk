//
//  ViewController.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "ViewController.h"
#import "InboxViewController.h"

static NSString* const kInboxSegue = @"inbox";
static NSString* const kAliasKey = @"alias";
static NSString* const kDeviceIdKey = @"deviceId";
/* Gender */
static NSString* const kGenderKey = @"gender";
static NSString* const kGenderMale = @"Male";
static NSString* const kGenderFemale = @"Female";
/* Age */
static NSString* const kAgeKey = @"age";

@interface ViewController ()

@property (nonatomic, getter = isRegistered) BOOL registered;
@property (nonatomic, getter = isRegistrationAsked) BOOL registrationAsked;
@property (nonatomic, strong) TPNotification* notification;

@end

typedef NS_ENUM(NSInteger, TPLocationSegment) {
    TPLocationSegmentOnOpen,
    TPLocationSegmentSignificant,
};

@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    // Do any additional setup after loading the view, typically from a nib.
    self.registered = NO;
    self.aliasTextField.delegate = self;
    self.spinner.hidden = YES;
    // Load previous properties
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* savedAlias = [defaults stringForKey:kAliasKey];
    if (savedAlias) {
        self.aliasTextField.text = savedAlias;
    }
    if ([defaults objectForKey:kAgeKey]) {
        NSString* age = [NSString stringWithFormat:@"%ld", (long)[defaults integerForKey:kAgeKey]];
        [self.ageTextField setText:age];
    }
    if ([defaults objectForKey:kGenderKey]) {
        [self.genderSegmentedControl setSelectedSegmentIndex:[defaults integerForKey:kGenderKey]];
    }
    TwinPushManager* twinPush = [TwinPushManager manager];
    if ([twinPush isMonitoringSignificantChanges]) {
        [self.locationSegmentedControl setSelectedSegmentIndex:TPLocationSegmentSignificant];
    }
}

- (void)viewDidUnload {
    [self setAliasTextField:nil];
    [self setRegisterDeviceButton:nil];
    [self setSpinner:nil];
    [self setContainerImageView:nil];
    [self setDeviceAliasLabel:nil];
    [self setTextFieldImageView:nil];
    [self setAgeLabel:nil];
    [self setAgeTextField:nil];
    [self setAgeTextFieldBackground:nil];
    [self setGenderSegmentedControl:nil];
    [self setLocationSegmentedControl:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self updateRegisterInfo];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self enableButton:YES];
}

#pragma mark - Private methods

- (void)enableButton:(BOOL)enable {
    self.registerDeviceButton.enabled = enable;
    self.aliasTextField.enabled = enable;
    self.spinner.hidden = enable;
    if (enable) {
        [_spinner stopAnimating];
        self.registerDeviceButton.alpha = 1;
    } else {
        [_spinner startAnimating];
        self.registerDeviceButton.alpha = 0.5;
    }
}

#pragma mark - Public methods
- (void)showError:(NSString*)errorMessage {
    self.errorMessage = errorMessage;
    [self enableButton:YES];
}

-(void) updateRegisterInfo {
    if ([TwinPushManager manager].alias != nil && [TwinPushManager manager].deviceId != nil) {
        self.aliasTextField.text = [TwinPushManager manager].alias;
    }
}

- (BOOL)registerCompleteWithDeviceId:(NSString*)deviceId andAlias:(NSString*)alias {
    self.errorMessage = nil;
    [self enableButton:YES];
    self.registered = YES;
    [self updateRegisterInfo];
    if (self.isRegistrationAsked) {
        [self showInbox];
    }
    return self.isRegistrationAsked;
}

- (void)showInbox {
    [self showInbox:nil];
}
- (void)showInbox:(TPNotification*)notification {
    self.notification = notification;
    [self performSegueWithIdentifier:kInboxSegue sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kInboxSegue]) {
        if (self.notification != nil) {
            InboxViewController* inboxVC = (InboxViewController*) segue.destinationViewController;
            inboxVC.selectedNotification = self.notification;
        }
    }
}

#pragma mark - IBActions

- (IBAction)registerDevice:(id)sender {
    self.registrationAsked = YES;
    [self enableButton:NO];
    [self.view endEditing:NO];
    NSString* alias = [_aliasTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString* ageString = [_ageTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSNumber* age = ageString.length > 0 ? @(_ageTextField.text.integerValue) : nil;
    NSString* gender = [_genderSegmentedControl selectedSegmentIndex] == 0 ? kGenderMale : kGenderFemale;
    TwinPushManager* twinPush = [TwinPushManager manager];
    [twinPush setAlias:alias];
    [twinPush setProperty:kAgeKey withIntegerValue:age];
    [twinPush setProperty:kGenderKey withEnumValue:gender];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (age.integerValue > 0) {
        [defaults setInteger:age.integerValue forKey:kAgeKey];
    } else {
        [defaults removeObjectForKey:kAgeKey];
    }
    [defaults setObject:alias forKey:kAliasKey];
    [defaults setInteger:_genderSegmentedControl.selectedSegmentIndex forKey:kGenderKey];
    [defaults synchronize];
}

- (IBAction)hideKeyboard:(id)sender {
    [_aliasTextField resignFirstResponder];
}

- (IBAction)locationSegmentChanged:(id)sender {
    TwinPushManager* twinPush = [TwinPushManager manager];
    switch (self.locationSegmentedControl.selectedSegmentIndex) {
        case TPLocationSegmentOnOpen:
            [twinPush stopMonitoringLocationChanges];
            break;
        case TPLocationSegmentSignificant:
            [twinPush startMonitoringLocationChanges];
            break;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.aliasTextField) {
        [self.ageTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.aliasTextField) {
        self.textFieldImageView.highlighted = YES;
    } else if (textField == self.ageTextField) {
        self.ageTextFieldBackground.highlighted = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.aliasTextField) {
        self.textFieldImageView.highlighted = NO;
    } else if (textField == self.ageTextField) {
        self.ageTextFieldBackground.highlighted = NO;
    }
}


@end
