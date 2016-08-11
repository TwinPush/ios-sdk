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
    [[TwinPushManager manager] getAliasNotificationsWithPagination:self.pagination onComplete:^(NSArray *array, BOOL hasMore) {
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
    }];
}

@end
