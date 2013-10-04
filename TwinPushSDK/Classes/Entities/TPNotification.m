//
//  Notification.m
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import "TPNotification.h"

static NSString* const kObjectsWrapper = @"objects";
static NSString* const kReferencesWrapper = @"references";
static NSString* const kNotificationsIdKey = @"id";
static NSString* const kApsNotificationsIdKey = @"tp_id";
static NSString* const kAlertKey = @"alert";
static NSString* const kTitleKey = @"title";
static NSString* const kSoundKey = @"sound";
static NSString* const kSentDateKey = @"last_sent_at";
static NSString* const kRichUrlKey = @"tp_rich_url";
static NSString* const kCustomPropertiesKey = @"custom_properties";
static NSString* const kTagsKey = @"tags";
static NSString* const kApsKey = @"aps";
static NSString* const kDateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

@implementation TPNotification

- (BOOL)isRich {
    return self.contentUrl.length > 0;
}

- (BOOL)isComplete {
    BOOL complete = _message != nil;
    complete &= _notificationId != nil;
    complete &= _date != nil;
    complete &= _tags != nil;
    complete &= _customProperties != nil;
    
    return complete;
}

+ (TPNotification*)notificationFromDictionary:(NSDictionary*)dict {
    static NSDateFormatter* df = nil;
    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:kDateFormat];
    }
    
    TPNotification* notification = [[TPNotification alloc] init];
    if ([dict[kApsKey] isKindOfClass:[NSDictionary class]]) {
        // Support APNS dict
        notification.notificationId = dict[kApsNotificationsIdKey];
        notification.message = dict[kApsKey][kAlertKey];
        notification.sound = dict[kApsKey][kSoundKey];
    }
    else {
        notification.notificationId = dict[kNotificationsIdKey];
        notification.message = dict[kAlertKey];
        notification.sound = dict[kSoundKey];
    }
    
    notification.title = dict[kTitleKey];
    if (dict[kRichUrlKey] == [NSNull null]) {
        notification.contentUrl = @"";
    } else {
        notification.contentUrl = dict[kRichUrlKey];
    }
    notification.date = [df dateFromString:dict[kSentDateKey]];
    notification.customProperties = dict[kCustomPropertiesKey];
    notification.tags = dict[kTagsKey];
    
    return notification;
}



@end
