#import "TPRequestLauncher.h"

@class TPRemotePinning;

// Internal configuration only. Applications activate remote mode through
// TwinPushManager; the transport and bypass-free bootstrap are not public API.
@interface TPRequestLauncher (RemotePinning)
@property (nonatomic, strong) TPRemotePinning *remotePinning;
@end
