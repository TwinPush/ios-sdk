//
//  TPNoResultsCell.m
//  TwinPushSDK
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPNoResultsCell.h"

@interface TPNoResultsCell()

@property (nonatomic, getter = isInStoryboard) BOOL inStoryboard;

@end

@implementation TPNoResultsCell

#pragma mark - Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (( self = [super initWithStyle:style reuseIdentifier:reuseIdentifier] )) {
        [self initializeCell];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (( self = [super initWithFrame:frame] )) {
        [self initializeCell];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.inStoryboard = YES;
}

- (void)initializeCell {
    // Initialization code
    self.noResultsLabel = [[UILabel alloc]init];
    self.noResultsLabel.textAlignment = NSTextAlignmentLeft;
    self.noResultsLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:_noResultsLabel];
}

- (void)layoutSubviews {
    if (![self isInStoryboard]) {
        [super layoutSubviews];
        CGRect contentRect = self.contentView.bounds;
        CGFloat boundsX = contentRect.origin.x;
        CGRect frame;
        frame = CGRectMake(boundsX+10 ,5, self.contentView.frame.size.width, 20);
        _noResultsLabel.frame = frame;
    }
}

@end
