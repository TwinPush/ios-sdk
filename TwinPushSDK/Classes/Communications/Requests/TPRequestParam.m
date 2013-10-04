//
//  TPRequestParam.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import "TPRequestParam.h"

@implementation TPRequestParam

NSString* const kTPRequestParamEmptyValue = @"";

#pragma mark - Init

- (id)initWithKey:(NSString*)key andValue:(NSObject*)value {
    self = [super init];
    if (self) {
        self.key = key;
        if (value == nil) {
            self.value = kTPRequestParamEmptyValue;
        } else {
            self.value = value;
        }
        _complex = NO;
    }
    return self;
}

- (id)initWithKey:(NSString*)key andParams:(NSArray*)params {
    self = [super init];
    if (self) {
        self.key = key;
        self.params = params;
        _complex = YES;
    }
    return self;
}

- (id)initWithKey:(NSString*)key andArrayValue:(NSArray*)values {
    self = [super init];
    if (self) {
        self.key = key;
        self.params = values;
        _array = YES;
    }
    return self;
}

#pragma mark - Public methods

+ (TPRequestParam*)paramWithKey:(NSString*)key andValue:(NSObject*)value {
    return [[TPRequestParam alloc] initWithKey:key andValue:value];
}

+ (TPRequestParam*)paramWithKey:(NSString*)key andParams:(NSArray*)params {
    return [[TPRequestParam alloc] initWithKey:key andParams:params];
}
+ (TPRequestParam*)paramWithKey:(NSString*)key andArrayValue:(NSArray*)value {
    return [[TPRequestParam alloc] initWithKey:key andArrayValue:value];
}

+ (TPRequestParam*)paramWithKey:(NSString*)key andDictionary:(NSDictionary*)dictionary {
    NSMutableArray* innerParams = [[NSMutableArray alloc] init];
    // Iterate dictionary items
    for (NSString* dictKey in dictionary.allKeys) {
        TPRequestParam* innerParam = nil;
        // Ckeck value
        id value = [dictionary objectForKey:dictKey];
        if (value == nil) {
            innerParam = [TPRequestParam paramWithKey:dictKey andValue:kTPRequestParamEmptyValue];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            innerParam = [TPRequestParam paramWithKey:dictKey andDictionary:value];
        } else {
            innerParam = [TPRequestParam paramWithKey:dictKey andValue:value];
        }
        
        // Include param in params array
        if (innerParam != nil) {
            [innerParams addObject:innerParam];
        }
    }
    TPRequestParam* param = [TPRequestParam paramWithKey:key andParams:innerParams];
    return param;
}

- (NSString*)description {
    if (_complex) {
        NSString* paramsDesc = [NSString string];
        for (TPRequestParam* param in _params) {
            paramsDesc = [paramsDesc stringByAppendingString:param.description];
        }
        return [NSString stringWithFormat:@"%@ = {%@}; ", _key, paramsDesc];
    } else {
        return [NSString stringWithFormat:@"%@ = %@; ", _key, _value];
    }
}

@end