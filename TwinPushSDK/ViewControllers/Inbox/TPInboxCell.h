//
//  TPInboxCell.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import <UIKit/UIKit.h>
#import "TPNotification.h"

@interface TPInboxCell : UITableViewCell

#pragma mark - Properties
@property (strong, nonatomic) TPNotification* notification;

#pragma mark - IBOutlets
@property (strong, nonatomic) IBOutlet UILabel *notificationDateLabel;
@property (strong, nonatomic) IBOutlet UILabel *notificationDescriptionLabel;

@end
