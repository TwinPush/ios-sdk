//
//  TCRequestLauncher.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 08/10/12.
//  Copyright (c) 2012 TwinCoders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPBaseRequest.h"

/** @brief Object that will handle the launch of the service requests **/
@interface TPRequestLauncher : NSObject <TPRequestEndDelegate>

@property (nonatomic, assign, getter=isAllowUnsafeCertificate) BOOL allowUnsafeCertificate;

/** @brief If not null, the request will validate the SSL certificate chain names using the list of certificate
 * names provided from (starting from the leaf certificate and ending with the root). The request will fail with
 * a generic error if the certificate names don't match */
@property (nonatomic, strong) NSArray* expectedCertNames;

/** @brief Launches the selected request */
-(void)launchRequest:(TPBaseRequest*)request;

/** @brief Cancel the selected request */
- (void)cancelRequest:(TPBaseRequest*)request;

@end
