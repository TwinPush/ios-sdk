//
//  TPTDemoInboxCell.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPDemoInboxCell.h"

@implementation TPDemoInboxCell

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
    self.notificationDateLabel.font = font;
    self.notificationDescriptionLabel.font = font;
}

#pragma mark - Setters

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self refreshStatusAnimated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self refreshStatusAnimated:animated];
}

- (void)refreshStatusAnimated:(BOOL)animated {
    BOOL highlighted = self.highlighted || (self.highlightOnSelected && self.selected);
    for (id element in self.highlightElements) {
        if ([element respondsToSelector:@selector(setHighlighted:animated:)]) {
            [element setHighlighted:highlighted animated:animated];
        }
        else if ([element respondsToSelector:@selector(setHighlighted:)]) {
            [element setHighlighted:highlighted];
        }
    }
}

- (BOOL)highlightOnSelected {
    return YES;
}

@end
