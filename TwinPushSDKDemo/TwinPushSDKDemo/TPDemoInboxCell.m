//
//  TPTDemoInboxCell.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPDemoInboxCell.h"

@implementation TPDemoInboxCell

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


- (UIFont*)boldFont {
    static UIFont* font = nil;
    if (font == nil) {
        font = [UIFont fontWithName:@"MuseoSans-700" size:13];
    }
    return font;
}

- (UIFont*)normalFont {
    static UIFont* font = nil;
    if (font == nil) {
        font = [UIFont fontWithName:@"MuseoSans-300" size:13];
    }
    return font;
}

- (void)setNotification:(TPNotification *)notification {
    [super setNotification:notification];
    
    if ([notification isKindOfClass:[TPInboxNotification class]]) {
        TPInboxNotification* inboxNotification = (TPInboxNotification*)notification;
        self.notificationDescriptionLabel.font = inboxNotification.isOpened ? [self normalFont] : [self boldFont];
        self.notificationDateLabel.font = inboxNotification.isOpened ? [self normalFont] : [self boldFont];
    }
}

@end
