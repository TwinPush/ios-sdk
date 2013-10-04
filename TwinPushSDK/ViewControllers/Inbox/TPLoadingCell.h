//
//  TPLoadingCell.h
//  TwinPushSDK
//
//  Created by Diego Prados on 06/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TPLoadingCell : UITableViewCell

#pragma mark - IBOutlets
@property (strong, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
