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

@interface InboxViewController()

@property (nonatomic) CGFloat collapsedSearchBoxHeight;
@property (nonatomic) CGFloat expandedSearchBoxHeight;

@end

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
    self.expandedSearchBoxHeight = self.searchBoxHeightConstraint.constant;
    self.collapsedSearchBoxHeight = self.expandedSearchBoxHeight - self.searchFieldsContainerView.frame.size.height;
    [self.tableViewContainerView.layer setCornerRadius:10];
    [self.searchContainerView.layer setCornerRadius:10];
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
    [self.view layoutIfNeeded];
    self.searchBoxHeightConstraint.constant = alpha < 0.1 ? self.collapsedSearchBoxHeight : self.expandedSearchBoxHeight;
    [UIView animateWithDuration:0.3 animations:^{
        self.searchFieldsContainerView.alpha = alpha;
        self.collapseSearchSectionImageView.transform = transform;
        [self.view layoutIfNeeded];
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
