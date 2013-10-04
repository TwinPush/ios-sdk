//
//  Notification.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import <Foundation/Foundation.h>

@interface TPNotification : NSObject

@property (nonatomic, copy) NSString* notificationId;
@property (nonatomic, copy) NSString* message;
@property (nonatomic, copy) NSString* title; // Android-only, but can be used from iOS
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, copy) NSString* sound;
@property (nonatomic, copy) NSString* contentUrl;
@property (nonatomic, strong) NSArray* tags;
@property (nonatomic, strong) NSDictionary* customProperties;

@property (nonatomic, readonly, getter = isRich) BOOL rich;
@property (nonatomic, readonly, getter = isComplete) BOOL complete; // NO if some information is missing

+ (TPNotification*)notificationFromDictionary:(NSDictionary*)dict;

@end
