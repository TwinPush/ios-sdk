//
//  TPNotificationsPagination.m
//  TwinPushSDK
//
//  Created by Diego Prados on 08/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPNotificationsPagination.h"

@implementation TPNotificationsPagination

- (id)init {
    self = [super init];
    if (self) {
        self.page = 1;
        self.resultsPerPage = 0;
    }
    return self;
}

- (void)page:(NSInteger)page andResultsPerPage:(NSInteger)resultsPerPage {
    self.page = page;
    self.resultsPerPage = resultsPerPage;
}

@end
