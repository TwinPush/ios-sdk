//
//  NSDictionary+DictionaryArrayForKey.m
//  SantanderChile
//
//  Created by Alex Gutiérrez on 11/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import "NSDictionary+ArrayForKey.h"

@implementation NSDictionary (ArrayForKey)

- (NSArray*)arrayForKey:(NSString*)itemKey {
    NSObject* response = [self objectForKey:itemKey];
    // If a single object is returned, include it into an array
    NSArray* dictionaryArray = nil;
    if (response == nil) {
        dictionaryArray = [NSArray array];
    } else if ([response isKindOfClass:[NSArray class]]) {
        dictionaryArray = (NSArray*) response;
    } else {
        dictionaryArray = [NSArray arrayWithObject:response];
    }
    return dictionaryArray;
}

@end
