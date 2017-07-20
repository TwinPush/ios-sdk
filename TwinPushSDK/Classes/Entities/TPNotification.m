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
static NSString* const kSubtitleKey = @"subtitle";
static NSString* const kSoundKey = @"sound";
static NSString* const kSentDateKey = @"last_sent_at";
static NSString* const kRichUrlKey = @"tp_rich_url";
static NSString* const kCustomPropertiesKey = @"custom_properties";
static NSString* const kCategoryKey = @"category";
static NSString* const kTagsKey = @"tags";
static NSString* const kApsKey = @"aps";
static NSString* const kDateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

@implementation TPNotification

- (BOOL)isRich {
    return self.contentUrl.length > 0;
}

- (void)populateFromDictionary:(NSDictionary*)dict {
    self.notificationId = dict[kNotificationsIdKey];
    self.message = dict[kAlertKey];
    self.sound = dict[kSoundKey];
    
    self.title = dict[kTitleKey];
    self.subtitle = dict[kSubtitleKey];
    if (dict[kRichUrlKey] == [NSNull null]) {
        self.contentUrl = @"";
    } else {
        self.contentUrl = dict[kRichUrlKey];
    }
    self.category = dict[kCategoryKey];
    self.date = [[TPNotification dateFormatter] dateFromString:dict[kSentDateKey]];
    self.customProperties = dict[kCustomPropertiesKey];
    self.tags = dict[kTagsKey];
    self.complete = YES;
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
    [notification populateFromDictionary:dict];
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
        notification.title = alert[kTitleKey];
        notification.subtitle = alert[kSubtitleKey];
    }
    notification.sound = dict[kApsKey][kSoundKey];
    
    if (dict[kRichUrlKey] == [NSNull null]) {
        notification.contentUrl = @"";
    } else {
        notification.contentUrl = dict[kRichUrlKey];
    }
    notification.category = dict[kCategoryKey];
    
    NSMutableDictionary* customProperties = [NSMutableDictionary dictionaryWithDictionary:dict];
    [customProperties removeObjectForKey:kApsKey];
    [customProperties removeObjectForKey:kApsNotificationsIdKey];
    [customProperties removeObjectForKey:kRichUrlKey];
    notification.customProperties = [NSDictionary dictionaryWithDictionary:customProperties];
    notification.complete = NO;
    
    return notification;
}

#ifdef __IPHONE_10_0
+ (TPNotification*)notificationFromUserNotification:(UNNotification*)userNotification {
    TPNotification* notification = [TPNotification notificationFromApnsDictionary: userNotification.request.content.userInfo];
    notification.date = notification.date;
    return notification;
}
#endif



@end
