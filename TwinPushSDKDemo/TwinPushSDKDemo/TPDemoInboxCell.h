//
//  TPTDemoInboxCell.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TwinPushManager.h"

@interface TPDemoInboxCell : TPInboxCell

#pragma mark - Properties
@property (nonatomic) BOOL highlightOnSelected;

#pragma mark - IBOutlets
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *highlightElements;

@end
