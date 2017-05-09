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

- (UIImage*)cg_rotatedImageWithCorrectOrientation;

- (UIImage*)cg_rotatedImageByRotation:(CCCImageRotation)rotation;

- (UIImage*)cg_croppedImageInRect:(CGRect)rect;

- (UIImage*)cg_scaledImageWithScale:(CGFloat)scale;

- (UIImage*)cg_scaledImageToFitBoundingSize:(CGSize)boundingSize;

- (UIImage*)cg_scaledImageToFillBoundingSize:(CGSize)boundingSize;

@end


@interface UIImage (CCCGIFReader)

+ (UIImage *)animatedImageWithGIFData:(NSData *)data;

+ (UIImage *)animatedImageWithGIFURL:(NSURL *)URL;

@end

@interface UIImage (CIProcessor)

- (UIImage *)ci_rotatedImageWithCorrectOrientation;

- (UIImage *)ci_rotatedImageByRotation:(CCCImageRotation)rotation;

- (UIImage *)ci_croppedImageInRect:(CGRect)rect;

- (UIImage *)ci_scaledImageWithScale:(CGFloat)scale;

- (UIImage *)ci_scaledImageToFitBoundingSize:(CGSize)boundingSize;

- (UIImage *)ci_scaledImageToFillBoundingSize:(CGSize)boundingSize;

@end
