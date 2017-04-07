//
//  Notification.m
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import "TPNotification.h"

@interface TPNotification ()
@property (nonatomic, readwrite, getter=isComplete) BOOL complete;
@end

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

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* df = nil;
    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:kDateFormat];
    }
    return df;
}

+ (TPNotification*)notificationFromDictionary:(NSDictionary*)dict {
    TPNotification* notification = [[TPNotification alloc] init];
    notification.notificationId = dict[kNotificationsIdKey];
    notification.message = dict[kAlertKey];
    notification.sound = dict[kSoundKey];
    
    notification.title = dict[kTitleKey];
    if (dict[kRichUrlKey] == [NSNull null]) {
        notification.contentUrl = @"";
    } else {
        notification.contentUrl = dict[kRichUrlKey];
    }
    notification.date = [[self dateFormatter] dateFromString:dict[kSentDateKey]];
    notification.customProperties = dict[kCustomPropertiesKey];
    notification.tags = dict[kTagsKey];
    notification.complete = YES;
    
    return notification;
}

+ (TPNotification*)notificationFromApnsDictionary:(NSDictionary*)dict {
    TPNotification* notification = [[TPNotification alloc] init];
    notification.notificationId = dict[kApsNotificationsIdKey];
    id alert = dict[kApsKey][kAlertKey];
    if ([alert isKindOfClass:[NSString class]]) {
        notification.message = alert;
    }
    else if ([alert isKindOfClass:[NSDictionary class]]) {
        notification.message = alert[@"body"];
        notification.title = alert[@"title"];
    }
    notification.sound = dict[kApsKey][kSoundKey];
    
    if (dict[kRichUrlKey] == [NSNull null]) {
        notification.contentUrl = @"";
    } else {
        notification.contentUrl = dict[kRichUrlKey];
    }
    
    NSMutableDictionary* customProperties = [NSMutableDictionary dictionaryWithDictionary:dict];
    [customProperties removeObjectForKey:kApsKey];
    [customProperties removeObjectForKey:kApsNotificationsIdKey];
    [customProperties removeObjectForKey:kRichUrlKey];
    notification.customProperties = [NSDictionary dictionaryWithDictionary:customProperties];
    notification.complete = NO;
    
    return notification;
}



@end
