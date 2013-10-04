//
//  TPNotificationsFilters.m
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPNotificationsFilters.h"

@implementation TPNotificationsFilters

- (id)init {
    self = [super init];
    if (self) {
    
    }
    return self;
}

- (void)filterWithTags:(NSMutableArray*)tags andNoTags:(NSMutableArray*)noTags {
    self.tags = tags;
    self.noTags = noTags;
}

@end
