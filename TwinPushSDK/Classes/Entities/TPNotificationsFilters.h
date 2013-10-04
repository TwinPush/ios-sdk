//
//  TPNotificationsFilters.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPNotificationsFilters : NSObject

@property (nonatomic, strong) NSMutableArray* tags;
@property (nonatomic, strong) NSMutableArray* noTags;

- (void)filterWithTags:(NSMutableArray*)tags andNoTags:(NSMutableArray*)noTags;

@end
