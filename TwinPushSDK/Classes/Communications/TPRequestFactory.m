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

@property (nonatomic, strong) TPRequestLauncher *requestLauncher;

@end

@implementation TPRequestFactory

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        self.requestLauncher = [[TPRequestLauncher alloc] init];
    }
    return self;
}

#pragma mark - Requests

- (TPBaseRequest *)createCreateDeviceRequestWithToken:(NSString *)token deviceAlias:(NSString *)deviceAlias UDID:(NSString*)udid appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPCreateDeviceRequest alloc] initCreateDeviceRequestWithToken:token deviceAlias:deviceAlias UDID:(NSString*)udid appId:appId apiKey:apiKey onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest *)createGetDeviceNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPGetDeviceNotificationsRequest alloc] initGetDeviceNotificationsRequestWithDeviceId:deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest *)createGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPGetAliasNotificationsRequest alloc] initGetAliasNotificationsRequestWithDeviceId:deviceId pagination:pagination appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest *)createGetDeviceNotificationWithId:(NSInteger)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPGetNotificationWithIdRequest alloc] initGetDeviceNotificationWithId:notificationId deviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createDeleteNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPDeleteNotificationRequest alloc] initDeleteNotificationWithId:notificationId deviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createUpdateBadgeRequestWithCount:(NSUInteger)badgeCount forDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(UpdateBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPUpdateBadgeRequest alloc] initUpdateBadgeRequestWithCount:badgeCount forDeviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createSetCustomPropertyRequestWithName:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPSetCustomPropertyRequest alloc] initSetCustomPropertyRequestWithName:name type:type value:value deviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createReportStatisticsRequestWithCoordinate:(CLLocationCoordinate2D)coordinate deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPReportStatisticsRequest alloc] initReportStatisticsRequestWithCoordinate:coordinate deviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createOpenAppRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPOpenAppRequest alloc] initOpenAppRequestWithDeviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createCloseAppRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPCloseAppRequest alloc] initCloseAppRequestWithDeviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

- (TPBaseRequest*)createUserOpenNotificationRequestWithDeviceId:(NSString*)deviceId notificationId:(NSString*)notificationId appId:(NSString*)appId onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError {
    TPBaseRequest* request = [[TPUserOpenNotificationRequest alloc] initUserOpenNotificationRequestWithNotificationId:notificationId deviceId:deviceId appId:appId onComplete:onComplete onError:onError];
    request.requestLauncher = _requestLauncher;
    return request;
}

@end
