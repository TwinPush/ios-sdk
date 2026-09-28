#import <Foundation/Foundation.h>
#import <Security/Security.h>

FOUNDATION_EXPORT NSString * const TPPinningErrorDomain;
FOUNDATION_EXPORT NSError *TPPinningError(NSInteger code, NSString *message);
FOUNDATION_EXPORT NSData *TPPinningSHA256(NSData *data);
FOUNDATION_EXPORT NSString *TPPinningHex(NSData *data);
FOUNDATION_EXPORT NSData *TPPinningCertificateSPKI(SecCertificateRef certificate);

// Internal protocol implementation. No downloaded value is a trust anchor.
@interface TPPinningProtocol : NSObject
+ (BOOL)validIntegrationKey:(NSString *)key;
+ (NSDictionary *)parse:(NSData *)data limit:(NSUInteger)limit error:(NSError **)error;
+ (NSDictionary *)authenticateKey:(NSData *)data integrationKey:(NSString *)key hostname:(NSString *)host error:(NSError **)error;
+ (NSDictionary *)verifyDocument:(NSData *)data authenticatedKey:(NSDictionary *)key now:(NSDate *)now error:(NSError **)error;
@end
