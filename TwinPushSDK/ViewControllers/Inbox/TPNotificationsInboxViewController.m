//
//  TPNotificationsInboxViewController.m
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPNotificationsInboxViewController.h"
#import "TwinPushManager.h"

static NSString* const kCellIdentifier = @"inboxCell";
static NSString* const kLoadingCellIdentifier = @"loadingCell";
static NSString* const kNoResultsCellIdentifier = @"noResultsCell";
static NSString* const kOnlyRichNotificationsTag = @"tp_rich";

@interface TPNotificationsInboxViewController ()

@property (nonatomic) NSInteger resultsPerPage;
@property (nonatomic, strong) TPLoadingCell* loadingCell;
@property (nonatomic, strong) TPNoResultsCell* noResultsCell;

@end

@implementation TPNotificationsInboxViewController

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
    // Do any additional setup after loading the view from its nib.
    if (_cellIdentifier == nil) {
        self.cellIdentifier = kCellIdentifier;
    }
    if (_loadingCellIdentifier == nil) {
        self.loadingCellIdentifier = kLoadingCellIdentifier;
    }
    if (_noResultsCellIdentifier == nil) {
        self.noResultsCellIdentifier = kNoResultsCellIdentifier;
    }
    if (_inboxTableView == nil) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.inboxTableView = [[UITableView alloc] initWithFrame:CGRectMake(5, 5, self.view.frame.size.width - 10, self.view.frame.size.height - 50)];
        [self.inboxTableView setDataSource:self];
        [self.inboxTableView setDelegate:self];
        [self.view addSubview:_inboxTableView];
        [self.inboxTableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self
                   action:@selector(closeModal)
         forControlEvents:UIControlEventTouchDown];
        [button setTitle:NSLocalizedStringWithDefaultValue(@"MODAL_NOTIFICATION_DETAIL_CLOSE_BUTTON", nil, [NSBundle mainBundle], @"Close", nil) forState:UIControlStateNormal];
        button.frame = CGRectMake(5, 20 + self.inboxTableView.frame.size.height, self.view.frame.size.width - 10, 30);
        [self.view addSubview:button];
    }
    [self calculateResultsPerPage];
    self.hasMore = YES;
    self.inboxOnlyRichNotifications = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_notifications == nil) {
        [self getInbox];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setInboxTableView:nil];
    [super viewDidUnload];
}

#pragma mark - Private methods

- (void)closeModal {
    [self.delegate dismissModalView];
}

- (void)calculateResultsPerPage {
    self.resultsPerPage = (_inboxTableView.frame.size.height / _inboxTableView.rowHeight > 0 ? _inboxTableView.rowHeight : 44) * 1.2;
    if (self.filters == nil) {
        self.filters = [[TPNotificationsFilters alloc] init];
        self.filters.tags = [NSMutableArray array];
        self.filters.noTags = [NSMutableArray array];
    }
    if (self.pagination == nil) {
        self.pagination = [[TPNotificationsPagination alloc] init];
        self.pagination.resultsPerPage = _resultsPerPage;
    }
    self.pagination.page = 1;
}

- (void)setFiltersForRichNotificationsFlag {
    if ([self isInboxOnlyRichNotifications]) {
        if (![_filters.tags containsObject:kOnlyRichNotificationsTag]) {
            [self.filters.tags addObject:kOnlyRichNotificationsTag];
        }
    } else {
        if ([_filters.tags containsObject:kOnlyRichNotificationsTag]) {
            [self.filters.tags removeObject:kOnlyRichNotificationsTag];
        }
    }
}

#pragma mark - Public methods

- (void)getInbox {
    self.loading = YES;
    [_inboxTableView reloadData];
    [self setFiltersForRichNotificationsFlag];
    [[TwinPushManager manager] getDeviceNotificationsWithFilters:_filters andPagination:_pagination onComplete:^(NSArray *array, BOOL hasMore) {
        if (self.notifications.count == 0) {
            self.notifications = [NSMutableArray arrayWithArray:array];
        } else {
            [self.notifications addObjectsFromArray:array];
        }
        [self.delegate didFinishLoadingNotifications];
        self.loading = NO;
        self.hasMore = hasMore;
        if (hasMore) {
            self.pagination.page += 1;
            TCLog(@"Page: %ld and HasMore: %@", (long)self.pagination.page, _hasMore ? @"YES" : @"NO");
        }
        [_inboxTableView reloadData];
    } onError:^(NSError *error) {
        self.loading = NO;
        [_inboxTableView reloadData];
        [self onRequestFailed:error];
    }];
}

- (void)onSelectedNotification:(TPNotification*)notification {
    NSString* notificationId = [NSString stringWithFormat:@"%@", notification.notificationId];
    [[TwinPushManager manager] userDidOpenNotificationWithId:notificationId];
    [self.delegate didSelectNotification:notification];
}

- (void)onRequestFailed:(NSError *)error {
    NSString* title = NSLocalizedStringWithDefaultValue(@"GET_NOTIFICATIONS_ERROR_ALERT_TITLE", nil, [NSBundle mainBundle], @"Error", nil);
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringWithDefaultValue(@"DEVICE_REGISTERED_ALERT_ACCEPT_BUTTON", nil, [NSBundle mainBundle], @"Accept", nil) style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
    
- (TPInboxCell*)createCell {
    return [[TPInboxCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_cellIdentifier];
}

- (TPLoadingCell*)createLoadingCell {
    return [[TPLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_loadingCellIdentifier];
}

- (TPNoResultsCell*)createNoResultsCell {
    return [[TPNoResultsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_noResultsCellIdentifier];
}

#pragma mark - IBActions

- (IBAction)reloadInbox {
    self.notifications = nil;
    self.hasMore = YES;
    [self calculateResultsPerPage];
    [self getInbox];
}

#pragma mark - UITableViewDelegate

- (BOOL)hasResults {
    return self.notifications.count > 0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    switch (section) {
        case kSectionNotifications:
            rowCount = _notifications.count;
            break;
        case kSectionLoadingCell:
            rowCount = self.loading || (self.notifications.count > 0 && self.hasMore) ? 1 : 0;
            break;
        case kSectionNoResultsCell:
            rowCount = !self.loading && _notifications.count == 0 ? 1 : 0;
            break;
    }
    return rowCount;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.notifications.count > 0 && !self.loading && indexPath.section == kSectionLoadingCell) {
        [self getInbox];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = nil;
    switch (indexPath.section) {
        case kSectionNotifications:
            if ([self hasResults]) {
                TPInboxCell* inboxCell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier];
                if (inboxCell == nil) {
                    inboxCell = [self createCell];
                }
                inboxCell.notification = self.notifications[indexPath.row];
                cell = inboxCell;
            }
            break;
        case kSectionLoadingCell:
            _loadingCell = [tableView dequeueReusableCellWithIdentifier:_loadingCellIdentifier];
            if (_loadingCell == nil) {
                self.loadingCell = [self createLoadingCell];
            }
            [_loadingCell.spinner startAnimating];
            _loadingCell.userInteractionEnabled = NO;
            cell = _loadingCell;
            break;
        case kSectionNoResultsCell:
            self.noResultsCell = [tableView dequeueReusableCellWithIdentifier:_noResultsCellIdentifier];
            if (_noResultsCell == nil) {
                _noResultsCell = [self createNoResultsCell];
            }
            _noResultsCell.userInteractionEnabled = NO;
            cell = _noResultsCell;
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TPNotification* notification = self.notifications[indexPath.row];
    [self onSelectedNotification:notification];
}

@end
