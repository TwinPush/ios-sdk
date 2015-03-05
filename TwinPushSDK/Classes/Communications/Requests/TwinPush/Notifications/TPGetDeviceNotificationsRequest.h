//
//  TPGetDeviceNotificationsRequest.h
//  TwinPushSDK
//
//  Created by Diego Prados on 13/12/12.
//
//

#import "TPDevice.h"
#import "TPTwinPushRequest.h"
#import "TPBaseRequest.h"
#import "TPNotificationsFilters.h"
#import "TPNotificationsPagination.h"

typedef void(^GetDeviceNotificationsResponseBlock)(NSArray* array, BOOL hasMore);

@interface TPGetDeviceNotificationsRequest : TPTwinPushRequest

/**
 @brief Constructor for CreateDeviceRequest
 @param deviceId The Device id for which we want to get the notifications
 @param filters The filters to apply in the notification search
 @param pagination The pagination to apply in the results of the notification search
 @param onComplete Block that will be executed if we obtain the notifications for the device
 @param onError Block that will be executed if the device is not correct
 */
- (id)initGetDeviceNotificationsRequestWithDeviceId:(NSString*)deviceId filters:(TPNotificationsFilters*)filters pagination:(TPNotificationsPagination*)pagination appId:(NSString*)appId onComplete:(GetDeviceNotificationsResponseBlock)onComplete onError:(TPRequestErrorBlock)onError;

@end