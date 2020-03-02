//
//  TPBaseRequest.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TPBaseRequest;
@class TPRequestLauncher;
@class TPRequestParam;

typedef enum {
    kTPRequestMethodGET,
    kTPRequestMethodPOST,
    kTPRequestMethodPUT,
    kTPRequestMethodDELETE,
} TPRequestMethod;


/** @brief Protocol that must be implemented by objects that want to be notified when a Request ends, regardless of its result */
@protocol TPRequestEndDelegate <NSObject>

/** @brief Notifies that a request did end, regardless of its result */
-(void) requestDidFinish:(TPBaseRequest*)aRequest;

@end

/** @brief Block that will be given for objects that will handle request response, in order to handle request errors */
typedef void(^TPRequestErrorBlock)(NSError* error);

/**
 @brief Method that is called when the request receives a response from server
 @param response Diccionary containing request response
 */
typedef void(^TPRequestCompleteBlock)(NSDictionary* response);

/**
 @brief Block to be called when a request is completed successfuly without response data */
typedef void(^TPRequestSuccessBlock)();

extern NSString* const kStringErrorCodeKey;

/** @brief Abstract petition that defines common properties for all the application requests */
@interface TPBaseRequest : NSObject {
    /** Array of end delegates that will be notified when the request finishes */
    NSMutableArray* _endDelegateArray;
}

/** @brief Unique identifier for Request */
@property (nonatomic, readonly) NSString* requestId;

/** @brief Name of the request */
@property (nonatomic, strong) NSString* name;

/** @brief URL of the request */
@property (nonatomic, readonly) NSString* url;

/** @brief Block that will be executed if the request returns an error */
@property (nonatomic, copy) TPRequestErrorBlock onError;

/** @brief Block that will be executed when request successfuly completes */
@property (nonatomic, copy) TPRequestCompleteBlock onComplete;

/** @brief Parameters of the request */
@property (nonatomic, strong) NSMutableArray* contentParams;

/** @brief Property that indicates whether the request has been canceled */
@property (getter = isCanceled) bool canceled;

/** @brief Reference to Request Launcher */
@property (nonatomic, assign) TPRequestLauncher *requestLauncher;

@property (nonatomic, getter = isDummy) BOOL dummy;

@property (nonatomic, assign) TPRequestMethod requestMethod;

@property (nonatomic, assign) NSStringEncoding encoding;

@property (nonatomic, strong) NSString* contentType;

@property (nonatomic, strong) NSString* acceptsContentType;

/** @brief Starts the asynchronous execution of the request */
-(void)start;

/** @brief Cancels the request if it has not yet received a response */
-(void)cancel;

/** @brief Add a delegate that receives notification that the request is completed, regardless of the outcome of the same */
-(void)addRequestEndDelegate:(NSObject<TPRequestEndDelegate>*)endDelegate;

/** @brief Removes a request end delegate */
-(void)removeRequestEndDelegate:(NSObject<TPRequestEndDelegate>*)endDelegate;

#pragma mark - Parameters

/** @brief Add a custom parameter to the request */
-(void)addParam:(TPRequestParam*)param;

/** @brief Add a custom parameter to the request */
-(void)addDictionaryParam:(NSDictionary*)param forKey:(NSString*)paramKey;

/** @brief Method that adds a param with given properties to content params */
-(void)addParam:(NSObject*)paramValue forKey:(NSString*)paramKey;

/** @brief Method that adds a numeric param to content params */
-(void)addNumberParam:(NSNumber*)paramValue forKey:(NSString*)paramKey;

/** @brief Return a String with serialized params array */
-(NSString*) stringFromRequestParamsArray:(NSArray*)paramsArray;

/** @brief Obtain the error domain used for custom errors (subclasses must override this method) */
+ (NSString*)errorDomain;

#pragma mark - Request launch methods

/** @brief Method that must be overriden by subclasses to properly create the request object */
- (NSMutableURLRequest*)createRequest;

#pragma mark - Request interception methods

/** @brief Method that can be overriden by subclass to perform any additional processing
    when the request is started */
- (void)onRequestStarted:(NSURLRequest*)request;

/** @brief Method that can be overriden by subclass to process result from request. Default behavior is call onProcessResponseDictionary method with nil argument */
- (void)onRequestFinished:(NSURLResponse*)response data:(NSData*)data;

/** @brief Method that can be overriden by subclass to process error from request. Default behavior is call onError with obtained error from request */
- (void)onRequestError:(NSURLResponse*)response error:(NSError*)error;

/** @brief Method that can be overriden by subclass to create a Dictionary from the response String. Default behavior returns nil */
- (NSDictionary*) dictionaryForResponseString:(NSString*)string;

/** @brief Method that can be overriden by subclass to analyze if it's a valid response or an error */
- (NSDictionary*)onProcessResponseDictionary:(NSDictionary*)response withError:(NSError**) error;

@end
