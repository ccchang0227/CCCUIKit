//
//  UIImage+CCCProcessor.m
//
//  Created by CHIEN-HSU WU on 2015/11/16.
//  Copyright © 2015年 CHIEN-HSU WU. All rights reserved.
//


#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import "UIImage+CCCProcessor.h"


@implementation UIImage (CCCProcessor)

- (UIImage*)rotatedImageWithCorrectOrientation {
    if (!self) return nil;
    
    size_t width = self.size.width;
    size_t height = self.size.height;
    
    size_t bytePerPixel = CGImageGetBitsPerPixel(self.CGImage)/8;
    
    size_t totalByteCount = width*height*bytePerPixel;
    
    void *bitmapData = malloc(totalByteCount);
    memset(bitmapData, 0, totalByteCount);
    if (bitmapData == NULL) {
        return self;
    }
    
    CGContextRef context = CGBitmapContextCreate (bitmapData,
                                                  width,
                                                  height,
                                                  CGImageGetBitsPerComponent(self.CGImage),
                                                  width*bytePerPixel,
                                                  CGImageGetColorSpace(self.CGImage),
                                                  CGImageGetAlphaInfo(self.CGImage)|CGImageGetBitmapInfo(self.CGImage));
    
    if (context == NULL) {
        free(bitmapData);
        bitmapData = NULL;
        
        return self;
    }
    
    CGContextSaveGState(context);
    switch (self.imageOrientation) {
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
            CGContextRotateCTM(context, -M_PI_2);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, -CGRectGetWidth(bounds), 0);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRightMirrored: {
            CGContextRotateCTM(context, M_PI_2);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored: {
            CGContextRotateCTM(context, M_PI);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, -CGRectGetWidth(bounds), -CGRectGetHeight(bounds));
            break;
        }
        default:
            break;
    }
    switch (self.imageOrientation) {
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored: {
            CGContextScaleCTM(context, 1, -1);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored: {
            CGContextScaleCTM(context, 1, -1);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        default:
            break;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage)), self.CGImage);
    CGContextRestoreGState(context);
    
    CGImageRef cgImageDest = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    context = NULL;
    
    UIImage *destImage = [UIImage imageWithCGImage:cgImageDest scale:self.scale orientation:UIImageOrientationUp];
    
    free(bitmapData);
    bitmapData = NULL;
    
    CGImageRelease(cgImageDest);
    cgImageDest = NULL;
    
    return destImage;
}

- (UIImage*)rotatedImageByRotation:(CCCImageRotation)rotation {
    if (!self) return nil;
    if (rotation != CCCImageRotation90 &&
        rotation != CCCImageRotation180 &&
        rotation != CCCImageRotation270) return self;
    
    size_t bytePerPixel = CGImageGetBitsPerPixel(self.CGImage)/8;
    
    size_t totalByteCount = self.size.width*self.size.height*bytePerPixel;
    
    void *bitmapData = malloc(totalByteCount);
    memset(bitmapData, 0, totalByteCount);
    if (bitmapData == NULL) {
        return self;
    }
    
    size_t imageWidth = self.size.width;
    size_t imageHeight = self.size.height;
    if (rotation%180 == 90) {
        imageWidth = self.size.height;
        imageHeight = self.size.width;
    }
    
    CGContextRef context = CGBitmapContextCreate (bitmapData,
                                                  imageWidth,
                                                  imageHeight,
                                                  CGImageGetBitsPerComponent(self.CGImage),
                                                  imageWidth*bytePerPixel,
                                                  CGImageGetColorSpace(self.CGImage),
                                                  CGImageGetBitmapInfo(self.CGImage));
    
    if (context == NULL) {
        free(bitmapData);
        bitmapData = NULL;
        
        return self;
    }
    
    CGContextSaveGState(context);
    switch (rotation) {
        case CCCImageRotation90: {
            CGContextRotateCTM(context, -M_PI_2);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, -CGRectGetWidth(bounds), 0);
            break;
        }
        case CCCImageRotation270: {
            CGContextRotateCTM(context, M_PI_2);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        case CCCImageRotation180: {
            CGContextRotateCTM(context, M_PI);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, -CGRectGetWidth(bounds), -CGRectGetHeight(bounds));
            break;
        }
        default:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored: {
            CGContextScaleCTM(context, 1, -1);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored: {
            CGContextScaleCTM(context, 1, -1);
            CGRect bounds = CGContextGetClipBoundingBox(context);
            CGContextTranslateCTM(context, 0, -CGRectGetHeight(bounds));
            break;
        }
        default:
            break;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage)), self.CGImage);
    CGContextRestoreGState(context);
    
    CGImageRef cgImageDest = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    context = NULL;
    
    free(bitmapData);
    bitmapData = NULL;
    
    UIImage *destImage = [UIImage imageWithCGImage:cgImageDest scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(cgImageDest);
    cgImageDest = NULL;
    
    return destImage;
}

- (UIImage*)croppedImageInRect:(CGRect)rect {
    if (!self ||
        CGRectEqualToRect(rect, CGRectZero) ||
        CGRectIsInfinite(rect) ||
        CGRectIsEmpty(rect) ||
        CGRectIsNull(rect)) return self;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (self.imageOrientation) {
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -self.size.width, 0);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -self.size.height);
            break;
        case UIImageOrientationDown:
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI), -self.size.width, -self.size.height);
            break;
        default:
            break;
    }
    transform = CGAffineTransformScale(transform, self.scale, self.scale);
    CGRect rectTransformed = CGRectApplyAffineTransform(rect, transform);
    
    rectTransformed.origin.x = roundf(rectTransformed.origin.x);
    rectTransformed.origin.y = roundf(rectTransformed.origin.y);
    rectTransformed.size.width = roundf(rectTransformed.size.width);
    rectTransformed.size.height = roundf(rectTransformed.size.height);
    
    CGImageRef cgImage = CGImageCreateWithImageInRect(self.CGImage, rectTransformed);
    if (cgImage == NULL) {
        return self;
    }
    
    UIImage *destImage = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(cgImage);
    cgImage = NULL;
    
    return destImage;
}

- (UIImage*)scaledImageWithScale:(CGFloat)scale {
    if (!self) return nil;
    if (scale <= 0.0f || scale >= 1000.0f) return self;
    
    size_t bytePerPixel = CGImageGetBitsPerPixel(self.CGImage)/8;
    
    size_t imageWidth = CGImageGetWidth(self.CGImage)*scale;
    size_t imageHeight = CGImageGetHeight(self.CGImage)*scale;
    
    size_t totalByteCount = imageWidth*imageHeight*bytePerPixel;
    
    void *bitmapData = malloc(totalByteCount);
    memset(bitmapData, 0, totalByteCount);
    if (bitmapData == NULL) {
        return self;
    }
    
    CGContextRef context = CGBitmapContextCreate (bitmapData,
                                                  imageWidth,
                                                  imageHeight,
                                                  CGImageGetBitsPerComponent(self.CGImage),
                                                  imageWidth*bytePerPixel,
                                                  CGImageGetColorSpace(self.CGImage),
                                                  CGImageGetBitmapInfo(self.CGImage));
    
    if (context == NULL) {
        free(bitmapData);
        bitmapData = NULL;
        
        return self;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), self.CGImage);
    
    CGImageRef cgImageDest = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    context = NULL;
    
    free(bitmapData);
    bitmapData = NULL;
    
    UIImage *destImage = [UIImage imageWithCGImage:cgImageDest scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(cgImageDest);
    cgImageDest = NULL;
    
    return destImage;
}

- (UIImage*)scaledImageToFitBoundingSize:(CGSize)boundingSize {
    if (!self) return nil;
    if (CGSizeEqualToSize(boundingSize, CGSizeZero)) return self;
    
    CGFloat imageWidth = self.size.width;
    CGFloat imageHeight = self.size.height;
    CGFloat scale = boundingSize.width/imageWidth;
    if (scale*imageHeight > boundingSize.height) {
        scale = boundingSize.height/imageHeight;
    }
    
    return [self scaledImageWithScale:scale];
}

- (UIImage*)scaledImageToFillBoundingSize:(CGSize)boundingSize {
    if (!self) return nil;
    if (CGSizeEqualToSize(boundingSize, CGSizeZero)) return self;
    
    CGFloat imageWidth = self.size.width;
    CGFloat imageHeight = self.size.height;
    CGFloat scale = boundingSize.width/imageWidth;
    if (scale*imageHeight < boundingSize.height) {
        scale = boundingSize.height/imageHeight;
    }
    
    return [self scaledImageWithScale:scale];
}

@end


@implementation UIImage (CCCGIFReader)

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = (id) CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = (id) CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count]) {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

static UIImage *animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source) {
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count]; // in centiseconds
    createImagesAndDelays(source, count, images, delayCentiseconds);
    int const totalDurationCentiseconds = sum(count, delayCentiseconds);
    NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
    UIImage *const animation = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
    releaseImages(count, images);
    return animation;
}

static UIImage *animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceRef CF_RELEASES_ARGUMENT source) {
    if (source) {
        UIImage *const image = animatedImageWithAnimatedGIFImageSource(source);
        CFRelease(source);
        return image;
    } else {
        return nil;
    }
}

+ (UIImage *)animatedImageWithGIFData:(NSData *)data {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithData((CFTypeRef) data, NULL));
}

+ (UIImage *)animatedImageWithGIFURL:(NSURL *)URL {
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithURL((CFTypeRef) URL, NULL));
}

@end
