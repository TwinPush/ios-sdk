//
//  TPStretchableImageView.m
//  TwinPushSDKDemo
//
//  Created by Diego Prados on 05/02/13.
//  Copyright (c) 2013 TwinCoders. All rights reserved.
//

#import "TPStretchableImageView.h"

@implementation TPStretchableImageView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (( self = [super initWithCoder:aDecoder] )) {
        UIImage* image = [self image];
        if (image != nil) {
            [super setImage:[self stretchImage:image]];
        }
        UIImage* highlightedImage = [self highlightedImage];
        if (highlightedImage != nil) {
            [super setHighlightedImage:[self stretchImage:highlightedImage]];
        }
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    [super setImage:[self stretchImage:image]];
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
    [super setHighlightedImage:[self stretchImage:highlightedImage]];
}

- (UIImage*)stretchImage:(UIImage*)image {
    UIImage* stretchedImage = [image stretchableImageWithLeftCapWidth:image.size.width / 2 topCapHeight:image.size.height / 2];
    return stretchedImage;
}

@end
