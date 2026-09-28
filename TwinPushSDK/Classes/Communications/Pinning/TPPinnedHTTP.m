#import "TPPinnedHTTP.h"
#import "TPPinningProtocol.h"
@interface TPPinnedHTTP ()
@property NSURLSession *session;
@property NSURLSessionDataTask *task;
@property NSMutableData *data;
@property NSUInteger limit;
@property NSError *failure;
@property BOOL completed;
@end
@implementation TPPinnedHTTP
- (void)start:(NSURLRequest *)request limit:(NSUInteger)limit queue:(NSOperationQueue *)queue {
    self.limit=limit; self.data=[NSMutableData data];
    NSURLSessionConfiguration *c=[NSURLSessionConfiguration ephemeralSessionConfiguration];
    c.URLCache=nil; c.HTTPCookieStorage=nil; c.URLCredentialStorage=nil;
    c.requestCachePolicy=NSURLRequestReloadIgnoringLocalCacheData;
    c.timeoutIntervalForRequest=12; c.timeoutIntervalForResource=25;
    self.session=[NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:queue];
    NSMutableURLRequest *r=[request mutableCopy]; r.cachePolicy=NSURLRequestReloadIgnoringLocalCacheData;
    self.task=[self.session dataTaskWithRequest:r]; [self.task resume];
}
- (void)cancel { [self.task cancel]; }
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    self.failure=TPPinningError(8,@"Redirect rejected by certificate pinning transport"); completionHandler(nil);
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (![challenge.protectionSpace.authenticationMethod isEqual:NSURLAuthenticationMethodServerTrust]) { completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil); return; }
    SecTrustRef trust=challenge.protectionSpace.serverTrust;
    CFArrayRef existingPolicies=NULL;
    OSStatus status=trust ? SecTrustCopyPolicies(trust,&existingPolicies) : errSecParam;
    if (status==errSecSuccess) {
        NSMutableArray *policies=[(__bridge NSArray *)existingPolicies mutableCopy];
        SecPolicyRef hostnamePolicy=SecPolicyCreateSSL(true,(__bridge CFStringRef)challenge.protectionSpace.host);
        [policies addObject:(__bridge id)hostnamePolicy];
        status=SecTrustSetPolicies(trust,(__bridge CFArrayRef)policies);
        CFRelease(hostnamePolicy);
    }
    if (existingPolicies) CFRelease(existingPolicies);
    if (status!=errSecSuccess) {
        self.failure=TPPinningError(9,@"Cannot evaluate platform TLS trust");
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
        return;
    }
    // Preserve every platform policy. Trust evaluation can fetch intermediates
    // or revocation data: do not block the SDK state queue or its timeout timers.
    id retainedTrust=CFBridgingRelease(CFRetain(trust));
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        SecTrustResultType result=kSecTrustResultInvalid;
        SecTrustRef evaluatedTrust=(__bridge SecTrustRef)retainedTrust;
        BOOL trusted=SecTrustEvaluate(evaluatedTrust,&result)==errSecSuccess &&
            (result==kSecTrustResultUnspecified || result==kSecTrustResultProceed);
        [session.delegateQueue addOperationWithBlock:^{
            if (self.completed || task.state!=NSURLSessionTaskStateRunning) {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
                return;
            }
            SecTrustRef currentTrust=(__bridge SecTrustRef)retainedTrust;
            BOOL valid=trusted;
            if (valid && self.verifyTrust) valid=self.verifyTrust(currentTrust,challenge.protectionSpace.host);
            if (valid) {
                completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:currentTrust]);
            } else {
                self.failure=TPPinningError(9,@"TLS trust, hostname, pin or pinset validity check failed");
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
            }
        }];
    });
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (response.expectedContentLength > (int64_t)self.limit) {
        self.failure=TPPinningError(10,@"Response exceeds certificate pinning transport size limit"); completionHandler(NSURLSessionResponseCancel);
    } else completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    if (data.length > self.limit-self.data.length) { self.failure=TPPinningError(10,@"Response exceeds certificate pinning transport size limit"); [task cancel]; }
    else [self.data appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    self.completed=YES;
    void (^completion)(NSData *,NSURLResponse *,NSError *)=self.completion; self.completion=nil;
    NSData *data=self.data;
    self.data=nil; self.verifyTrust=nil;
    [session invalidateAndCancel]; self.task=nil; self.session=nil;
    if (completion) completion(data,task.response,self.failure ?: error);
}
@end
