//
//  TPInboxNotification.m
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 19/7/17.
//  Copyright © 2017 TwinCoders. All rights reserved.
//

#import "TPInboxNotification.h"

static NSString* const kDateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

@implementation TPInboxNotification
- (BOOL)isOpened {
    return self.openDate != nil;
}

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* df = nil;
    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:kDateFormat];
    }
    return df;
}

- (void)populateFromDictionary:(NSDictionary *)dict {
    id openAt = dict[@"open_at"];
    if ([openAt isKindOfClass:[NSString class]]) {
        self.openDate = [[TPInboxNotification dateFormatter] dateFromString:openAt];
    }
    [super populateFromDictionary:dict[@"notification"]];
}

+ (TPInboxNotification*)inboxNotificationFromDictionary:(NSDictionary*)dict {
    TPInboxNotification* notification = [[TPInboxNotification alloc] init];
    [notification populateFromDictionary:dict];
    return notification;
}

@end
