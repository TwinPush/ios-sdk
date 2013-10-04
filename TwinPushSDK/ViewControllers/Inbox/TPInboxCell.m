//
//  TPInboxCell.m
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import "TPInboxCell.h"

static NSString* const kDateFormat = @"dd/MM/yyyy HH:mm";

@interface TPInboxCell()

@property (nonatomic, getter = isInStoryboard) BOOL inStoryboard;

@end

@implementation TPInboxCell

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
    self.notificationDateLabel = [[UILabel alloc]init];
    self.notificationDateLabel.textAlignment = UITextAlignmentLeft;
    self.notificationDateLabel.font = [UIFont systemFontOfSize:12];
    self.notificationDescriptionLabel = [[UILabel alloc]init];
    self.notificationDescriptionLabel.textAlignment = UITextAlignmentLeft;
    self.notificationDescriptionLabel.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:_notificationDateLabel];
    [self.contentView addSubview:_notificationDescriptionLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (![self isInStoryboard]) {
        [super layoutSubviews];
        CGRect contentRect = self.contentView.bounds;
        CGFloat boundsX = contentRect.origin.x;
        CGRect frame;
        frame = CGRectMake(boundsX+10 ,5, self.contentView.frame.size.width, 20);
        _notificationDateLabel.frame = frame;
        
        frame = CGRectMake(boundsX+10 ,25, self.contentView.frame.size.width, 20);
        _notificationDescriptionLabel.frame = frame;
    }
}

#pragma mark - Setters

- (void)setNotification:(TPNotification *)notification {
    _notification = notification;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateFormat];
    if ([notification.date isKindOfClass:[NSDate class]]) {
        self.notificationDateLabel.text = [dateFormatter stringFromDate:_notification.date];
    }
    if ([notification.message isKindOfClass:[NSString class]]) {
        self.notificationDescriptionLabel.text = notification.message;
    }
}

@end
