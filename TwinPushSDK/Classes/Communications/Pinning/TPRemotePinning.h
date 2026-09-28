#import <Foundation/Foundation.h>
@interface TPPinningCall : NSObject
- (void)cancel;
@end
@interface TPRemotePinning : NSObject
+ (BOOL)validIntegrationKey:(NSString *)key;
- (instancetype)initWithKey:(NSString *)key;
- (void)configureURL:(NSString *)url appID:(NSString *)appID token:(NSString *)token;
- (void)refresh;
- (void)invalidate;
- (TPPinningCall *)send:(NSURLRequest *)request certificateNames:(NSArray *)names completion:(void (^)(NSData *, NSURLResponse *, NSError *))completion;
@end
