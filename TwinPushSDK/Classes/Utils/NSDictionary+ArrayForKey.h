//
//  NSDictionary+DictionaryArrayForKey.h
//  SantanderChile
//
//  Created by Alex Gutiérrez on 11/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ArrayForKey)

/** @brief Convenience method that returns an array of objects, even when the value it's not an array */
- (NSArray*) arrayForKey:(NSString*)itemKey;

@end
