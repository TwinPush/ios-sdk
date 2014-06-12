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

// Error domain
static NSString* const kErrorDomain  = @"com.twincoders.TCBaseRequest";
static NSString* const kContentTypeHeaderKey = @"Content-Type";
static NSString* const kAcceptContentTypeHeaderKey = @"Accept";

@interface TPBaseRequest()

@property (nonatomic, strong) NSArray *endDelegateArray;
@property (nonatomic, strong, readwrite) NSString* requestId;
@property (nonatomic, strong) NSMutableData* responseData;

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
    self.responseData = [[NSMutableData alloc] init];
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

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Perform operations in main thread and retaining self
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isDummy) {
            // Notify delegates
            [self notifyEndDelegates];
            [self onRequestError:connection error:error];
        } else {
            [self connectionDidFinishLoading:connection];
        }
    });
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Perform operations in main thread and retaining self
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyEndDelegates];
        [self onRequestFinished:connection];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}


#pragma mark - Param methods
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
        stringValue = [NSString stringWithFormat:@"%li", (long)paramValue.integerValue];
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

- (NSMutableURLRequest*)createRequest {
    NSURL* url = [NSURL URLWithString:self.url];
    TCLog(@"\nREQUEST: %@ (%@)", self.name, url);
    
    // Instance Request with url
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = [self stringFromMethod:self.requestMethod];
    
    // Set content type
    if (self.contentType != nil) {
        [request addValue:self.contentType forHTTPHeaderField:kContentTypeHeaderKey];
    }
    if (self.acceptsContentType != nil) {
        [request addValue:self.acceptsContentType forHTTPHeaderField:kAcceptContentTypeHeaderKey];
    }
    
    return request;
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

- (void)onRequestStarted:(NSURLConnection*)connection {
    // By default no additional operation is required
}

- (void)onRequestFinished:(NSURLConnection*)connection {
    if (![self isCanceled]) {
        // Use when fetching text data
        NSString *responseString = nil;
        if (self.encoding != 0) {
            responseString = [[NSString alloc] initWithData:self.responseData encoding:self.encoding];
        }
        if (responseString == nil) {
            responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        }
        if (responseString == nil) {
            responseString = [[NSString alloc] initWithData:self.responseData encoding:NSASCIIStringEncoding];
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

- (void)onRequestError:(NSURLConnection*)connection error:(NSError*)error {
    TCLog(@"Request error: %@", error);
    _onError(error);
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