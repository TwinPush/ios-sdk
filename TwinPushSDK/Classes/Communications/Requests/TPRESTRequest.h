//
//  TPRESTRequest.h
//  TwinPushSDK
//
//  Created by Alex Gutiérrez on 16/11/12.
//  Copyright (c) 2012 TwinCoders S.L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPBaseRequest.h"

extern NSString* const kSegmentParamsSeparator;

@interface TPRESTRequest : TPBaseRequest

/** @brief Base URL where the request parameters will be concatenated */
@property (nonatomic, strong) NSString* baseServerUrl;

/** @brief Name of the resource to be accessed */
@property (nonatomic, strong) NSString* resource;

/** @brief Segment parameters */
@property (nonatomic, strong) NSMutableArray* segmentParams;

/** @brief Includes a paramater to be included in URL as a segment */
-(void) addSegmentParam:(NSString*)segmentParam;

/** @brief Creates the String from the segment parameters to be concatenated to server URL */
-(NSString*) createSegmentParamsString;

/** @brief Creates the String for the given segment parameters */
-(NSString*) stringForSegmentParams:(NSArray*)params;

/** @brief Creates the parameters query string to be concatenated to the URL after segmented params string */
-(NSString*) createParametersQueryString;

/** @brief Creates the key-value pair string to be included in url query string */
-(NSString*) queryStringForParameter:(TPRequestParam*)requestParam;

/** @brief Returns the body content for the given request */
-(NSString*) createBodyContent;

@end
