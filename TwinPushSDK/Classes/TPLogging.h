#import <Foundation/Foundation.h>

#ifndef TCLog
#ifdef DEBUG
#define TCLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define TCLog(...) do {} while (0)
#endif
#endif
