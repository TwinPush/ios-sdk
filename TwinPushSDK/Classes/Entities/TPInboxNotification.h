//
//  TPInboxNotification.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 19/7/17.
//  Copyright © 2017 TwinCoders. All rights reserved.
//

#import "TPNotification.h"

@interface TPInboxNotification : TPNotification
@property (nonatomic, strong) NSDate* openDate;
- (BOOL)isOpened;

+ (TPInboxNotification*)inboxNotificationFromDictionary:(NSDictionary*)dict;
@end
