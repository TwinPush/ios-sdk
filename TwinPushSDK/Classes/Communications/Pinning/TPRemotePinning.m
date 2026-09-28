#import "TPRemotePinning.h"
#import "TPPinnedHTTP.h"
#import "TPPinningProtocol.h"
#import <errno.h>
#import <fcntl.h>
#import <sys/stat.h>
#import <unistd.h>

static const NSUInteger TPMaximumStoredPinningBytes = 1024 * 1024;

@interface TPPinningCall ()
@property (atomic) BOOL cancelled;
@property (atomic) TPPinnedHTTP *operation;
@end
@implementation TPPinningCall
- (void)cancel { @synchronized(self) { self.cancelled=YES; [self.operation cancel]; } }
@end

@interface TPRemotePinning ()
@property NSString *integrationKey;
@property NSString *host;
@property NSString *origin;
@property NSString *appID;
@property NSString *token;
@property NSURL *storeURL;
@property NSMutableDictionary *records;
@property NSDictionary *document;
@property NSData *keyData;
@property NSData *documentData;
@property dispatch_queue_t queue;
@property NSOperationQueue *delegateQueue;
@property NSUInteger generation;
// Caller-side revision fences queued main-thread callbacks immediately. The
// remaining mutable state belongs to queue, including activeRevision.
@property (atomic) NSUInteger deliveryRevision;
@property (atomic) NSUInteger activeRevision;
@property (nonatomic, copy) NSArray *requestedConfiguration;
@property BOOL invalidated;
@property BOOL refreshing;
@property BOOL storageFailed;
@property NSUInteger failures;
@property NSDate *nextRefresh;
@property NSMutableArray *waiting;
@property NSMutableSet *operations;
@property NSMutableSet *ordinaryOperations;
@property NSDate *lastPinRefresh;
@property NSError *lastError;
@property (nonatomic, copy) NSDate *(^clock)(void);
@end
@implementation TPRemotePinning
+ (BOOL)validIntegrationKey:(NSString *)key { return [TPPinningProtocol validIntegrationKey:key]; }
- (instancetype)initWithKey:(NSString *)key {
    if ((self=[super init])) {
        _integrationKey=[key copy];
        static dispatch_queue_t sharedQueue; static dispatch_once_t once;
        dispatch_once(&once, ^{ sharedQueue=dispatch_queue_create("com.twinpush.pinning",DISPATCH_QUEUE_SERIAL); });
        _queue=sharedQueue;
        _delegateQueue=[NSOperationQueue new]; _delegateQueue.maxConcurrentOperationCount=1; _delegateQueue.underlyingQueue=_queue;
        _waiting=[NSMutableArray array]; _operations=[NSMutableSet set]; _ordinaryOperations=[NSMutableSet set]; _clock=^{ return [NSDate date]; };
    }
    return self;
}
- (void)invalidate {
    @synchronized (self) { self.deliveryRevision++; }
    dispatch_async(self.queue, ^{ self.invalidated=YES; self.generation++; [self cancelOperations]; [self finishWaiting]; });
}
- (void)cancelOperations { for (TPPinnedHTTP *op in self.operations) [op cancel]; [self.operations removeAllObjects]; [self.ordinaryOperations removeAllObjects]; }
- (void)configureURL:(NSString *)url appID:(NSString *)appID token:(NSString *)token {
    // Snapshot mutable NSString arguments before returning to the caller.
    url=[url copy]; appID=[appID copy]; token=[token copy];
    NSArray *configuration=@[url ?: NSNull.null, appID ?: NSNull.null, token ?: NSNull.null];
    NSUInteger revision;
    @synchronized (self) {
        if (![self.requestedConfiguration isEqual:configuration]) {
            self.requestedConfiguration=configuration;
            self.deliveryRevision++;
        }
        revision=self.deliveryRevision;
    }
    dispatch_async(self.queue, ^{
        if (self.invalidated || revision != self.deliveryRevision) return;
        if (self.activeRevision == revision) { [self beginRefresh]; return; }
        NSURLComponents *c=url ? [NSURLComponents componentsWithString:url] : nil;
        NSString *origin=nil;
        if ([c.scheme isEqual:@"https"] && c.host.length && !c.user && !c.password && !c.query && !c.fragment && c.URL && (!c.port || (c.port.integerValue > 0 && c.port.integerValue <= 65535))) {
            origin=[NSString stringWithFormat:@"https://%@%@",c.host,c.port ? [@":" stringByAppendingString:c.port.stringValue] : @""];
        }
        self.generation++; self.activeRevision=revision;
        [self cancelOperations]; self.refreshing=NO; self.document=nil;
        self.storeURL=nil; self.keyData=nil; self.documentData=nil; self.lastPinRefresh=nil; self.lastError=nil;
        self.origin=origin; self.host=c.host; self.appID=[appID copy]; self.token=[token copy];
        self.failures=0; self.nextRefresh=nil; self.storageFailed=NO; self.records=[NSMutableDictionary dictionary];
        if (origin) {
            NSURL *dir=[self storageDirectory];
            NSError *e=nil;
            if (![[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&e]) self.storageFailed=YES;
            self.storeURL=[dir URLByAppendingPathComponent:[TPPinningHex(TPPinningSHA256([self.host dataUsingEncoding:NSUTF8StringEncoding])) stringByAppendingString:@".plist"]];
            [self loadCache];
        }
        [self finishWaiting]; [self beginRefresh];
    });
}
- (TPPinnedHTTP *)newOperation { return [TPPinnedHTTP new]; }
- (NSURL *)storageDirectory {
    NSURL *base=[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    return [base URLByAppendingPathComponent:@"TwinPushCertificatePins" isDirectory:YES];
}
- (NSDictionary *)verifiedRecord:(NSDictionary *)r environment:(NSString *)environment {
    if (![r isKindOfClass:NSDictionary.class] || ![r[@"key"] isKindOfClass:NSData.class] ||
        ![r[@"document"] isKindOfClass:NSData.class] || ![r[@"anchor"] isKindOfClass:NSString.class]) return nil;
    NSDictionary *key=[TPPinningProtocol authenticateKey:r[@"key"] integrationKey:r[@"anchor"] hostname:self.host error:nil];
    NSDictionary *document=key ? [TPPinningProtocol verifyDocument:r[@"document"] authenticatedKey:key now:[NSDate distantPast] error:nil] : nil;
    return [document[@"environment"] isEqual:environment] ? document : nil;
}
- (NSError *)unavailableError {
    NSMutableDictionary *info=[@{NSLocalizedDescriptionKey:@"No current verified pinset for this TwinPush configuration"} mutableCopy];
    if (self.lastError) info[NSUnderlyingErrorKey]=self.lastError;
    return [NSError errorWithDomain:TPPinningErrorDomain code:4 userInfo:info];
}
- (BOOL)mergePersistedRecords {
    // Only ENOENT means a fresh installation. EACCES (including protected data
    // before unlock), a directory or a symlink must not erase the rollback floor.
    if (!self.storeURL.isFileURL) return NO;
    int descriptor=open(self.storeURL.fileSystemRepresentation, O_RDONLY | O_NOFOLLOW | O_NONBLOCK);
    if (descriptor < 0) return errno == ENOENT;
    struct stat attributes;
    if (fstat(descriptor, &attributes) != 0 || !S_ISREG(attributes.st_mode) ||
        attributes.st_size < 0 || attributes.st_size > TPMaximumStoredPinningBytes) {
        close(descriptor);
        return NO;
    }
    NSMutableData *raw=[NSMutableData data];
    uint8_t buffer[4096];
    BOOL readable=YES;
    for (;;) {
        ssize_t count=read(descriptor, buffer, sizeof(buffer));
        if (count < 0 && errno == EINTR) continue;
        if (count < 0) { readable=NO; break; }
        if (!count) break;
        if ((NSUInteger)count > TPMaximumStoredPinningBytes - raw.length) { readable=NO; break; }
        [raw appendBytes:buffer length:(NSUInteger)count];
    }
    close(descriptor);
    if (!readable) return NO;
    id records=raw ? [NSPropertyListSerialization propertyListWithData:raw options:NSPropertyListMutableContainers format:nil error:nil] : nil;
    if (![records isKindOfClass:NSDictionary.class]) return NO;
    // The queue is shared by all controllers. Re-read the on-disk high-water
    // marks at commit time, including after a different manager/key accepted data.
    NSMutableDictionary *merged=[self.records mutableCopy];
    for (NSString *env in records) {
        NSDictionary *document=[self verifiedRecord:records[env] environment:env];
        if (!document) return NO;
        NSDictionary *prior=merged[env] ? [self verifiedRecord:merged[env] environment:env] : nil;
        if (prior) {
            NSComparisonResult order=[document[@"version"] compare:prior[@"version"]];
            if (order==NSOrderedSame && ![document[@"canonical"] isEqual:prior[@"canonical"]]) return NO;
            if (order==NSOrderedAscending) continue; // retain in-memory high-water mark
        }
        merged[env]=records[env];
    }
    self.records=merged;
    return YES;
}
- (void)loadCache {
    if (![self mergePersistedRecords]) { self.storageFailed=YES; self.document=nil; self.lastError=TPPinningError(12,@"Cannot read or revalidate persisted certificate pins"); return; }
    for (NSString *env in self.records) {
        NSDictionary *r=self.records[env];
        NSDictionary *d=[self verifiedRecord:r environment:env];
        if ([r[@"appID"] isEqual:self.appID] && [r[@"origin"] isEqual:self.origin] && [r[@"anchor"] isEqual:self.integrationKey] && [d[@"expiry"] compare:self.clock()] == NSOrderedDescending) {
            self.document=d; self.keyData=r[@"key"]; self.documentData=r[@"document"];
        }
    }
    [self scheduleExpiry];
}
- (BOOL)usable { return self.activeRevision == self.deliveryRevision && !self.invalidated && !self.storageFailed && self.document && [self.document[@"expiry"] compare:self.clock()] == NSOrderedDescending; }
- (void)refresh { dispatch_async(self.queue, ^{ [self beginRefresh]; }); }
- (void)finishWaiting {
    NSArray *waiting=[self.waiting copy]; [self.waiting removeAllObjects];
    for (void (^block)(void) in waiting) block();
}
- (void)fetch:(NSString *)path generation:(NSUInteger)generation completion:(void (^)(NSData *,NSError *))completion {
    // Only this private method creates bootstrap requests, always exact GET URLs.
    NSCharacterSet *safe=[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"];
    NSString *app=[self.appID stringByAddingPercentEncodingWithAllowedCharacters:safe];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v2/apps/%@/certificate_pins%@",self.origin,app,path]];
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:url]; r.HTTPMethod=@"GET";
    [r setValue:self.token forHTTPHeaderField:@"X-TwinPush-REST-API-Token"];
    TPPinnedHTTP *op=[self newOperation]; [self.operations addObject:op];
    NSUInteger revision=self.activeRevision;
    __weak TPPinnedHTTP *weakOp=op;
    op.completion=^(NSData *data,NSURLResponse *response,NSError *error) {
        [self.operations removeObject:weakOp];
        if (self.invalidated || generation!=self.generation || revision!=self.deliveryRevision) return;
        NSInteger status=[(NSHTTPURLResponse *)response statusCode];
        NSError *failure=error;
        if (!failure && status!=200) {
            failure=[NSError errorWithDomain:TPPinningErrorDomain code:11 userInfo:@{
                NSLocalizedDescriptionKey:@"Certificate pinning bootstrap HTTP error",
                @"HTTPStatusCode":@(status)
            }];
        }
        if (failure) self.lastError=failure;
        completion(data,failure);
    };
    [op start:r limit:16384 queue:self.delegateQueue];
}
- (BOOL)accept:(NSData *)data keyData:(NSData *)keyData key:(NSDictionary *)key {
    NSError *verificationError=nil;
    NSDictionary *d=[TPPinningProtocol verifyDocument:data authenticatedKey:key now:self.clock() error:&verificationError];
    if (!d) { self.lastError=verificationError; return NO; }
    if (self.storageFailed) return NO;
    if (![self mergePersistedRecords]) {
        self.storageFailed=YES;
        self.lastError=TPPinningError(12,@"Cannot read or revalidate persisted certificate pins");
        return NO;
    }
    NSString *env=d[@"environment"]; NSDictionary *old=self.records[env];
    if (old) {
        NSDictionary *oldKey=[TPPinningProtocol authenticateKey:old[@"key"] integrationKey:old[@"anchor"] hostname:self.host error:nil];
        NSDictionary *prior=[TPPinningProtocol verifyDocument:old[@"document"] authenticatedKey:oldKey now:[NSDate distantPast] error:nil];
        if (!prior || [d[@"version"] compare:prior[@"version"]]==NSOrderedAscending || ([d[@"version"] isEqual:prior[@"version"]] && ![d[@"canonical"] isEqual:prior[@"canonical"]])) {
            self.lastError=TPPinningError(7,@"Signed pinset attempts rollback or reuses a version with different content");
            return NO;
        }
    }
    NSMutableDictionary *next=[self.records mutableCopy];
    next[env]=@{@"anchor":self.integrationKey,@"key":keyData,@"document":data,@"appID":self.appID,@"origin":self.origin};
    NSError *storageError=nil;
    NSData *stored=[NSPropertyListSerialization dataWithPropertyList:next format:NSPropertyListBinaryFormat_v1_0 options:0 error:&storageError];
    if (!stored || stored.length > TPMaximumStoredPinningBytes || ![stored writeToURL:self.storeURL options:NSDataWritingAtomic error:&storageError]) {
        NSMutableDictionary *info=[@{NSLocalizedDescriptionKey:@"Cannot persist verified certificate pins"} mutableCopy];
        if (storageError) info[NSUnderlyingErrorKey]=storageError;
        self.lastError=[NSError errorWithDomain:TPPinningErrorDomain code:12 userInfo:info];
        return NO;
    }
    if (self.document && ![self.document[@"canonical"] isEqual:d[@"canonical"]]) {
        for (TPPinnedHTTP *op in self.ordinaryOperations) [op cancel];
    }
    self.records=next; self.document=d; self.keyData=keyData; self.documentData=data;
    [self scheduleExpiry];
    return YES;
}
- (void)scheduleExpiry {
    if (!self.document) return;
    NSDictionary *snapshot=self.document; NSUInteger generation=self.generation;
    NSTimeInterval delay=MAX(0,[snapshot[@"expiry"] timeIntervalSinceDate:self.clock()]);
    __weak typeof(self) weakSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(MIN(delay,3600)*NSEC_PER_SEC)),self.queue,^{
        TPRemotePinning *s=weakSelf;
        if (!s || s.invalidated || s.generation!=generation || s.document!=snapshot) return;
        if (![s usable]) { for (TPPinnedHTTP *op in s.ordinaryOperations) [op cancel]; s.nextRefresh=nil; [s beginRefresh]; }
        else [s scheduleExpiry];
    });
}
- (void)beginRefresh {
    if (self.activeRevision != self.deliveryRevision || self.invalidated || self.refreshing || !self.origin || !self.appID.length || !self.token.length) return;
    if (self.nextRefresh && [self.nextRefresh compare:self.clock()]==NSOrderedDescending) return;
    if (self.storageFailed) {
        // Protected data may become readable after unlock. Revalidate without
        // deleting either the file or the in-memory rollback floor.
        self.storageFailed=![[NSFileManager defaultManager] createDirectoryAtURL:[self.storeURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        if (!self.storageFailed) [self loadCache];
        if (self.storageFailed) {
            self.nextRefresh=[self.clock() dateByAddingTimeInterval:30];
            return;
        }
    }
    self.refreshing=YES; NSUInteger generation=self.generation;
    [self fetch:@"/verification_key" generation:generation completion:^(NSData *keyData,NSError *error) {
        NSError *verificationError=nil;
        NSDictionary *key=error ? nil : [TPPinningProtocol authenticateKey:keyData integrationKey:self.integrationKey hostname:self.host error:&verificationError];
        if (!key) {
            self.lastError=error ?: verificationError;
            [self refreshed:NO generation:generation];
            return;
        }
        [self fetch:@"" generation:generation completion:^(NSData *data,NSError *error) {
            [self refreshed:!error && [self accept:data keyData:keyData key:key] generation:generation];
        }];
    }];
}
- (void)refreshed:(BOOL)success generation:(NSUInteger)generation {
    self.refreshing=NO;
    if (success) self.lastError=nil;
    self.failures=success ? 0 : self.failures+1;
    NSTimeInterval delay=success ? MAX(30,MIN(3600,[self.document[@"expiry"] timeIntervalSinceDate:self.clock()]-300)) : MIN(300,pow(2,MIN(self.failures,8)));
    self.nextRefresh=[self.clock() dateByAddingTimeInterval:delay];
    [self finishWaiting];
    // At most three automatic attempts in a failed burst. Later requests/resume
    // may retry after the backoff, never replaying an ordinary operation.
    if (success || self.failures<3) {
        __weak typeof(self) weakSelf=self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(delay*NSEC_PER_SEC)),self.queue,^{
            TPRemotePinning *s=weakSelf; if (s && s.generation==generation) [s beginRefresh];
        });
    }
}
- (TPPinningCall *)send:(NSURLRequest *)request completion:(void (^)(NSData *,NSURLResponse *,NSError *))completion {
    request=[request copy];
    TPPinningCall *call=[TPPinningCall new];
    NSUInteger revision=self.deliveryRevision;
    dispatch_async(self.queue, ^{
        NSUInteger generation=self.generation;
        __block NSDictionary *admittedDocument=nil;
        void (^deliver)(NSData *,NSURLResponse *,NSError *)=^(NSData *d,NSURLResponse *r,NSError *e) {
            dispatch_async(dispatch_get_main_queue(),^{
                if (call.cancelled) return;
                // A completion can wait on the main queue while configuration,
                // pinset or time changes. Recheck at the actual callback boundary.
                NSError *failure=e;
                if (revision != self.deliveryRevision || (admittedDocument &&
                    (![self usable] || ![admittedDocument[@"canonical"] isEqual:self.document[@"canonical"]]))) {
                    failure=TPPinningError(4,@"Pinning configuration changed or expired before callback delivery");
                }
                completion(failure ? nil : d, failure ? nil : r, failure);
            });
        };
        void (^start)(void)=^{
            if (call.cancelled) return;
            NSURLComponents *u=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
            NSString *origin=[NSString stringWithFormat:@"%@://%@%@",u.scheme,u.host,u.port ? [@":" stringByAppendingString:u.port.stringValue] : @""];
            if (revision!=self.deliveryRevision || generation!=self.generation || ![self usable] || ![origin isEqual:self.origin] || u.user || u.password) { deliver(nil,nil,[self unavailableError]); return; }
            NSDictionary *snapshot=self.document;
            admittedDocument=snapshot;
            TPPinnedHTTP *op=[self newOperation];
            op.verifyTrust=^BOOL(SecTrustRef trust,NSString *host) {
                if (revision!=self.deliveryRevision || generation!=self.generation || ![self usable] || ![host isEqual:self.host] || ![snapshot[@"canonical"] isEqual:self.document[@"canonical"]]) return NO;
                NSData *spki=TPPinningCertificateSPKI(SecTrustGetCertificateAtIndex(trust,0));
                NSString *pin=spki ? [@"sha256/" stringByAppendingString:[TPPinningSHA256(spki) base64EncodedStringWithOptions:0]] : nil;
                BOOL matches=pin && [self.document[@"pins"] containsObject:pin];
                if (!matches) {
                    if (!self.lastPinRefresh || [self.clock() timeIntervalSinceDate:self.lastPinRefresh]>=30) {
                        self.lastPinRefresh=self.clock(); self.nextRefresh=nil; [self beginRefresh];
                    }
                    return NO;
                }
                return YES;
            };
            __weak TPPinnedHTTP *weakOp=op;
            op.completion=^(NSData *data,NSURLResponse *response,NSError *error) {
                [self.operations removeObject:weakOp]; [self.ordinaryOperations removeObject:weakOp];
                if (revision!=self.deliveryRevision || generation!=self.generation || ![self usable] || ![snapshot[@"canonical"] isEqual:self.document[@"canonical"]]) error=TPPinningError(4,@"Pinning configuration changed or expired during request");
                deliver(data,response,error);
            };
            @synchronized(call) { if (call.cancelled) return; call.operation=op; [self.operations addObject:op]; [self.ordinaryOperations addObject:op]; [op start:request limit:16*1024*1024 queue:self.delegateQueue]; }
        };
        [self beginRefresh];
        if (![self usable] && self.refreshing) {
            [self.waiting addObject:[start copy]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,25*NSEC_PER_SEC),self.queue,^{
                if ([self.waiting containsObject:start]) { [self.waiting removeObject:start]; deliver(nil,nil,TPPinningError(5,@"Timed out waiting for verified certificate pins")); }
            });
        } else start();
    });
    return call;
}
@end
