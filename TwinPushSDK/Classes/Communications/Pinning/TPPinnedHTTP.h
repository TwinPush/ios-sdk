#import <Foundation/Foundation.h>
#import <Security/Security.h>

// Internal, single-use transport. Each operation owns an ephemeral session;
// no shared cookies, HTTP cache, connection pool or redirect credential forwarding.
@interface TPPinnedHTTP : NSObject <NSURLSessionDataDelegate>
@property (nonatomic, copy) BOOL (^verifyTrust)(SecTrustRef trust, NSString *host);
@property (nonatomic, copy) void (^completion)(NSData *data, NSURLResponse *response, NSError *error);
- (void)start:(NSURLRequest *)request limit:(NSUInteger)limit queue:(NSOperationQueue *)queue;
- (void)cancel;
@end
