//
//  TPNotificationDetailViewController.m
//  TwinPushSDK
//
//  Created by Diego Prados on 25/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPNotificationDetailViewController.h"
#import "TwinPushManager.h"
#import <QuartzCore/QuartzCore.h>

static NSString* const kDateFormat = @"yyyy-MM-dd HH:mm:ss";

@interface TPNotificationDetailViewController ()

@end

@implementation TPNotificationDetailViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (( self = [super initWithCoder:aDecoder] )) {
        
    }
    return self;
}

- (instancetype)init {
    if (( self = [super init])) {
        self.requiresInitialization = YES;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (_notification != nil) {
        if (self.requiresInitialization) {
            // Build the default GUI
            self.view.backgroundColor = [UIColor whiteColor];
            self.notificationDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width - 10, 30)];
            [self.view addSubview:_notificationDateLabel];
            self.notificationTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5 + _notificationDateLabel.frame.size.height, self.view.frame.size.width - 10, 30)];
            [self.view addSubview:_notificationTitleLabel];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button addTarget:self
                       action:@selector(closeModal)
             forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:NSLocalizedStringWithDefaultValue(@"MODAL_NOTIFICATION_DETAIL_CLOSE_BUTTON", nil, [NSBundle mainBundle], @"Close", nil) forState:UIControlStateNormal];
            button.frame = CGRectMake(5, 20 + _notificationTitleLabel.frame.size.height, self.view.frame.size.width - 10, 30);
            [self.view addSubview:button];
        }
        [self setNotificationDetails];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![self.notification isComplete]) {
        [self fetchNotificationDetails];
    }
}

- (void)viewDidUnload {
    [self setNotificationTitleLabel:nil];
    [self setNotificationDateLabel:nil];
    [self setWebView:nil];
    [super viewDidUnload];
}

#pragma mark - Public methods
- (void)fetchNotificationDetails {
    if ([TwinPushManager manager].deviceId != nil) {
        self.loading = YES;
        [[TwinPushManager manager] getDeviceNotificationWithId:self.notification.notificationId.integerValue onComplete:^(TPNotification *notification) {
            if (notification != nil) {
                self.notification = notification;
                [self setNotificationDetails];
            }
            self.loading = NO;
        }];
    }
    else {
        TCLog(@"Unable to fetch notification details until device is registered");
    }
}

#pragma mark - Private methods
- (void)setNotificationDetails {
    self.notificationTitleLabel.text = _notification.message;
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:kDateFormat];
    self.notificationDateLabel.text = [df stringFromDate:_notification.date];
    if (_notification.contentUrl != nil && _notification.contentUrl.length > 0) {
        NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_notification.contentUrl]];
        [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    }
}

- (void)closeModal {
    if ([_delegate respondsToSelector:@selector(dismissModalView)]) {
        [_delegate dismissModalView];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)displayAlert:(NSString*)alert withTitle:(NSString*)title {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:alert delegate:nil cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"WEBVIEW_LOADING_ERROR_BUTTON", nil, [NSBundle mainBundle], @"OK", nil) otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - Public methods

- (void)webViewLoadFailedWithErrorCode:(NSString*)errorDescription {
    NSString* message = [NSString stringWithFormat:NSLocalizedString(@"WEBVIEW_LOADING_ERROR", nil), errorDescription];
    NSString* defaultMessage = [NSString stringWithFormat:@"An error happened when trying to load the rich content of the notificacion. Error code: %@", errorDescription];
    [self displayAlert:NSLocalizedStringWithDefaultValue(message, nil, [NSBundle mainBundle], defaultMessage, nil) withTitle:NSLocalizedStringWithDefaultValue(@"WEBVIEW_LOADING_ERROR_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_notification.contentUrl]]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self webViewLoadFailedWithErrorCode:error.localizedDescription];
}

- (IBAction)dismissButtonTapped:(id)sender {
    [self closeModal];
}

@end