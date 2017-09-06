//
//  Notification.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import <Foundation/Foundation.h>
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@interface TPNotification : NSObject

@property (nonatomic, copy) NSString* notificationId;
@property (nonatomic, copy) NSString* message;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* subtitle;
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, copy) NSString* sound;
@property (nonatomic, copy) NSString* contentUrl;
@property (nonatomic, strong) NSArray* tags;
@property (nonatomic, strong) NSDictionary* customProperties;
@property (nonatomic, copy) NSString* category;

@property (nonatomic, readonly, getter = isRich) BOOL rich;
@property (nonatomic, readonly, getter = isComplete) BOOL complete; // NO if some information is missing

+ (TPNotification*)notificationFromDictionary:(NSDictionary*)dict;
+ (TPNotification*)notificationFromApnsDictionary:(NSDictionary*)dict;
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
+ (TPNotification*)notificationFromUserNotification:(UNNotification*)userNotification;
#endif

- (void)populateFromDictionary:(NSDictionary*)dict;

@end
