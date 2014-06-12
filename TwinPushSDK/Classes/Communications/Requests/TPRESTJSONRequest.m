//
//  TPRESTJSONRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 16/11/12.
//  Copyright (c) 2012 TwinCoders S.L. All rights reserved.
//

#import "TPRESTJSONRequest.h"
#import "TPRequestParam.h"

@interface TPRESTJSONRequest()

@property (strong, nonatomic) NSString* baseResource;

@end

static NSString* const kContentTypeJSON = @"application/json";

@implementation TPRESTJSONRequest

#pragma mark - Public methods

- (NSString *)contentType {
    return kContentTypeJSON;
}

- (NSString*)acceptsContentType {
    return kContentTypeJSON;
}

- (NSString *)createSegmentParamsString {
    NSMutableArray* params = [NSMutableArray arrayWithArray:self.segmentParams];
    return [self stringForSegmentParams:params];
}

- (NSDictionary*)dictionaryForResponseString:(NSString*)string {
    NSDictionary* dictionary = nil;
    if (string.length > 1) {
        NSError* error = nil;
        NSData* jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
        dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error != nil) {
            TCLog(@"Error parsing response string '%@': %@", string, error);
        }
    }

    return dictionary;
}

- (NSString*)createBodyContent {
    NSString* bodyContent = nil;
    if (self.contentParams.count > 0) {
        NSError* error = nil;
        NSDictionary* paramsDictionary = [self dictionaryForParams:self.contentParams];
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:paramsDictionary options:0 error:&error];
        if (error != nil) {
            TCLog(@"Error generating JSON request for dictionary '%@': %@", paramsDictionary, error);
        }
        bodyContent = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return bodyContent;
}

- (NSDictionary*)dictionaryForParams:(NSArray*)params {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:params.count];
    for (TPRequestParam* param in params) {
        if (!param.isArray) {
            if (!param.isComplex) {
                dictionary[param.key] = param.value;
            } else {
                dictionary[param.key] = [self dictionaryForParams:param.params];
            }
        } else {
            dictionary[param.key] = param.params;
        }
    }
    return dictionary;
}

@end
