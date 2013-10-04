//
//  TPRequestParam.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPRequestParam : NSObject

extern NSString* const kTPRequestParamEmptyValue;

@property (readonly, getter = isComplex) bool complex;
@property (readonly, getter = isArray) bool array;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSObject *value;
@property (nonatomic, strong) NSArray *params;

- (id) initWithKey:(NSString*)key andValue:(NSObject*)value;
- (id) initWithKey:(NSString*)key andArrayValue:(NSArray*)value;
- (id) initWithKey:(NSString*)key andParams:(NSArray*)params;

+ (TPRequestParam*) paramWithKey:(NSString*)key andValue:(NSObject*)value;
+ (TPRequestParam*) paramWithKey:(NSString*)key andArrayValue:(NSArray*)value;
+ (TPRequestParam*) paramWithKey:(NSString*)key andParams:(NSArray*)params;
+ (TPRequestParam*) paramWithKey:(NSString*)key andDictionary:(NSDictionary*)dictionary;

@end