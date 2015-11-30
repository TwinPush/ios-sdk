//
//  DetailViewController.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "DetailViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation DetailViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.webViewContainerView.layer setCornerRadius:10];
    [self.detailsContainerView.layer setCornerRadius:10];
    [self.webViewContainerView.layer setBorderWidth:2];
    [self.webViewContainerView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self updateStatus];
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    [self updateStatus];
}

- (void)updateStatus {
    if (!self.loading) {
        [UIView animateWithDuration:0.5 animations:^{
            self.loadingView.alpha = 0;
        } completion:^(BOOL finished) {
            self.loadingView.hidden = YES;
        }];
        self.webViewContainerView.hidden = self.notification.contentUrl == nil;
    } else {
        self.loadingView.alpha = 0;
        self.loadingView.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{
            self.loadingView.alpha = 1;
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setLoadingView:nil];
    [self setLoadingLabel:nil];
    [self setWebViewContainerView:nil];
    [self setDetailsContainerView:nil];
    [super viewDidUnload];
}

@end
