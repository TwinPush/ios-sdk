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

@interface TPRequestLauncher() <NSURLSessionDelegate>

// Array of active requests
@property (nonatomic, strong) NSMutableDictionary *activeRequests;
@property NSInteger requestTimeOutSeconds;
@property (nonatomic, strong) NSURLSession* session;

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
        
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
        //self.session = [NSURLSession sharedSession];
    }
    return self;
}

#pragma mark - Public methods

/** @brief Launches the selected request */
- (void)launchRequest:(TPBaseRequest*)request {
    // Check if a equal request is not already launched
    if ([_activeRequests objectForKey:request.requestId] == nil) {
        [request addRequestEndDelegate:self];
        
        NSURLRequest* urlRequest = [request createRequest];
        NSURLSessionDataTask* dataTask = [self.session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse* response, NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != nil) {
                    [request onRequestError:response error:error];
                }
                else {
                    [request onRequestFinished:response data:data];
                }
            });
        }];
        [dataTask resume];
        
        // Display network activity indicator
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        // Add request to active request array
        [_activeRequests setObject:dataTask forKey:request.requestId];

    } else {
        TCLog(@"Equal request already launched. Ignoring...");
    }
}

/** @brief Cancel the selected request */
- (void)cancelRequest:(TPBaseRequest*)request {
    TCLog(@"Cancelling request...");
    NSURLSessionDataTask* dataTask = [_activeRequests objectForKey:request.requestId];
    if (dataTask != nil) {
        //[dataTask cancel];
        [_activeRequests removeObjectForKey:request.requestId];
    }
}

#pragma mark - RequestEndDelegate
- (void)requestDidFinish:(TPBaseRequest *)request {
    NSURLSessionDataTask* dataTask = [_activeRequests objectForKey:request.requestId];
    if (dataTask != nil) {
        [_activeRequests removeObjectForKey:request.requestId];
    }
    
    // Hide network activity indicator when there are no more active requests
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_activeRequests.count > 0];
}

#pragma mark - NSURLSessionDelegate
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    [self verifyAuthChallengeTrust:challenge];
}

#pragma mark - Certificate verification methods
- (void)verifyAuthChallengeTrust:(NSURLAuthenticationChallenge*)challenge {
    BOOL verified = FALSE;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // By now, the OS will already have built a SecTrustRef instance for
        // the server certificates; we just need to evaluate it
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        SecTrustResultType res;
        OSStatus status = SecTrustEvaluate(serverTrust, &res);
        
        if (status == errSecSuccess && ((res == kSecTrustResultProceed) || (res == kSecTrustResultUnspecified))) {
            TCLog(@"iOS certificate chain validation for host %@ passed", challenge.protectionSpace.host);
            // If the iOS Security Framework accepted the certificate chain, we'll
            // check the chain *again* with OpenSSL. This is a relatively simplistic
            // implementation - for example, it won't check hostnames - but we assume
            // that the only gap we need to cover is basicConstraints checking, and
            // OpenSSL *will* do that.
            verified = [self verifyServerTrust:serverTrust];
            if (verified) {
                NSURLCredential* credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            }
        }
        
        if (!verified) {
            TCLog(@"iOS certificate chain validation for host %@ failed", challenge.protectionSpace.host);
            if (self.allowUnsafeCertificate) {
                TCLog(@"WARNING: Connecting to untrusted site %@", challenge.protectionSpace.host);
                verified = YES;
                [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        }
    }
    else {
        TCLog(@"Authentication method not supported: %@", challenge.protectionSpace.authenticationMethod);
    }

    if (!verified) {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
}

- (BOOL)verifyServerTrust:(SecTrustRef)trust {
    BOOL verified = YES;
    if (self.expectedCertNames != nil) {
        verified = [self verifySecurityTrust:trust withCertificateNames:self.expectedCertNames];
    }
    return verified;
}

- (NSArray*)getCertificateSummaries:(SecTrustRef)trustRef {
    CFIndex chainLen = SecTrustGetCertificateCount(trustRef);
    NSMutableArray* summaries = [NSMutableArray arrayWithCapacity:chainLen];
    
    for (int i = 0; i < chainLen; i++) {
        SecCertificateRef leafRef = SecTrustGetCertificateAtIndex(trustRef, i);
        CFStringRef summaryRef = SecCertificateCopySubjectSummary(leafRef);
        NSString* summary = (__bridge NSString*)summaryRef;
        
        [summaries addObject:summary];
        
        CFRelease(summaryRef);
    }
    
    return summaries;
}

- (BOOL)verifySecurityTrust:(SecTrustRef)trustRef withCertificateNames:(NSArray*)expectedCertNames {
    NSArray* certNames = [self getCertificateSummaries:trustRef];
    return [certNames isEqualToArray:expectedCertNames];
}


@end
