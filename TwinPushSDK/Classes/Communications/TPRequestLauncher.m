//
//  TCRequestLauncher.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import "TPRequestLauncher.h"
#import "TPRequestParam.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@interface TPRequestLauncher()

// Array of active requests
@property (nonatomic, strong) NSMutableDictionary *activeRequests;
@property NSInteger requestTimeOutSeconds;

@end

@implementation TPRequestLauncher

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        // Init active requests array
        _activeRequests = [[NSMutableDictionary alloc] init];
        _allowUnsafeCertificate = NO;
        _requestTimeOutSeconds = 30;
    }
    return self;
}

#pragma mark - Public methods

/** @brief Launches the selected request */
- (void)launchRequest:(TPBaseRequest*)request {
    // Check if a equal request is not already launched
    if ([_activeRequests objectForKey:request.requestId] == nil) {
        [request addRequestEndDelegate:self];
        ASIHTTPRequest* asiRequest = [request createAsiRequest];
        // Set request timeout
        [asiRequest setTimeOutSeconds:_requestTimeOutSeconds];
        // Allows self-signed certificate
        if (self.allowUnsafeCertificate) {
            [asiRequest setValidatesSecureCertificate:NO];
        }
        // Avoid redirect
        asiRequest.shouldRedirect = NO;
        asiRequest.delegate = request;
        // Display network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        // Add request to active request array
        [_activeRequests setObject:asiRequest forKey:request.requestId];
        if (!request.isDummy) {
            // Start request
            [asiRequest startAsynchronous];
        } else {
            if ([request respondsToSelector:@selector(requestFinished:)]) {
                NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
                    [(id<ASIHTTPRequestDelegate>)request requestFinished:asiRequest];
                }];
                
                [[NSOperationQueue mainQueue] performSelector:@selector(addOperation:) withObject:operation afterDelay:1];
            }
        }
    } else {
        TCLog(@"Equal request already launched. Ignoring...");
    }
}

/** @brief Cancel the selected request */
- (void)cancelRequest:(TPBaseRequest*)request {
    TCLog(@"Cancelling request...");
    ASIHTTPRequest* asiRequest = [_activeRequests objectForKey:request.requestId];
    if (asiRequest != nil) {
        [asiRequest clearDelegatesAndCancel];
        [_activeRequests removeObjectForKey:request.requestId];
    }
}

#pragma mark - RequestEndDelegate
- (void)requestDidFinish:(TPBaseRequest *)request {
    ASIHTTPRequest* asiRequest = [_activeRequests objectForKey:request.requestId];
    if (asiRequest != nil) {
        [asiRequest clearDelegatesAndCancel];
        [_activeRequests removeObjectForKey:request.requestId];
    }
    
    // Hide network activity indicator when there are no more active requests
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_activeRequests.count > 0];
}

@end