//
//  TPBaseRequest.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import "TPBaseRequest.h"
#import "TPRequestLauncher.h"
#import "TPRequestParam.h"
#import "ASIFormDataRequest.h"
#import "ASIHTTPRequest.h"

// Error domain
static NSString* const kErrorDomain  = @"com.twincoders.TCBaseRequest";
static NSString* const kContentTypeHeaderKey = @"Content-Type";

@interface TPBaseRequest()

@property (nonatomic, strong) NSArray *endDelegateArray;
@property (nonatomic, strong, readwrite) NSString* requestId;

@end

@implementation TPBaseRequest

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        _canceled = NO;
        _endDelegateArray = [[NSMutableArray alloc] init];
        _contentParams = [[NSMutableArray alloc] init];
        _name =  NSStringFromClass([self class]);
        _requestId = [self createID];
    }
    return self;
}

- (NSString*)createID {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidStr;
}

#pragma mark - Public methods

- (void)notifyEndDelegates {
    for (id<TPRequestEndDelegate> endDelegate in _endDelegateArray) {
        [endDelegate requestDidFinish:self];
    }
}

- (void)start {
    self.canceled = NO;
    [_requestLauncher launchRequest:self];
}

- (void)cancel {
    [_requestLauncher cancelRequest:self];
    self.canceled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyEndDelegates];
    });
}

- (void)addRequestEndDelegate:(NSObject<TPRequestEndDelegate>*)endDelegate {
    if (![_endDelegateArray containsObject:endDelegate]) {
        [_endDelegateArray addObject:endDelegate];
    }
}

- (void)removeRequestEndDelegate:(NSObject<TPRequestEndDelegate>*)endDelegate {
    if ([_endDelegateArray containsObject:endDelegate]) {
        [_endDelegateArray removeObject:endDelegate];
    }
}

#pragma mark - ASIRequest Delegate

- (void)requestFinished:(ASIHTTPRequest *)request {
    // Perform operations in main thread and retaining self
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyEndDelegates];
        [self onRequestFinished:request];
    });
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    // Perform operations in main thread and retaining self
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isDummy) {
            // Notify delegates
            [self notifyEndDelegates];
            [self onRequestError:request];
        } else {
            [self requestFinished:request];
        }
    });
}

- (void)addParam:(TPRequestParam*)param {
    [_contentParams addObject:param];
}

- (void)addParam:(NSObject*)paramValue forKey:(NSString*)paramKey {
    NSObject* paramString = paramValue != nil ? paramValue : @"";
    [_contentParams addObject:[TPRequestParam paramWithKey:paramKey andValue:paramString]];
}

- (void)addNumberParam:(NSNumber*)paramValue forKey:(NSString*)paramKey {
    NSString* stringValue = nil;
    if (paramValue != nil) {
        stringValue = [NSString stringWithFormat:@"%i", paramValue.integerValue];
    }
    [self addParam:stringValue forKey:paramKey];
}

- (void)addDictionaryParam:(NSDictionary*)dictionary forKey:(NSString*)paramKey {
    [self addParam:[TPRequestParam paramWithKey:paramKey andDictionary:dictionary]];
}

+ (NSString*)errorDomain {
    return kErrorDomain;
}

#pragma mark - Request launch methods

- (ASIHTTPRequest*)createAsiRequest {
    NSURL* url = [NSURL URLWithString:self.url];
    TCLog(@"\nREQUEST: %@ (%@)", self.name, url);
    // Instance ASI Request with url
    ASIFormDataRequest* asiRequest = [[ASIFormDataRequest alloc] initWithURL: url];
    [asiRequest setStringEncoding:NSUTF8StringEncoding];
    asiRequest.requestMethod = [self stringFromMethod:self.requestMethod];
    // Set content type
    if (self.contentType != nil) {
        [asiRequest addRequestHeader:kContentTypeHeaderKey value:self.contentType];
    }

    return asiRequest;
}

- (NSString*)stringFromMethod:(TPRequestMethod)method {
    NSString* string;
    switch (method) {
        case kTPRequestMethodDELETE:
            string = @"DELETE";
            break;
        case kTPRequestMethodGET:
            string = @"GET";
            break;
        case kTPRequestMethodPOST:
            string = @"POST";
            break;
        case kTPRequestMethodPUT:
            string = @"PUT";
    }
    return string;
}

#pragma mark - Request interception methods

- (void)onRequestFinished:(ASIHTTPRequest *)request {
    
    if (![self isCanceled]) {
        // Use when fetching text data
        NSString *responseString = nil;
        if (self.encoding != 0) {
            responseString = [[NSString alloc] initWithData:request.responseData encoding:self.encoding];
        }
        if (responseString == nil) {
            responseString = [[NSString alloc] initWithData:request.responseData encoding:NSUTF8StringEncoding];
        }
        if (responseString == nil) {
            responseString = [[NSString alloc] initWithData:request.responseData encoding:NSASCIIStringEncoding];
        }
        TCLog(@"\nOUTPUT:\n%@", responseString);
        NSDictionary* responseDictionary = nil;
        if (responseString.length > 0) {
            responseDictionary = [self dictionaryForResponseString:responseString];
        }
        NSError* error = nil;
        NSDictionary* dictionary = nil;
        if (!self.isDummy) {
            dictionary = [self onProcessResponseDictionary:responseDictionary withError:&error];
        }
        
        if (error == nil) {
            self.onComplete(dictionary);
        } else {
            self.onError(error);
        }
    }
}

- (void)onRequestError:(ASIHTTPRequest *)request {
    TCLog(@"Request error: %@", request.error);
    _onError(request.error);
}

- (NSDictionary*)onProcessResponseDictionary:(NSDictionary*)response withError:(NSError**) error {
    return response;
}

- (NSDictionary*) dictionaryForResponseString:(NSString*)string {
    return nil;
}

- (NSString*) stringFromRequestParamsArray:(NSArray*)paramsArray {
    return nil;
}

@end