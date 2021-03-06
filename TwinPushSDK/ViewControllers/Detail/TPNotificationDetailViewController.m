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
#import "UIImage+UIBarButtonItem.h"

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
            
            WKWebView* webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
            webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.webView = webView;
            [self.view addSubview:webView];
            
            UIButton *button = [self createCloseButton];
            [self.view addSubview:button];
        }
        [self setNotificationDetails];
    }
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
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
        [[TwinPushManager manager] getDeviceNotificationWithId:self.notification.notificationId onComplete:^(TPNotification *notification) {
            if (notification != nil) {
                self.notification = notification;
                [self setNotificationDetails];
            }
            self.loading = NO;
        } onError:^(NSError *error) {
            [self onRequestFailed:error];
        }];
    }
    else {
        TCLog(@"Unable to fetch notification details until device is registered");
    }
}

- (void)onRequestFailed:(NSError *)error {
    NSString* title = NSLocalizedStringWithDefaultValue(@"GET_NOTIFICATIONS_ERROR_ALERT_TITLE", nil, [NSBundle mainBundle], @"Error", nil);
    [self displayAlert:error.localizedDescription withTitle:title];
}
    
#pragma mark - Private methods
- (UIButton*)createCloseButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* buttonImage = [[UIImage imageFromSystemBarButton:UIBarButtonSystemItemStop] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    button.tintColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [button addTarget:self
               action:@selector(dismissButtonTapped:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setImage:buttonImage forState:UIControlStateNormal];
    button.frame = CGRectMake(10, 30, 30, 30);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.layer.cornerRadius = button.frame.size.height / 2;
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    button.layer.borderWidth = 1;
    button.layer.borderColor = [[[UIColor blackColor] colorWithAlphaComponent:0.2] CGColor];
    return button;
}

- (void)setNotificationDetails {
    self.notificationTitleLabel.text = _notification.message;
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:kDateFormat];
    self.notificationDateLabel.text = [df stringFromDate:_notification.date];
    if (_notification.contentUrl != nil && _notification.contentUrl.length > 0) {
        NSURLRequest* urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:_notification.contentUrl]];
        [self.webView loadRequest:urlRequest];
    }
}

- (void)closeModal {
    if ([_delegate respondsToSelector:@selector(dismissModalView)]) {
        [_delegate dismissModalView];
    }
    else {
        if (self.navigationController != nil && self.navigationController.viewControllers.count > 1 && self.navigationController.viewControllers.lastObject == self) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else if (self.presentingViewController != nil || self.navigationController.presentingViewController != nil) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)displayAlert:(NSString*)alert withTitle:(NSString*)title {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:alert preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"WEBVIEW_LOADING_ERROR_BUTTON", nil, [NSBundle mainBundle], @"OK", nil) style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Public methods

- (void)webViewLoadFailedWithErrorCode:(NSString*)errorDescription {
    NSString* message = [NSString stringWithFormat:NSLocalizedString(@"WEBVIEW_LOADING_ERROR", nil), errorDescription];
    NSString* defaultMessage = [NSString stringWithFormat:@"An error happened when trying to load the rich content of the notificacion. Error code: %@", errorDescription];
    [self displayAlert:NSLocalizedStringWithDefaultValue(message, nil, [NSBundle mainBundle], defaultMessage, nil) withTitle:NSLocalizedStringWithDefaultValue(@"WEBVIEW_LOADING_ERROR_TITLE", nil, [NSBundle mainBundle], @"Error", nil)];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.loading = NO;
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
        NSURL* url = [NSURL URLWithString:self.notification.contentUrl];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                [self closeModal];
            }
            else {
                [self webViewLoadFailedWithErrorCode:error.localizedDescription];
            }
        }];
    }
    else {
        [self webViewLoadFailedWithErrorCode:error.localizedDescription];
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.loading = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.loading = NO;
}

#pragma mark - IBAction
- (IBAction)dismissButtonTapped:(id)sender {
    [self closeModal];
}

@end
