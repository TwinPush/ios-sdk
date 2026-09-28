#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "TPRequestLauncher.h"
#import "TPRequestLauncher+RemotePinning.h"
#import "TwinPushManager.h"
#endif
#import "TPPinningProtocol.h"
#import "TPPinnedHTTP.h"
#import "TPRemotePinning.h"

static NSUInteger checks=0;
static NSUInteger trustChallenges=0;
#define CHECK(c) do { checks++; if (!(c)) { NSLog(@"FAIL line %d: %s",__LINE__,#c); exit(1); } } while(0)
static NSData *JSON(id value) { return [NSJSONSerialization dataWithJSONObject:value options:0 error:nil]; }
static NSData *Text(NSString *s) { return [s dataUsingEncoding:NSUTF8StringEncoding]; }
static NSDate *Now(void) { return [NSDate dateWithTimeIntervalSince1970:1893456000]; } // 2030
static NSString *work;
static NSDictionary *fixtures;
static void Wait(BOOL (^done)(void)) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:35];
    while (!done() && deadline.timeIntervalSinceNow>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    CHECK(done());
}
static void Control(NSDictionary *d) { CHECK([JSON(d) writeToFile:[work stringByAppendingPathComponent:@"control.json"] atomically:YES]); }
static NSArray *Hits(void) {
    NSString *s=[NSString stringWithContentsOfFile:[work stringByAppendingPathComponent:@"hits.jsonl"] encoding:NSUTF8StringEncoding error:nil];
    return [s componentsSeparatedByString:@"\n"] ?: @[];
}
// Test-only CA injection, on the actual trust object before production evaluation.
// No custom anchor, bypass or alternate trust policy is compiled into the SDK.
@interface TestHTTP : TPPinnedHTTP
@property dispatch_semaphore_t completionSignal;
@property NSString *additionalHostnamePolicy;
@end
@implementation TestHTTP
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completion {
    if (challenge.protectionSpace.serverTrust) {
        trustChallenges++;
        NSData *der=[NSData dataWithContentsOfFile:[work stringByAppendingPathComponent:@"root.der"]];
        SecCertificateRef cert=SecCertificateCreateWithData(NULL,(__bridge CFDataRef)der);
        SecTrustSetAnchorCertificates(challenge.protectionSpace.serverTrust,(__bridge CFArrayRef)@[(__bridge id)cert]);
        SecTrustSetAnchorCertificatesOnly(challenge.protectionSpace.serverTrust,YES); CFRelease(cert);
        if (self.additionalHostnamePolicy) {
            SecPolicyRef policy=SecPolicyCreateSSL(true,(__bridge CFStringRef)self.additionalHostnamePolicy);
            CHECK(SecTrustSetPolicies(challenge.protectionSpace.serverTrust,policy)==errSecSuccess);
            CFRelease(policy);
        }
    }
    [super URLSession:session task:task didReceiveChallenge:challenge completionHandler:completion];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [super URLSession:session task:task didCompleteWithError:error];
    if ([task.originalRequest.URL.path isEqual:@"/ordinary"] && self.completionSignal) {
        dispatch_semaphore_signal(self.completionSignal);
    }
}
@end
@interface TPRemotePinning (Testing)
- (TPPinnedHTTP *)newOperation;
- (NSURL *)storageDirectory;
- (BOOL)accept:(NSData *)data keyData:(NSData *)keyData key:(NSDictionary *)key;
- (void)loadCache;
- (BOOL)usable;
@end
@interface TestController : TPRemotePinning
@property NSString *testDirectory;
@property dispatch_semaphore_t completionSignal;
@property NSString *additionalHostnamePolicy;
@end
@implementation TestController
- (TPPinnedHTTP *)newOperation {
    TestHTTP *op=[TestHTTP new];
    op.completionSignal=self.completionSignal;
    op.additionalHostnamePolicy=self.additionalHostnamePolicy;
    return op;
}
- (NSURL *)storageDirectory { return [NSURL fileURLWithPath:self.testDirectory]; }
@end
static void Sync(TPRemotePinning *c,void (^b)(void)) { dispatch_sync([c valueForKey:@"queue"],b); }
static void ForceRefresh(TPRemotePinning *c) {
    Sync(c,^{ [c setValue:nil forKey:@"nextRefresh"]; }); [c refresh];
    __block BOOL done=NO;
    Wait(^BOOL{ Sync(c,^{ done=![[c valueForKey:@"refreshing"] boolValue]; }); return done; });
}
static TestController *Controller(NSString *name,NSString *origin) {
    TestController *c=[[TestController alloc] initWithKey:fixtures[@"anchor"]];
    c.testDirectory=[work stringByAppendingPathComponent:name];
    [c setValue:[^{ return Now(); } copy] forKey:@"clock"];
    [c configureURL:origin appID:@"app" token:@"APP-TOKEN"];
    __block BOOL done=NO;
    Wait(^BOOL{ Sync(c,^{ done=![[c valueForKey:@"refreshing"] boolValue]; }); return done; });
    return c;
}
static NSError *Send(TPRemotePinning *c,NSString *origin) {
    __block BOOL done=NO; __block NSError *failure=nil;
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[origin stringByAppendingString:@"/ordinary"]]];
    r.HTTPMethod=@"POST"; r.HTTPBody=Text(@"PRIVATE-BODY"); [r setValue:@"PRIVATE-TOKEN" forHTTPHeaderField:@"X-TwinPush-REST-API-Token"];
    [c send:r completion:^(NSData *d,NSURLResponse *response,NSError *e){ CHECK(NSThread.isMainThread); failure=e; done=YES; }];
    Wait(^BOOL{ return done; }); return failure;
}
static NSUInteger OrdinaryHits(void) {
    NSUInteger n=0; for (NSString *s in Hits()) if ([s containsString:@"/ordinary"]) n++; return n;
}
static void ProtocolTests(NSDictionary *v) {
    NSString *anchor=v[@"integration_key"];
    CHECK([TPPinningProtocol validIntegrationKey:anchor]);
    for (id bad in @[@"",@"tp-pinning-v2:abc",[anchor stringByAppendingString:@"="],[anchor stringByAppendingString:@"\n"],[@" " stringByAppendingString:anchor],[[anchor substringToIndex:56] stringByAppendingString:@"R"],@1]) CHECK(![TPPinningProtocol validIntegrationKey:bad]);
    NSError *error=nil;
    NSDictionary *key=[TPPinningProtocol authenticateKey:JSON(v[@"verification_key"]) integrationKey:anchor hostname:@"sdk.example.com" error:&error];
    CHECK(key && !error);
    CHECK([TPPinningHex(TPPinningSHA256(key[@"spki"])) isEqual:v[@"verification_key"][@"key_id"]]);
    NSDictionary *doc=[TPPinningProtocol verifyDocument:JSON(v[@"configuration"]) authenticatedKey:key now:Now() error:&error];
    CHECK(doc && !error);
    CHECK([[doc[@"canonical"] base64EncodedStringWithOptions:0] isEqual:v[@"canonical_base64"]]);
    CHECK(![TPPinningProtocol authenticateKey:JSON(v[@"verification_key"]) integrationKey:anchor hostname:@"other.example.com" error:nil]);
    for (NSString *field in @[@"format",@"environment",@"algorithm",@"key_id",@"public_key"]) {
        NSMutableDictionary *k=[v[@"verification_key"] mutableCopy]; k[field]=@"attacker";
        CHECK(![TPPinningProtocol authenticateKey:JSON(k) integrationKey:anchor hostname:@"sdk.example.com" error:nil]);
    }
    NSMutableDictionary *edited=[v[@"verification_key"] mutableCopy]; edited[@"environment"]=@"live:sdk.example.com";
    CHECK(![TPPinningProtocol authenticateKey:JSON(edited) integrationKey:anchor hostname:@"sdk.example.com" error:nil]);
    for (NSString *suffix in @[@"junk",@"\n-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----",v[@"verification_key"][@"public_key"]]) {
        edited=[v[@"verification_key"] mutableCopy]; edited[@"public_key"]=[edited[@"public_key"] stringByAppendingString:suffix];
        CHECK(![TPPinningProtocol authenticateKey:JSON(edited) integrationKey:anchor hostname:@"sdk.example.com" error:nil]);
    }
    NSArray *fields=@[@"format",@"algorithm",@"environment",@"key_id",@"version",@"valid_until",@"pins",@"signature",@"extra"];
    NSArray *values=@[@"other",@"HS256",@"live:sdk.example.com",[@"0" stringByPaddingToLength:64 withString:@"0" startingAtIndex:0],@2,@"2034-01-01T00:00:00Z",@[fixtures[@"a"]],@"AA==",@"unsigned"];
    for (NSUInteger i=0;i<fields.count;i++) {
        edited=[v[@"configuration"] mutableCopy]; edited[fields[i]]=values[i];
        CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
    }
    for (NSString *field in fields) {
        if ([field isEqual:@"extra"]) continue;
        edited=[v[@"configuration"] mutableCopy]; [edited removeObjectForKey:field];
        CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
        edited=[v[@"configuration"] mutableCopy]; edited[field]=@YES;
        CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
    }
    for (NSString *date in @[@"2034-02-30T00:00:00Z",@"2034-01-01T00:00:00+00:00",@"2034-01-01T00:00:00.0Z",@"2034-01-01T24:00:00Z",@"2034-01-01T00:00:60Z"]) {
        edited=[v[@"configuration"] mutableCopy]; edited[@"valid_until"]=date;
        CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
    }
    NSArray *pinCases=@[@[],@[fixtures[@"a"],fixtures[@"a"]],@[fixtures[@"b"],fixtures[@"a"],fixtures[@"b"]],@[@"sha256/AAAA"],@[@"sha256/YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWF="],@[@1]];
    for (NSArray *pins in pinCases) {
        edited=[v[@"configuration"] mutableCopy]; edited[@"pins"]=pins;
        CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
    }
    edited=[v[@"configuration"] mutableCopy]; edited[@"signature"]=[edited[@"signature"] stringByAppendingString:@"\n"];
    CHECK(![TPPinningProtocol verifyDocument:JSON(edited) authenticatedKey:key now:Now() error:nil]);
    CHECK(![TPPinningProtocol verifyDocument:JSON(v[@"configuration"]) authenticatedKey:key now:[NSDate dateWithTimeIntervalSince1970:2051222400] error:nil]);
    for (NSString *json in @[@"{\"x\":\"a\",\"x\":\"b\"}",@"{\"x\":\"a\",\"\\u0078\":\"b\"}",@"{\"v\":1.0}",@"{\"v\":1e0}",@"{\"v\":9007199254740992}",@"{\"v\":01}",@"{\"v\":-1}",@"{\"v\":true}",@"{\"v\":null}",@"{\"v\":{}}",@"{\"v\":1} trailing"]) CHECK(![TPPinningProtocol parse:Text(json) limit:16384 error:nil]);
    for (NSUInteger control=0;control<32;control++) {
        NSString *invalid=[NSString stringWithFormat:@"{\"field\":\"a%Cb\"}",(unichar)control];
        CHECK(![TPPinningProtocol parse:Text(invalid) limit:16384 error:nil]);
    }
    CHECK(![TPPinningProtocol parse:[NSMutableData dataWithLength:16385] limit:16384 error:nil]);
    CHECK([TPPinningProtocol parse:Text(@"{\"v\":9007199254740991}") limit:16384 error:nil]);
    NSDictionary *attackerKey=[TPPinningProtocol authenticateKey:JSON(fixtures[@"attackerKey"]) integrationKey:fixtures[@"attackerAnchor"] hostname:@"localhost" error:nil];
    CHECK([TPPinningProtocol verifyDocument:JSON(fixtures[@"attacker"]) authenticatedKey:attackerKey now:Now() error:nil]);
    CHECK(![TPPinningProtocol authenticateKey:JSON(fixtures[@"attackerKey"]) integrationKey:fixtures[@"anchor"] hostname:@"localhost" error:nil]);
    NSLog(@"Protocol/vector checks passed");
}
static void PersistenceTests(void) {
    NSDictionary *key=[TPPinningProtocol authenticateKey:JSON(fixtures[@"key"]) integrationKey:fixtures[@"anchor"] hostname:@"localhost" error:nil];
    TPRemotePinning *c=[[TPRemotePinning alloc] initWithKey:fixtures[@"anchor"]];
    NSURL *store=[NSURL fileURLWithPath:[work stringByAppendingPathComponent:@"persistent.plist"]];
    void (^prepare)(TPRemotePinning *)=^(TPRemotePinning *s){ [s setValue:@"localhost" forKey:@"host"]; [s setValue:@"https://localhost" forKey:@"origin"]; [s setValue:@"app" forKey:@"appID"]; [s setValue:store forKey:@"storeURL"]; [s setValue:[NSMutableDictionary dictionary] forKey:@"records"]; [s setValue:[^{return Now();} copy] forKey:@"clock"]; };
    Sync(c,^{ prepare(c);
        CHECK([c accept:JSON(fixtures[@"B"]) keyData:JSON(fixtures[@"key"]) key:key]);
        CHECK(![c accept:JSON(fixtures[@"A"]) keyData:JSON(fixtures[@"key"]) key:key]);
        CHECK(![c accept:JSON(fixtures[@"same"]) keyData:JSON(fixtures[@"key"]) key:key]);
        CHECK([c accept:JSON(fixtures[@"B"]) keyData:JSON(fixtures[@"key"]) key:key]);
    });
    [c invalidate];
    TPRemotePinning *restart=[[TPRemotePinning alloc] initWithKey:fixtures[@"anchor"]];
    Sync(restart,^{ prepare(restart); [restart loadCache]; CHECK([restart usable]); CHECK(![restart accept:JSON(fixtures[@"AB"]) keyData:JSON(fixtures[@"key"]) key:key]);
        [restart setValue:[^{ return [NSDate dateWithTimeIntervalSince1970:2051222400]; } copy] forKey:@"clock"]; CHECK(![restart usable]);
        [restart setValue:@"different-app" forKey:@"appID"]; [restart setValue:nil forKey:@"document"]; [restart loadCache]; CHECK(![restart usable]);
    });
    // Anchor/key_id changes cannot reset the per-environment high-water mark.
    TPRemotePinning *rotated=[[TPRemotePinning alloc] initWithKey:fixtures[@"attackerAnchor"]];
    Sync(rotated,^{ prepare(rotated); [rotated loadCache]; CHECK(![rotated usable]); CHECK([rotated valueForKey:@"records"][@"test:localhost"]); });
    [restart invalidate]; [rotated invalidate];
    // A stale second controller must re-read the committed high-water mark.
    TPRemotePinning *stale=[[TPRemotePinning alloc] initWithKey:fixtures[@"anchor"]];
    Sync(stale,^{ prepare(stale); CHECK(![stale accept:JSON(fixtures[@"A"]) keyData:JSON(fixtures[@"key"]) key:key]); });
    [stale invalidate];
    NSLog(@"Persistence/rollback checks passed");
}
static void DeliveryAndStorageRegressions(NSString *origin) {
    Control(@{@"certificate":@"a",@"document":@"A"});
    // Deliberately hold the main queue until the network completion is enqueued.
    // A configuration/expiry/revision change must fence the delayed success.
    for (NSString *scenario in @[@"configuration",@"expiry",@"pinset",@"invalidate"]) {
        TestController *c=Controller([@"delivery-" stringByAppendingString:scenario],origin);
        c.completionSignal=dispatch_semaphore_create(0);
        __block BOOL done=NO; __block NSError *error=nil;
        [c send:[NSURLRequest requestWithURL:[NSURL URLWithString:[origin stringByAppendingString:@"/ordinary"]]] completion:^(NSData *data,NSURLResponse *response,NSError *failure){
            CHECK(NSThread.isMainThread); CHECK(data==nil); CHECK(response==nil);
            error=failure; done=YES;
        }];
        CHECK(dispatch_semaphore_wait(c.completionSignal,dispatch_time(DISPATCH_TIME_NOW,10*NSEC_PER_SEC))==0);
        CHECK(!done);
        if ([scenario isEqual:@"configuration"]) [c configureURL:origin appID:@"different-app" token:@"TOKEN"];
        else if ([scenario isEqual:@"invalidate"]) [c invalidate];
        else Sync(c,^{
            if ([scenario isEqual:@"expiry"]) [c setValue:[^{return [NSDate dateWithTimeIntervalSince1970:2051222400];} copy] forKey:@"clock"];
            else {
                NSDictionary *key=[TPPinningProtocol authenticateKey:JSON(fixtures[@"key"]) integrationKey:fixtures[@"anchor"] hostname:@"localhost" error:nil];
                CHECK([c accept:JSON(fixtures[@"AB"]) keyData:JSON(fixtures[@"key"]) key:key]);
            }
        });
        Wait(^BOOL{return done;}); CHECK([error.domain isEqual:TPPinningErrorDomain]); CHECK(error.code==4);
        [c invalidate];
    }
    TestController *policy=Controller(@"extra-policy",origin);
    policy.additionalHostnamePolicy=@"not-localhost.example";
    NSUInteger hits=OrdinaryHits(); CHECK(Send(policy,origin)); CHECK(OrdinaryHits()==hits); [policy invalidate];

    TestController *c=Controller(@"storage-failure",origin);
    __block NSURL *original=nil;
    Sync(c,^{ original=[c valueForKey:@"storeURL"]; });
    NSData *saved=[NSData dataWithContentsOfURL:original]; CHECK(saved.length>0);
    NSString *link=[work stringByAppendingPathComponent:@"cache-symlink"];
    CHECK([[NSFileManager defaultManager] createSymbolicLinkAtPath:link withDestinationPath:original.path error:nil]);
    Sync(c,^{ [c setValue:[NSURL fileURLWithPath:link] forKey:@"storeURL"]; [c loadCache]; CHECK(![c usable]); });
    Sync(c,^{ [c setValue:original forKey:@"storeURL"]; [c setValue:@NO forKey:@"storageFailed"]; [c loadCache]; CHECK([c usable]); });
    CHECK([[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions:@0} ofItemAtPath:original.path error:nil]);
    Sync(c,^{ [c loadCache]; CHECK(![c usable]); });
    CHECK([[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions:@0600} ofItemAtPath:original.path error:nil]);
    ForceRefresh(c);
    Sync(c,^{ CHECK([c usable]); });
    id restored=[NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:original] options:0 format:nil error:nil];
    id savedRecord=[NSPropertyListSerialization propertyListWithData:saved options:0 format:nil error:nil];
    CHECK([restored isEqual:savedRecord]);
    CHECK([[NSMutableData dataWithLength:1024*1024+1] writeToURL:original atomically:YES]);
    Sync(c,^{ [c loadCache]; CHECK(![c usable]); });
    CHECK([saved writeToURL:original atomically:YES]);
    ForceRefresh(c); CHECK(!Send(c,origin)); [c invalidate];
    NSLog(@"Delayed callbacks, retained TLS policies and storage recovery regressions passed");
}
static void TransportTests(NSString *origin) {
    Control(@{@"certificate":@"a",@"document":@"A"});
    TestController *c=Controller(@"network",origin);
    CHECK(!Send(c,origin));
    Control(@{@"certificate":@"renewed",@"document":@"A"}); CHECK(!Send(c,origin));
    Control(@{@"certificate":@"a",@"document":@"AB"}); ForceRefresh(c); CHECK(!Send(c,origin));
    Control(@{@"certificate":@"b",@"document":@"AB"}); CHECK(!Send(c,origin));
    Control(@{@"certificate":@"b",@"document":@"B"}); ForceRefresh(c); CHECK(!Send(c,origin));
    NSUInteger before=OrdinaryHits();
    Control(@{@"certificate":@"a",@"document":@"B"}); CHECK(Send(c,origin)); CHECK(OrdinaryHits()==before);
    // New isolated sessions must not reuse the previous [A] trust decision.
    Control(@{@"certificate":@"a",@"document":@"bad"}); ForceRefresh(c); CHECK(Send(c,origin)); CHECK(OrdinaryHits()==before);
    Control(@{@"certificate":@"a",@"document":@"fixed"});
    Sync(c,^{ [c setValue:nil forKey:@"lastPinRefresh"]; });
    CHECK(Send(c,origin)); // fail the original POST; never replay automatically
    __block BOOL recovered=NO;
    Wait(^BOOL { Sync(c,^{ recovered=[[[c valueForKey:@"document"] objectForKey:@"version"] isEqual:@5]; }); return recovered; });
    CHECK(!Send(c,origin));
    Control(@{@"certificate":@"wronghost",@"document":@"fixed"}); before=OrdinaryHits(); CHECK(Send(c,origin)); CHECK(OrdinaryHits()==before);
    Control(@{@"certificate":@"a",@"document":@"fixed",@"redirect":@YES}); CHECK(Send(c,origin));
    for (NSString *line in Hits()) CHECK(![line containsString:@"/leaked"]);
    Control(@{@"certificate":@"a",@"document":@"fixed",@"status":@503}); ForceRefresh(c);
    __block BOOL valid=NO; Sync(c,^{valid=[c usable];}); CHECK(valid);
    Control(@{@"certificate":@"a",@"document":@"fixed"});
    // System trust without the test root must reject even if the pin matches.
    __block BOOL done=NO; __block NSError *failure=nil;
    TPPinnedHTTP *untrusted=[TPPinnedHTTP new]; untrusted.verifyTrust=^BOOL(SecTrustRef trust,NSString *host){ return YES; };
    untrusted.completion=^(NSData *d,NSURLResponse *r,NSError *e){failure=e;done=YES;};
    before=OrdinaryHits(); [untrusted start:[NSURLRequest requestWithURL:[NSURL URLWithString:[origin stringByAppendingString:@"/ordinary"]]] limit:16384 queue:NSOperationQueue.mainQueue]; Wait(^BOOL{return done;}); CHECK(failure); CHECK(OrdinaryHits()==before);
    Sync(c,^{ [c setValue:[^{return [NSDate dateWithTimeIntervalSince1970:2051222400];} copy] forKey:@"clock"]; }); CHECK(Send(c,origin)); CHECK(OrdinaryHits()==before);
    // Cancellation suppresses callbacks, including while awaiting bootstrap.
    TestController *cancelled=Controller(@"cancel",origin); __block BOOL callback=NO;
    TPPinningCall *call=[cancelled send:[NSURLRequest requestWithURL:[NSURL URLWithString:[origin stringByAppendingString:@"/ordinary"]]] completion:^(NSData *d,NSURLResponse *r,NSError *e){callback=YES;}];
    [call cancel]; [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.2]]; CHECK(!callback);
    [cancelled invalidate]; [c invalidate];
    Control(@{@"certificate":@"a",@"document":@"A",@"redirect":@YES});
    TestController *redirect=Controller(@"redirect",origin); CHECK(Send(redirect,origin)); [redirect invalidate];
    Control(@{@"certificate":@"a",@"document":@"A",@"oversized":@YES});
    TestController *oversized=Controller(@"oversized",origin); CHECK(Send(oversized,origin)); [oversized invalidate];
    Control(@{@"certificate":@"a",@"document":@"A",@"streamed":@YES});
    TestController *streamed=Controller(@"streamed",origin); CHECK(Send(streamed,origin)); [streamed invalidate];
    for (NSNumber *status in @[@403,@404]) {
        Control(@{@"certificate":@"a",@"document":@"A",@"status":status});
        TestController *httpError=Controller([status stringValue],origin);
        NSError *failure=Send(httpError,origin); CHECK(failure);
        NSError *bootstrapError=failure.userInfo[NSUnderlyingErrorKey];
        CHECK([bootstrapError.userInfo[@"HTTPStatusCode"] isEqual:status]);
        [httpError invalidate];
    }
    Control(@{@"certificate":@"a",@"document":@"rootOnly"});
    TestController *rootOnly=Controller(@"rootOnly",origin); before=OrdinaryHits(); CHECK(Send(rootOnly,origin)); CHECK(OrdinaryHits()==before); [rootOnly invalidate];
    Control(@{@"certificate":@"ec",@"document":@"EC"});
    TestController *ec=Controller(@"ec",origin); CHECK(!Send(ec,origin)); [ec invalidate];
    CHECK(trustChallenges>10);
    NSLog(@"Real HTTPS transport checks passed (%lu trust challenges)",(unsigned long)trustChallenges);
}
static NSUInteger KeyHits(void) {
    NSUInteger count=0; for (NSString *line in Hits()) if ([line containsString:@"/verification_key"]) count++; return count;
}
static void ConcurrentTests(NSString *origin) {
    Control(@{@"certificate":@"a",@"document":@"A",@"delay":@0.3});
    TestController *c=[[TestController alloc] initWithKey:fixtures[@"anchor"]];
    c.testDirectory=[work stringByAppendingPathComponent:@"concurrent"];
    [c setValue:[^{ return Now(); } copy] forKey:@"clock"];
    NSUInteger before=KeyHits();
    [c configureURL:origin appID:@"app" token:@"APP-TOKEN"];
    for (int i=0;i<20;i++) [c refresh];
    // The first ordinary request waits asynchronously for the single bootstrap.
    __block BOOL done=NO; __block NSError *error=nil;
    [c send:[NSURLRequest requestWithURL:[NSURL URLWithString:[origin stringByAppendingString:@"/ordinary"]]] completion:^(NSData *d,NSURLResponse *r,NSError *e){done=YES;error=e;}];
    CHECK(!done); Wait(^BOOL {return done;}); CHECK(!error); CHECK(KeyHits()==before+1);
    // Change app while a previous key fetch is in flight. Old completion cannot
    // supply the new configuration. Cancellation does not emit two callbacks.
    before=KeyHits(); Sync(c,^{[c setValue:nil forKey:@"nextRefresh"];}); [c refresh];
    Wait(^BOOL{return KeyHits()>before;});
    [c configureURL:origin appID:@"new-app" token:@"NEW-TOKEN"];
    CHECK(!Send(c,origin));
    __block NSString *app=nil; Sync(c,^{app=[c valueForKey:@"appID"];}); CHECK([app isEqual:@"new-app"]);
    [c configureURL:@"https://different.invalid" appID:@"app" token:@"TOKEN"];
    CHECK(Send(c,origin)); [c invalidate];
    NSLog(@"Concurrent refresh/configuration checks passed");
}
#if TARGET_OS_IPHONE
@interface TPBaseRequest (TestTrust)
- (void)verifyAuthChallengeTrust:(NSURLAuthenticationChallenge *)challenge;
@end
@interface LauncherRequest : TPBaseRequest
@property NSString *testOrigin;
@end
@implementation LauncherRequest
- (NSMutableURLRequest *)createRequest { return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self.testOrigin stringByAppendingString:@"/ordinary"]]]; }
- (void)verifyAuthChallengeTrust:(NSURLAuthenticationChallenge *)challenge {
    if (challenge.protectionSpace.serverTrust) {
        NSData *der=[NSData dataWithContentsOfFile:[work stringByAppendingPathComponent:@"root.der"]];
        SecCertificateRef cert=SecCertificateCreateWithData(NULL,(__bridge CFDataRef)der);
        SecTrustSetAnchorCertificates(challenge.protectionSpace.serverTrust,(__bridge CFArrayRef)@[(__bridge id)cert]);
        SecTrustSetAnchorCertificatesOnly(challenge.protectionSpace.serverTrust,YES); CFRelease(cert);
    }
    [super verifyAuthChallengeTrust:challenge];
}
@end
static void LauncherTests(NSString *origin) {
    Control(@{@"certificate":@"a",@"document":@"A"});
    TPRequestLauncher *launcher=[TPRequestLauncher new];
    TestController *controller=Controller(@"launcher",origin);
    for (NSNumber *remote in @[@NO,@YES]) {
        launcher.remotePinning=remote.boolValue ? controller : nil;
        LauncherRequest *r=[LauncherRequest new]; r.testOrigin=origin; r.requestLauncher=launcher;
        __block BOOL done=NO; __block NSUInteger calls=0; __block NSError *error=nil;
        r.onComplete=^(NSDictionary *d){CHECK(NSThread.isMainThread);done=YES;calls++;};
        r.onError=^(NSError *e){done=YES;calls++;error=e;};
        [r start]; Wait(^BOOL{return done;}); CHECK(!error); CHECK(calls==1);
        CHECK([[launcher valueForKey:@"activeRequests"] count]==0);
    }
    TwinPushManager *manager=[TwinPushManager new];
    CHECK([manager enableCertificatePinning:@"invalid"]!=nil);
    CHECK([manager enableCertificatePinning:fixtures[@"anchor"]]==nil);
    CHECK([manager enableCertificatePinning:fixtures[@"anchor"]]==nil);
    [controller invalidate];
    NSLog(@"iOS public API and real request launcher checks passed");
}
#endif
static void RestartTests(void) {
    TPRemotePinning *c=[[TPRemotePinning alloc] initWithKey:fixtures[@"anchor"]];
    Sync(c,^{
        [c setValue:@"localhost" forKey:@"host"]; [c setValue:@"https://localhost" forKey:@"origin"]; [c setValue:@"app" forKey:@"appID"];
        [c setValue:[NSURL fileURLWithPath:[work stringByAppendingPathComponent:@"persistent.plist"]] forKey:@"storeURL"];
        [c setValue:[NSMutableDictionary dictionary] forKey:@"records"]; [c setValue:[^{return Now();} copy] forKey:@"clock"];
        [c loadCache]; CHECK([c usable]);
        NSDictionary *key=[TPPinningProtocol authenticateKey:JSON(fixtures[@"key"]) integrationKey:fixtures[@"anchor"] hostname:@"localhost" error:nil];
        CHECK(![c accept:JSON(fixtures[@"A"]) keyData:JSON(fixtures[@"key"]) key:key]);
    }); [c invalidate];
    NSLog(@"Fresh-process persistent rollback checks passed");
}
static int RunTests(NSArray<NSString *> *args) { @autoreleasepool {
    CHECK(args.count>=3); work=args[1];
    fixtures=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[work stringByAppendingPathComponent:@"fixtures.json"]] options:0 error:nil];
    if (args.count>3) RestartTests();
    else {
        NSDictionary *vector=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:args[2]] options:0 error:nil];
        ProtocolTests(vector); PersistenceTests();
        NSString *port=[NSString stringWithContentsOfFile:[work stringByAppendingPathComponent:@"port"] encoding:NSUTF8StringEncoding error:nil];
        NSString *origin=[@"https://localhost:" stringByAppendingString:port];
        TransportTests(origin); ConcurrentTests(origin); DeliveryAndStorageRegressions(origin);
#if TARGET_OS_IPHONE
        LauncherTests(origin);
#endif
    }
    NSLog(@"PASS: %lu checks",(unsigned long)checks);
    [@"PASS" writeToFile:[work stringByAppendingPathComponent:@"result"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
} return 0; }
#if TARGET_OS_IPHONE
@interface TestAppDelegate : UIResponder <UIApplicationDelegate> @end
@implementation TestAppDelegate
- (void)runTests { exit(RunTests(NSProcessInfo.processInfo.arguments)); }
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    [self performSelector:@selector(runTests) withObject:nil afterDelay:0]; return YES;
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(TestAppDelegate.class)); } }
#else
int main(int argc,const char **argv) { return RunTests(NSProcessInfo.processInfo.arguments); }
#endif
