//
//  TPDevice.h
//  TwinPushSDK
//
//  Created by Diego Prados on 24/01/13.
//
//

#import <Foundation/Foundation.h>

@interface TPDevice : NSObject

@property (nonatomic, copy) NSString* deviceId;
@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSString* deviceAlias;
@property (nonatomic, strong) NSDate* creationDate;
@property (nonatomic, strong) NSDate* updateDate;
@property (nonatomic, strong) NSDate* lastRegistrationDate;
@property (nonatomic, copy) NSString* appId;

@end
