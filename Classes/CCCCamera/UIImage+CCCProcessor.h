//
//  UIImage+CCCProcessor.h
//
//  Created by CHIEN-HSU WU on 2015/11/16.
//  Copyright © 2015年 CHIEN-HSU WU. All rights reserved.
//


#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, CCCImageRotation) {
    CCCImageRotation90 = 90,
    CCCImageRotation180 = 180,
    CCCImageRotation270 = 270
};

typedef NS_ENUM(NSUInteger, CCCImageCombineScaleType) {
    CCCImageCombineScaleTypeScaleToFill,
    CCCImageCombineScaleTypeAscpectFill,
    CCCImageCombineScaleTypeAscpectFit
};

@interface UIImage (CCCProcessor)

- (UIImage*)rotatedImageWithCorrectOrientation;

- (UIImage*)rotatedImageByRotation:(CCCImageRotation)rotation;

- (UIImage*)croppedImageInRect:(CGRect)rect;

- (UIImage*)scaledImageWithScale:(CGFloat)scale;

- (UIImage*)scaledImageToFitBoundingSize:(CGSize)boundingSize;

- (UIImage*)scaledImageToFillBoundingSize:(CGSize)boundingSize;

@end


@interface UIImage (CCCGIFReader)

+ (UIImage *)animatedImageWithGIFData:(NSData *)data;

+ (UIImage *)animatedImageWithGIFURL:(NSURL *)URL;

@end
