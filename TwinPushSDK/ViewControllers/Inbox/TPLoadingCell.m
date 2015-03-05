//
//  TPLoadingCell.m
//  TwinPushSDK
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPLoadingCell.h"

@interface TPLoadingCell()

@property (nonatomic, getter = isInStoryboard) BOOL inStoryboard;

@end

@implementation TPLoadingCell

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
    self.loadingLabel = [[UILabel alloc]init];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0
    self.loadingLabel.textAlignment = NSTextAlignmentLeft;
#else
    self.loadingLabel.textAlignment = UITextAlignmentLeft;
#endif
    self.loadingLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:_loadingLabel];
    [self.contentView addSubview:_spinner];
}

- (void)layoutSubviews {
    if (![self isInStoryboard]) {
        [super layoutSubviews];
        CGRect contentRect = self.contentView.bounds;
        CGFloat boundsX = contentRect.origin.x;
        CGRect frame;
        frame = CGRectMake(boundsX+10 ,5, self.contentView.frame.size.width, 20);
        _loadingLabel.frame = frame;
        
        frame = CGRectMake(boundsX+10 ,25, self.spinner.frame.size.width, self.spinner.frame.size.height);
        _spinner.frame = frame;
        [_spinner startAnimating];
    }
}

@end
