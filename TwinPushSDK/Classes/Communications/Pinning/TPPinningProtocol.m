#import "TPPinningProtocol.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const TPPinningErrorDomain = @"com.twinpush.CertificatePinning";
NSError *TPPinningError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:TPPinningErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:message}];
}
NSData *TPPinningSHA256(NSData *data) {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    return [NSData dataWithBytes:hash length:sizeof(hash)];
}
NSString *TPPinningHex(NSData *data) {
    NSMutableString *s = [NSMutableString string];
    const unsigned char *b = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) [s appendFormat:@"%02x", b[i]];
    return s;
}
static BOOL Match(NSString *s, NSString *pattern) {
    if (![s isKindOfClass:NSString.class]) return NO;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *m = [re firstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
    return m && NSEqualRanges(m.range, NSMakeRange(0, s.length));
}
static NSData *Base64(NSString *s) {
    if (![s isKindOfClass:NSString.class]) return nil;
    NSData *d = [[NSData alloc] initWithBase64EncodedString:s options:0];
    return [[d base64EncodedStringWithOptions:0] isEqual:s] ? d : nil;
}
static NSString *URL64(NSData *d) {
    return [[[[d base64EncodedStringWithOptions:0] stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

// A deliberately small JSON grammar: flat objects of strings, unsigned decimal
// integers, or arrays of strings. Reject duplicate decoded keys BEFORE insertion.
// NSJSONSerialization only decodes individual strings, never the whole object.
@interface TPPinningJSON : NSObject
@property NSString *text;
@property NSUInteger offset;
- (NSDictionary *)object;
@end
@implementation TPPinningJSON
- (void)space { while (_offset < _text.length && [@" \t\r\n" rangeOfString:[_text substringWithRange:NSMakeRange(_offset, 1)]].location != NSNotFound) _offset++; }
- (BOOL)take:(unichar)c { [self space]; if (_offset < _text.length && [_text characterAtIndex:_offset] == c) { _offset++; return YES; } return NO; }
- (NSString *)string {
    [self space]; NSUInteger start = _offset;
    if (![self take:'"']) return nil;
    while (_offset < _text.length) {
        unichar c = [_text characterAtIndex:_offset++];
        if (c < 0x20) return nil; // JSON forbids unescaped control characters.
        if (c == '\\') { if (_offset == _text.length) return nil; _offset++; }
        else if (c == '"') {
            NSData *d = [[_text substringWithRange:NSMakeRange(start, _offset-start)] dataUsingEncoding:NSUTF8StringEncoding];
            id value = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingFragmentsAllowed error:nil];
            return [value isKindOfClass:NSString.class] ? value : nil;
        }
    }
    return nil;
}
- (id)value {
    [self space]; if (_offset >= _text.length) return nil;
    if ([_text characterAtIndex:_offset] == '"') return [self string];
    if ([self take:'[']) {
        NSMutableArray *a = [NSMutableArray array];
        if ([self take:']']) return a;
        do { NSString *s = [self string]; if (!s || a.count == 32) return nil; [a addObject:s]; } while ([self take:',']);
        return [self take:']'] ? a : nil;
    }
    NSUInteger start = _offset;
    while (_offset < _text.length && [_text characterAtIndex:_offset] >= '0' && [_text characterAtIndex:_offset] <= '9') _offset++;
    NSString *n = [_text substringWithRange:NSMakeRange(start, _offset-start)];
    if (!Match(n, @"[1-9][0-9]{0,15}") || n.longLongValue > 9007199254740991LL) return nil;
    return @(n.longLongValue);
}
- (NSDictionary *)object {
    if (![self take:'{']) return nil;
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    do {
        NSString *k = [self string];
        if (!k || d[k] || d.count == 8 || ![self take:':']) return nil;
        id v = [self value]; if (!v) return nil; d[k] = v;
    } while ([self take:',']);
    if (![self take:'}']) return nil;
    [self space]; return _offset == _text.length ? d : nil;
}
@end

// Strict definite/minimal DER lengths. All slices retain original SPKI bytes.
static NSData *TLV(NSData *d, NSUInteger *offset, uint8_t tag, BOOL content) {
    const uint8_t *b = d.bytes; NSUInteger start = *offset, i = start;
    if (i + 2 > d.length || b[i++] != tag) return nil;
    NSUInteger n = b[i++];
    if (n & 128) {
        NSUInteger count = n & 127; n = 0;
        if (!count || count > sizeof(NSUInteger) || count > d.length-i || !b[i]) return nil;
        for (NSUInteger j = 0; j < count; j++) { if (n > (NSUIntegerMax >> 8)) return nil; n = (n << 8) | b[i++]; }
        if (n < 128) return nil;
    }
    if (n > d.length-i) return nil;
    *offset = i+n;
    return [d subdataWithRange:content ? NSMakeRange(i,n) : NSMakeRange(start,i+n-start)];
}
static BOOL Integer(NSData *d) {
    const uint8_t *b = d.bytes;
    return d.length && !(b[0] & 128) && !(d.length > 1 && b[0] == 0 && !(b[1] & 128));
}
static NSData *RSAData(NSData *spki) {
    NSUInteger i = 0; NSData *seq = TLV(spki,&i,0x30,YES); if (!seq || i != spki.length) return nil;
    i = 0; NSData *alg = TLV(seq,&i,0x30,NO);
    const uint8_t rsaAlg[] = {0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x01,0x05,0x00};
    if (![alg isEqual:[NSData dataWithBytes:rsaAlg length:sizeof(rsaAlg)]]) return nil;
    NSData *bits = TLV(seq,&i,0x03,YES);
    if (!bits || i != seq.length || bits.length < 2 || ((const uint8_t *)bits.bytes)[0]) return nil;
    NSData *rsa = [bits subdataWithRange:NSMakeRange(1,bits.length-1)];
    i = 0; NSData *body = TLV(rsa,&i,0x30,YES); if (!body || i != rsa.length) return nil;
    i = 0; NSData *mod = TLV(body,&i,0x02,YES), *exp = TLV(body,&i,0x02,YES);
    if (!Integer(mod) || !Integer(exp) || i != body.length) return nil;
    const uint8_t *exponent=exp.bytes;
    const uint8_t *modulus=mod.bytes;
    if (!(modulus[mod.length-1] & 1) || !(exponent[exp.length-1] & 1) ||
        (exp.length == 1 && exponent[0] < 3)) return nil;
    const uint8_t *b = mod.bytes; NSUInteger start = b[0] == 0 ? 1 : 0;
    NSUInteger bitCount = (mod.length-start)*8;
    if (start >= mod.length) return nil;
    for (uint8_t first = b[start]; !(first & 128) && bitCount; first <<= 1) bitCount--;
    return bitCount >= 2048 && bitCount <= 8192 ? rsa : nil;
}
NSData *TPPinningCertificateSPKI(SecCertificateRef certificate) {
    if (!certificate) return nil;
    NSData *der = CFBridgingRelease(SecCertificateCopyData(certificate));
    NSUInteger i=0; NSData *cert = TLV(der,&i,0x30,YES); if (!cert || i != der.length) return nil;
    i=0; NSData *tbs = TLV(cert,&i,0x30,YES); if (!tbs) return nil;
    i=0; if (tbs.length && ((const uint8_t *)tbs.bytes)[0] == 0xa0 && !TLV(tbs,&i,0xa0,YES)) return nil;
    if (!TLV(tbs,&i,0x02,YES)) return nil; // serial
    for (int n=0;n<4;n++) if (!TLV(tbs,&i,0x30,YES)) return nil; // signature, issuer, validity, subject
    return TLV(tbs,&i,0x30,NO);
}
static BOOL Fields(NSDictionary *d, NSArray *fields) {
    return d && [[NSSet setWithArray:d.allKeys] isEqual:[NSSet setWithArray:fields]];
}
@implementation TPPinningProtocol
+ (BOOL)validIntegrationKey:(NSString *)key {
    if (![key isKindOfClass:NSString.class] || key.length != 57 || !Match(key,@"tp-pinning-v1:[A-Za-z0-9_-]{43}")) return NO;
    NSString *s = [[[key substringFromIndex:14] stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSData *d = Base64([s stringByAppendingString:@"="]);
    return d.length == 32 && [[@"tp-pinning-v1:" stringByAppendingString:URL64(d)] isEqual:key];
}
+ (NSDictionary *)parse:(NSData *)data limit:(NSUInteger)limit error:(NSError **)error {
    TPPinningJSON *p = [TPPinningJSON new];
    if (data.length && data.length <= limit) p.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *d = p.text ? [p object] : nil;
    if (!d && error) *error = TPPinningError(1,@"Invalid, duplicate, oversized or unsupported pinning JSON");
    return d;
}
+ (NSDictionary *)authenticateKey:(NSData *)data integrationKey:(NSString *)key hostname:(NSString *)host error:(NSError **)error {
    if (error) *error = TPPinningError(2,@"Unauthenticated certificate pinning verification key");
    NSDictionary *d = [self parse:data limit:16384 error:error];
    if (!Fields(d,@[@"format",@"environment",@"algorithm",@"key_id",@"public_key"])) return nil;
    for (id v in d.allValues) if (![v isKindOfClass:NSString.class]) return nil;
    if (![self validIntegrationKey:key] || ![d[@"format"] isEqual:@"twinpush-pinning-key-v1"] || ![d[@"algorithm"] isEqual:@"RS256"] || !Match(d[@"environment"],@"[a-z0-9_-]+:[a-z0-9.-]+") || ![[d[@"environment"] componentsSeparatedByString:@":"].lastObject isEqual:host]) return nil;
    NSString *pem = d[@"public_key"];
    if (!Match(pem,@"-----BEGIN PUBLIC KEY-----\\r?\\n[A-Za-z0-9+/=\\r\\n]+\\r?\\n-----END PUBLIC KEY-----(\\r?\\n)?")) return nil;
    NSRange end = [pem rangeOfString:@"-----END PUBLIC KEY-----"];
    NSString *body = [pem substringWithRange:NSMakeRange(26,end.location-26)];
    body = [[body stringByReplacingOccurrencesOfString:@"\r" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSData *spki = Base64(body), *rsa = RSAData(spki);
    if (!rsa) return nil;
    NSMutableData *input = [[[NSString stringWithFormat:@"twinpush-pinning-key-v1\n%@\n",d[@"environment"]] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [input appendData:spki];
    if (![[ @"tp-pinning-v1:" stringByAppendingString:URL64(TPPinningSHA256(input))] isEqual:key] || ![TPPinningHex(TPPinningSHA256(spki)) isEqual:d[@"key_id"]]) return nil;
    SecKeyRef publicKey = SecKeyCreateWithData((__bridge CFDataRef)rsa, (__bridge CFDictionaryRef)@{(__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeRSA,(__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic},NULL);
    if (!publicKey) return nil;
    NSMutableDictionary *result = [d mutableCopy]; result[@"key"] = CFBridgingRelease(publicKey); result[@"spki"] = spki;
    if (error) *error=nil;
    return result;
}
+ (NSDictionary *)verifyDocument:(NSData *)data authenticatedKey:(NSDictionary *)key now:(NSDate *)now error:(NSError **)error {
    if (error) *error = TPPinningError(3,@"Invalid signature, expired or malformed certificate pinset");
    NSDictionary *d = [self parse:data limit:16384 error:error];
    if (!Fields(d,@[@"format",@"algorithm",@"environment",@"key_id",@"version",@"valid_until",@"pins",@"signature"])) return nil;
    for (NSString *name in @[@"format",@"algorithm",@"environment",@"key_id",@"valid_until",@"signature"]) if (![d[name] isKindOfClass:NSString.class]) return nil;
    if (![d[@"format"] isEqual:@"twinpush-certificate-pins-v1"] || ![d[@"algorithm"] isEqual:@"RS256"] || ![d[@"environment"] isEqual:key[@"environment"]] || ![d[@"key_id"] isEqual:key[@"key_id"]] || ![d[@"version"] isKindOfClass:NSNumber.class]) return nil;
    if (!Match(d[@"valid_until"],@"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z")) return nil;
    NSDateFormatter *f = [NSDateFormatter new]; f.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]; f.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]; f.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0]; f.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'"; f.lenient = NO;
    NSDate *expiry = [f dateFromString:d[@"valid_until"]];
    if (!expiry || ![[f stringFromDate:expiry] isEqual:d[@"valid_until"]] || [expiry compare:now] != NSOrderedDescending) return nil;
    NSArray *pins=d[@"pins"];
    if (![pins isKindOfClass:NSArray.class] || !pins.count || pins.count>32) return nil;
    NSString *previous=nil;
    for (NSString *pin in pins) {
        if (!Match(pin,@"sha256/[A-Za-z0-9+/]{43}=") || Base64([pin substringFromIndex:7]).length != 32 || (previous && [previous compare:pin options:NSLiteralSearch] != NSOrderedAscending)) return nil;
        previous=pin;
    }
    NSMutableArray *lines = [NSMutableArray arrayWithArray:@[d[@"format"],d[@"algorithm"],d[@"environment"],d[@"key_id"],[d[@"version"] stringValue],d[@"valid_until"],[@(pins.count) stringValue]]];
    [lines addObjectsFromArray:pins];
    NSData *canonical = [[[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sig = Base64(d[@"signature"]);
    if (!sig || !key[@"key"] || !SecKeyVerifySignature((__bridge SecKeyRef)key[@"key"],kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256,(__bridge CFDataRef)canonical,(__bridge CFDataRef)sig,NULL)) return nil;
    NSMutableDictionary *result=[d mutableCopy]; result[@"canonical"]=canonical; result[@"expiry"]=expiry;
    if (error) *error=nil;
    return result;
}
@end
