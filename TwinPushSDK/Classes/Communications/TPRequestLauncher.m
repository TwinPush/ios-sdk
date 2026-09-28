//
//  TCRequestLauncher.m
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPRequestLauncher.h"
#import "TPRequestParam.h"
#import "TPRemotePinning.h"

@interface TPBaseRequest (RemoteTransport)
- (void)finishRemoteData:(NSData *)data error:(NSError *)error;
@end

@interface TPRequestLauncher()

@property (nonatomic, strong) TPRemotePinning *remotePinning;

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
        request.allowUntrustedCertificates = self.allowUnsafeCertificate;
        
        NSURLRequest* urlRequest = [request createRequest];
        id urlConnection;
        if (self.remotePinning) {
            urlConnection = [self.remotePinning send:urlRequest completion:^(NSData *data, NSURLResponse *response, NSError *error) {
                [request finishRemoteData:data error:error];
            }];
        } else {
            urlConnection = [NSURLConnection connectionWithRequest:urlRequest delegate:request];
        }
        
        // Display network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        // Add request to active request array
        [_activeRequests setObject:urlConnection forKey:request.requestId];

    } else {
        TCLog(@"Equal request already launched. Ignoring...");
    }
}

/** @brief Cancel the selected request */
- (void)cancelRequest:(TPBaseRequest*)request {
    TCLog(@"Cancelling request...");
    id urlConnection = [_activeRequests objectForKey:request.requestId];
    if (urlConnection != nil) {
        [urlConnection cancel];
        [_activeRequests removeObjectForKey:request.requestId];
    }
}

#pragma mark - RequestEndDelegate
- (void)requestDidFinish:(TPBaseRequest *)request {
    id urlConnection = [_activeRequests objectForKey:request.requestId];
    if (urlConnection != nil) {
        [urlConnection cancel];
        [_activeRequests removeObjectForKey:request.requestId];
    }
    
    // Hide network activity indicator when there are no more active requests
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_activeRequests.count > 0];
}

@end
