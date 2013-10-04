//
//  InboxViewController.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 28/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "InboxViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "DetailViewController.h"

static NSString* const kCommaSeparator = @",";
static NSString* const kDetailSegue = @"detail";
static NSString* const kCellIdentifier = @"inboxCell";
static NSString* const kFont300 = @"MuseoSans-300";
static NSString* const kFont500 = @"MuseoSans-500";
static NSString* const kFont700 = @"MuseoSans-700";

@implementation InboxViewController

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
    self.cellIdentifier = kCellIdentifier;
    self.tagsTextField.delegate = self;
    self.noTagsTextField.delegate = self;
    self.delegate = self;
    [self.tableViewContainerView.layer setCornerRadius:10];
    [self.searchContainerView.layer setCornerRadius:10];
    self.searchLabel.font = [UIFont fontWithName:kFont700 size:16];
    self.includeTagsLabel.font = [UIFont fontWithName:kFont500 size:12];
    self.notIncludeTagsLabel.font = [UIFont fontWithName:kFont500 size:12];
    self.tagsTextField.font = [UIFont fontWithName:kFont300 size:13];
    self.noTagsTextField.font = [UIFont fontWithName:kFont300 size:13];
    [self hideSearchFields:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTagsTextField:nil];
    [self setNoTagsTextField:nil];
    [self setReloadInboxButton:nil];
    [self setTableViewContainerView:nil];
    [self setSearchContainerView:nil];
    [self setHideSearchFieldsButton:nil];
    [self setSearchFieldsContainerView:nil];
    [self setCollapseSearchSectionImageView:nil];
    [self setSearchLabel:nil];
    [self setIncludeTagsLabel:nil];
    [self setNotIncludeTagsLabel:nil];
    [self setTagsTextFieldImageView:nil];
    [self setNoTagsTextFieldImageView:nil];
    [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.selectedNotification != nil) {
        [self openNotification:self.selectedNotification];
    }
}

#pragma mark - Private methods

- (TPNotificationsFilters*)createFilters {
    TPNotificationsFilters* filters = [[TPNotificationsFilters alloc] init];
    if (![_tagsTextField.text isEqualToString:@""]) {
        filters.tags = [NSMutableArray arrayWithArray:[_tagsTextField.text componentsSeparatedByString:kCommaSeparator]];
    } else {
        filters.tags = nil;
    }
    if (![_noTagsTextField.text isEqualToString:@""]) {
        filters.noTags = [NSMutableArray arrayWithArray:[_noTagsTextField.text componentsSeparatedByString:kCommaSeparator]];
    } else {
        filters.noTags = nil;
    }
    return filters;
}

- (void)transformSearhFieldsViewWithAlpha:(NSInteger)alpha andHeight:(CGFloat)height andTransformArrowWithAngle:(CGFloat)angle {
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    [UIView animateWithDuration:0.3 animations:^{
        self.searchFieldsContainerView.alpha = alpha;
        self.searchContainerView.frame = CGRectMake(_searchContainerView.frame.origin.x, _searchContainerView.frame.origin.y, _searchContainerView.frame.size.width, _searchContainerView.frame.size.height + height);
        self.collapseSearchSectionImageView.transform = transform;
        self.tableViewContainerView.frame = CGRectMake(_tableViewContainerView.frame.origin.x, _tableViewContainerView.frame.origin.y + height, _tableViewContainerView.frame.size.width, _tableViewContainerView.frame.size.height - height);
    }];
}

- (void)highlightTextField:(UITextField*)textField highlighted:(BOOL)highlighted {
    if (textField == _tagsTextField) {
        _tagsTextFieldImageView.highlighted = highlighted;
    } else {
        _noTagsTextFieldImageView.highlighted = highlighted;
    }
}

#pragma mark - Public methods
- (void)openNotification:(TPNotification*)notification {
    self.selectedNotification = notification;
    
    [self performSegueWithIdentifier:kDetailSegue sender:self];
}

#pragma mark - TPNotificationsInboxViewControllerDelegate

- (void)didSelectNotification:(TPNotification *)notification {
    self.selectedNotification = notification;
    [self performSegueWithIdentifier:kDetailSegue sender:self];
}

- (void)didFinishLoadingNotifications {
    // Redimensionar la tabla
}

#pragma mark - prepare for segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:kDetailSegue]) {
        DetailViewController* detailViewController = segue.destinationViewController;
        
        detailViewController.notification = self.selectedNotification;
        self.selectedNotification = nil;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self reload:nil];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self highlightTextField:textField highlighted:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self highlightTextField:textField highlighted:NO];
}

#pragma mark - IBActions

- (IBAction)hideSearchFields:(id)sender {
    [_tagsTextField resignFirstResponder];
    [_noTagsTextField resignFirstResponder];
    if (_searchContainerView.frame.size.height > _searchFieldsContainerView.frame.size.height) {
        [self transformSearhFieldsViewWithAlpha:0 andHeight:(-_searchFieldsContainerView.frame.size.height) andTransformArrowWithAngle:M_PI];
    } else {
        [self transformSearhFieldsViewWithAlpha:1 andHeight:(_searchFieldsContainerView.frame.size.height) andTransformArrowWithAngle:0];
    }
}

- (IBAction)reload:(id)sender {
    self.filters = [self createFilters];
    [super reloadInbox];
}

@end
