//
//  TPAliasInboxViewController.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez on 11/8/16.
//  Copyright © 2016 TwinCoders. All rights reserved.
//

#import "TPAliasInboxViewController.h"
#import "TwinPushManager.h"

@implementation TPAliasInboxViewController

- (void)getInbox {
    self.loading = YES;
    [self.inboxTableView reloadData];
    [[TwinPushManager manager] getAliasNotificationsWithFilters:self.filters andPagination:self.pagination onComplete:^(NSArray *array, BOOL hasMore) {
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
            TCLog(@"Page: %ld and HasMore: %@", (long)self.pagination.page, hasMore ? @"YES" : @"NO");
        }
        [self.inboxTableView reloadData];
    } onError:^(NSError *error) {
        self.loading = NO;
        [self.inboxTableView reloadData];
        [self onRequestFailed:error];
    }];
}

- (void)deleteNotification:(TPNotification*)notification {
    self.loading = YES;
    [[TwinPushManager manager] deleteNotificationWithId:notification.notificationId onComplete:^{
        self.loading = NO;
        [self reloadInbox];
    } onError:^(NSError *error) {
        self.loading = NO;
        NSString* title = NSLocalizedStringWithDefaultValue(@"ERROR_DELETING_NOTIFICATION_TITLE", nil, [NSBundle mainBundle], @"Error", nil);
        NSString* message = NSLocalizedStringWithDefaultValue(@"ERROR_DELETING_NOTIFICATION_MSG", nil, [NSBundle mainBundle], @"Error deleting notification: ", nil);
        NSString* button = NSLocalizedStringWithDefaultValue(@"ERROR_DELETING_NOTIFICATION_BUTTON", nil, [NSBundle mainBundle], @"Accept", nil);
        
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}


- (void)onSelectedNotification:(TPNotification *)notification {
    [super onSelectedNotification:notification];
    if ([notification isKindOfClass:[TPInboxNotification class]]) {
        TPInboxNotification* inboxNotification = (TPInboxNotification*)notification;
        inboxNotification.openDate = [NSDate date];
        NSUInteger row = [self.notifications indexOfObject:notification];
        if (row != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.inboxTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}


@end
