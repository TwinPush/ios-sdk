//
//  TPRequestFactory.m
//  TwinPushSDK
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPRequestFactory.h"
#import "TPRequestLauncher.h"

@interface TPRequestFactory()

@property (nonatomic, strong) TPRequestLauncher *tcRequestLauncher;

@end

@implementation TPRequestFactory

static TPRequestFactory *_sharedInstance;

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        self.tcRequestLauncher = [[TPRequestLauncher alloc] init];
    }
    return self;
}

#pragma mark - Shared instance

+ (TPRequestFactory*) sharedInstance {
    if (_sharedInstance == nil) {
        _sharedInstance = [[TPRequestFactory alloc] init];
    }
    return _sharedInstance;
}

#pragma mark - Requests

- (TPBaseRequest *)createCreateDeviceRequestWithToken:(NSString *)token deviceAlias:(NSString *)deviceAlias UDID:(NSString*)udid appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPCreateDeviceRequest alloc] initCreateDeviceRequestWithToken:token deviceAlias:deviceAlias UDID:(NSString*)udid appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest *)createGetDeviceNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPGetDeviceNotificationsRequest alloc] initGetDeviceNotificationsRequestWithDeviceId:deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest *)createGetDeviceNotificationWithId:(NSInteger)notificationId appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPGetNotificationWithIdRequest alloc] initGetDeviceNotificationWithId:notificationId appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createUpdateBadgeRequestWithCount:(NSUInteger)badgeCount forDeviceId:(NSString*)deviceId appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(UpdateBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPUpdateBadgeRequest alloc] initUpdateBadgeRequestWithCount:badgeCount forDeviceId:deviceId appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createSetCustomPropertyRequestWithName:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value deviceId:(NSString*)deviceId appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPSetCustomPropertyRequest alloc] initSetCustomPropertyRequestWithName:name type:type value:value deviceId:deviceId appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createReportStatisticsRequestWithCoordinate:(CLLocationCoordinate2D)coordinate deviceId:(NSString*)deviceId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPReportStatisticsRequest alloc] initReportStatisticsRequestWithCoordinate:coordinate deviceId:deviceId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createOpenAppRequestWithDeviceId:(NSString*)deviceId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPOpenAppRequest alloc] initOpenAppRequestWithDeviceId:deviceId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createCloseAppRequestWithDeviceId:(NSString*)deviceId apiKey:(NSString*)apiKey onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPCloseAppRequest alloc] initCloseAppRequestWithDeviceId:deviceId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

- (TPBaseRequest*)createUserOpenNotificationRequestWithDeviceId:(NSString*)deviceId notificationId:(NSString*)notificationId apiKey:(NSString*)apiKey onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPUserOpenNotificationRequest alloc] initUserOpenNotificationRequestWithDeviceId:deviceId notificationId:notificationId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _tcRequestLauncher;
    return request;
}

@end
