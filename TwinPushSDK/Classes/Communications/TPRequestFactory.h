//
//  TPRequestFactory.h
//  TwinPushSDK
//
//  Created by Diego Prados on 23/01/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPBaseRequest.h"
#import "TPCreateDeviceRequest.h"
#import "TPGetDeviceNotificationsRequest.h"
#import "TPGetAliasNotificationsRequest.h"
#import "TPNotificationsFilters.h"
#import "TPGetNotificationWithIdRequest.h"
#import "TPUpdateBadgeRequest.h"
#import "TPSetCustomPropertyRequest.h"
#import "TPReportStatisticsRequest.h"
#import "TPOpenAppRequest.h"
#import "TPCloseAppRequest.h"
#import "TPUserOpenNotificationRequest.h"
#import "TPDeleteNotificationRequest.h"
#import "TPInboxSummaryRequest.h"
#import <CoreLocation/CoreLocation.h>

@interface TPRequestFactory : NSObject

#pragma mark - Requests

@property (nonatomic, readonly) TPRequestLauncher* requestLauncher;

/**
 @brief Constructor for CreateDeviceRequest
 @param token Token for getting the device id
 @param deviceAlias (Optional)
 @param onComplete Block that will be executed if login is successful
 @param onError Block that will be executed if login is not successful
 */
- (TPBaseRequest*)createCreateDeviceRequestWithToken:(NSString*)token deviceAlias:(NSString*)deviceAlias UDID:(NSString*)udid appId:(NSString*)appId apiKey:(NSString*)apiKey onComplete:(CreateDeviceResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

/**
 @brief Constructor for GetDeviceNotifications
 @param device The Device for which we want to get the notifications
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest *)createGetDeviceNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

/**
 @brief Constructor for GetAliasNotifications
 @param device The Device for which we want to get the notifications
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest *)createGetAliasNotificationsRequestWithDeviceId:(NSString*)deviceId pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

/**
 @brief Constructor for GetDeviceNotificationWithId
 @param notificationId The notification's ID of the notification we are asking for
 @param onComplete Block that will be executed if we obtain the notification with the specified id
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest *)createGetDeviceNotificationWithId:(NSInteger)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetDeviceNotificationWithIdResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

/**
 @brief Constructor for TPDeleteNotificationRequest
 @param notificationId The notification's ID of the notification we are deleting
 @param onComplete Block that will be executed after a successful deletion
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest*)createDeleteNotificationWithId:(NSString*)notificationId deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(DeleteNotificationResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

/**
 @brief Constructor for TPUpdateBadgeRequest
 @param badgeCount Badge count to be stored in the server
 @param deviceId The ID of the device which is asking for the notification
 @param onComplete Block that will be executed if we obtain the notification with the specified id
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest*)createUpdateBadgeRequestWithCount:(NSUInteger)badgeCount forDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(UpdateBadgeResponse)onComplete onError:(TPRequestErrorBlock)onError;

#pragma mark Custom Properties

/**
 @brief Constructor for SetCustomPropertyRequest
 @param deviceId The Device id for which we want to get the notifications
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest*)createSetCustomPropertyRequestWithName:(NSString*)name type:(TPPropertyType)type value:(NSObject*)value deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

#pragma mark Statistics

/**
 @brief Creates a request for sending device statistics to TwinPush server
 @param coordinate Current location
 @param deviceId The Device id for which we want to get the notifications
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (TPBaseRequest*)createReportStatisticsRequestWithCoordinate:(CLLocationCoordinate2D)coordinate deviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

- (TPBaseRequest*)createOpenAppRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

- (TPBaseRequest*)createCloseAppRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(TPRequestSuccessBlock)onComplete onError:(TPRequestErrorBlock)onError;

- (TPBaseRequest*)createUserOpenNotificationRequestWithDeviceId:(NSString*)deviceId notificationId:(NSString*)notificationId appId:(NSString*)appId onComplete:(TPRequestCompleteBlock)onComplete onError:(TPRequestErrorBlock)onError;

- (TPBaseRequest*)createInboxSummaryRequestWithDeviceId:(NSString*)deviceId appId:(NSString*)appId onComplete:(GetInboxSummaryResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end
