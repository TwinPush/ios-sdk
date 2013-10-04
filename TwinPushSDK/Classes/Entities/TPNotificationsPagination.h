//
//  TPNotificationsPagination.h
//  TwinPushSDK
//
//  Created by Diego Prados on 08/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPNotificationsPagination : NSObject

@property (nonatomic) NSInteger resultsPerPage;
@property (nonatomic) NSInteger page;

- (void)page:(NSInteger)page andResultsPerPage:(NSInteger)resultsPerPage;

@end
