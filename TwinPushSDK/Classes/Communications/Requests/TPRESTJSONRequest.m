//
//  TPRESTJSONRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 16/11/12.
//  Copyright (c) 2012 TwinCoders S.L. All rights reserved.
//

#import "TPRESTJSONRequest.h"
#import "TPRequestParam.h"
#import "JSONKit.h"

@interface TPRESTJSONRequest()

@property (strong, nonatomic) NSString* baseResource;

@end

@implementation TPRESTJSONRequest

#pragma mark - Public methods

- (NSString *)createSegmentParamsString {
    NSMutableArray* params = [NSMutableArray arrayWithArray:self.segmentParams];
    return [self stringForSegmentParams:params];
}

- (NSDictionary*)dictionaryForResponseString:(NSString*)string {
    NSDictionary* dictionary = [string objectFromJSONString];
    return dictionary;
}

//- (NSDictionary *)dictionaryForResponseString:(NSString *)string {
//    NSDictionary* dictionary = [super dictionaryForResponseString:string];
//    // If dictionary contains errors, call onError
//    return dictionary;
//}

- (NSString*)createBodyContent {
    NSString* bodyContent = nil;
    if (self.contentParams.count > 0) {
        NSDictionary* paramsDictionary = [self dictionaryForParams:self.contentParams];
        bodyContent = [paramsDictionary JSONString];
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
