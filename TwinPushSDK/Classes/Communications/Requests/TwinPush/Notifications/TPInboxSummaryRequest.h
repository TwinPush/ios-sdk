//
//  TPInboxSummaryRequest.h
//  TwinPushSDK
//
//  Created by Guillermo Gutiérrez Doral on 4/6/18.
//  Copyright © 2018 TwinCoders. All rights reserved.
//

#import "TPTwinPushRequest.h"
#import "TPInboxSummary.h"

typedef void(^GetInboxSummaryResponseBlock)(TPInboxSummary*);

@interface TPInboxSummaryRequest : TPTwinPushRequest
- (id)initWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetInboxSummaryResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;
@end
