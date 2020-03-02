//
//  TPRESTRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 16/11/12.
//  Copyright (c) 2012 TwinCoders S.L. All rights reserved.
//

#import "TPRESTRequest.h"
#import "TPRequestParam.h"

// Segment Params
NSString* const kTPRESTSegmentParamsSeparator = @"/";
// Query String Params
static NSString* const kQueryStringParamFormat = @"%@=%@";
static NSString* const kQueryStringFormat = @"?%@";
static NSString* const kQueryStringArrayKeyFormat = @"%@[]";
static NSString* const kQueryStringSeparator = @"&";
static NSString* const kContentType = @"application/x-www-form-urlencoded";

@implementation TPRESTRequest

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        self.segmentParams = [NSMutableArray array];
        self.requestMethod = kTPRequestMethodGET;
        self.contentType = kContentType;
    }
    return self;
}

#pragma mark - Public methods

- (void)addSegmentParam:(NSString*)segmentParam {
    if (segmentParam.length > 0) {
        [self.segmentParams addObject:segmentParam];
    }
}

- (NSString*)url {
    NSString* paramsString = [NSString string];
    if (self.resource != nil) {
        paramsString = [paramsString stringByAppendingPathComponent:self.resource];
    }
    if (self.segmentParams.count > 0) {
        paramsString = [paramsString stringByAppendingPathComponent:[self createSegmentParamsString]];
    }
    if (self.requestMethod == kTPRequestMethodGET && self.contentParams.count > 0) {
        paramsString = [paramsString stringByAppendingString:[self createParametersQueryString]];
    }
    return [self.baseServerUrl stringByAppendingString:paramsString];
}

- (NSString*)createSegmentParamsString {
    return [self stringForSegmentParams:self.segmentParams];
}

- (NSString*)stringForSegmentParams:(NSArray*)params {
    return [params componentsJoinedByString:kTPRESTSegmentParamsSeparator];
}

- (NSString*)createParametersQueryString {
    NSString* queryString = [NSString stringWithFormat:kQueryStringFormat, [self queryStringFromRequestParamsArray:self.contentParams]];
    return queryString;
}

- (NSString*)queryStringForParameter:(TPRequestParam*)requestParam {
    if (requestParam.array) {
        NSString* key = [NSString stringWithFormat:kQueryStringArrayKeyFormat, requestParam.key];
        NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:requestParam.params.count];
        for (NSString* value in requestParam.params) {
            NSString* queryStr = [self queryStringForKey:key value:value];
            [array addObject:queryStr];
        }
        return [array componentsJoinedByString:kQueryStringSeparator];
    }
    return [self queryStringForKey:requestParam.key value:(NSString*)requestParam.value];
}

- (NSString*)queryStringForKey:(NSString*)key value:(NSString*)value {
    NSString* encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    return [NSString stringWithFormat:kQueryStringParamFormat, key, encodedValue];
}

- (NSString*)queryStringFromRequestParamsArray:(NSArray*)paramsArray {
    NSMutableArray* stringParams = [NSMutableArray arrayWithCapacity:self.contentParams.count];
    for (TPRequestParam* param in self.contentParams) {
        NSString* paramString = [self queryStringForParameter:param];
        [stringParams addObject:paramString];
    }
    NSString* queryString = [stringParams componentsJoinedByString:kQueryStringSeparator];
    return queryString;
}

- (NSString*)stringFromRequestParamsArray:(NSArray*)paramsArray {
    return [self queryStringFromRequestParamsArray:paramsArray];
}

- (NSString *)name {
    return self.resource;
}

- (NSMutableURLRequest*)createRequest {
    NSMutableURLRequest* request = [super createRequest];
    
    switch (self.requestMethod) {
            // For POST and PUT requests, include body content
        case kTPRequestMethodPOST:
        case kTPRequestMethodPUT: {
            NSString* bodyContent = [self createBodyContent];
            TCLog(@"\nINPUT:\n%@", bodyContent);
            if (bodyContent != nil) {
                request.HTTPBody = [bodyContent dataUsingEncoding:NSUTF8StringEncoding];
                [request addValue:@(request.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
            }
            break;
        }
        default:
            break;
    }
    return request;
}

- (NSString*)createBodyContent {
    NSString* bodyContent = nil;
    if (self.requestMethod == kTPRequestMethodPOST) {
        bodyContent = [self stringFromRequestParamsArray:self.contentParams];
    }
    return bodyContent;
}

@end
