//
//  TPDemoLoadingCell.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPDemoLoadingCell.h"

@implementation TPDemoLoadingCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UIFont *font;
    if (_fontName.length == 0) {
        font = [UIFont systemFontOfSize:_fontSize];
    } else {
        font = [UIFont fontWithName:_fontName size:_fontSize];
    }
    self.loadingLabel.font = font;
    [self.spinner startAnimating];
}

- (void)layoutSubviews {
    [self.spinner startAnimating];
}

@end
