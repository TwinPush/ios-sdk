//
//  TPNotificationsInboxViewController.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPNotificationsFilters.h"
#import "TPNotificationsPagination.h"
#import "TPNotificationDetailViewController.h"
#import "TPInboxCell.h"
#import "TPLoadingCell.h"
#import "TPNoResultsCell.h"

enum {
    kSectionNotifications,
    kSectionLoadingCell,
    kSectionNoResultsCell,
    kSectionCount
};

@protocol TPNotificationsInboxViewControllerDelegate <NSObject>

- (void)didFinishLoadingNotifications;

@optional
- (void)dismissModalView;
- (void)didSelectNotification:(TPNotification*)notification;
- (void)didFinishLoadingAllNotifications;

@end

@interface TPNotificationsInboxViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

#pragma mark - Properties
@property (strong, nonatomic) NSMutableArray* notifications;
@property (copy, nonatomic) NSString* cellIdentifier;
@property (copy, nonatomic) NSString* loadingCellIdentifier;
@property (nonatomic, getter = isInboxOnlyRichNotifications) BOOL inboxOnlyRichNotifications;
@property (copy, nonatomic) NSString* noResultsCellIdentifier;
@property (nonatomic, strong) TPNotificationsFilters* filters;
@property (nonatomic, strong) TPNotificationsPagination* pagination;
@property (weak, nonatomic) id<TPNotificationsInboxViewControllerDelegate> delegate;
@property (nonatomic, assign, getter = isLoading) BOOL loading;
@property (nonatomic, assign) NSInteger nextPage;
@property (nonatomic, assign) BOOL hasMore;

#pragma mark - IBOutlets
@property (strong, nonatomic) IBOutlet UITableView *inboxTableView;

#pragma mark - IBActions
- (IBAction)reloadInbox;

#pragma mark - Public methods
- (void)getInbox;

@end