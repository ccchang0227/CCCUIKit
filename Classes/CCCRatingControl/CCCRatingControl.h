//
//  CCCRatingControl.h
//
//  Created by RealTouch on 2014/10/20.
//  Copyright (c) 2014年 RealTouch. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


#define kCCCRatingControlDefaultMaximumValue 5
#define kCCCRatingControlDefaultFractionNumber 1


UIKIT_EXTERN UIImage *starImage(CGSize size, UIColor *strokeColor, UIColor *fillColor, BOOL fill);


/**
 * Custom RatingBar (Similar to RatingBar in Android SDK)
 *
 * @version 1.0.1
 * @author Chih-chieh Chang
 * @date 2017-02-20
 */
@interface CCCRatingControl : UIControl

/// Default is 0.
@property (nonatomic) CGFloat value;
/// Default is 5.
@property (nonatomic) NSUInteger maximumValue;
/// Default is 1. Defines number of fractions in a rating unit.
@property (nonatomic) NSUInteger fractionNumber;

/// Default is nil.
@property (retain, nonatomic, nullable) UIImage *ratingImage;
/// Default is nil.
@property (retain, nonatomic, nullable) UIImage *highlightedRatingImage;

/// This value will be ignored if horizontalAlignment is UIControlContentHorizontalAlignmentFill. Default is {30, 30}.
@property (nonatomic) CGSize unitSize;
/// Edge between each rating units, padding of rating bar will be estimate by unitSize and edgeBetweenUnits. This value will be ignored if horizontalAlignment is UIControlContentHorizontalAlignmentFill. Default is 0.
@property (nonatomic) CGFloat edgeBetweenUnits;

/// If set, value change events are generated any time the value changes due to dragging. default is YES.
@property (nonatomic, getter=isContinuous) BOOL continuous;

- (instancetype)initWithRatingImage:(nullable UIImage *)image
             highlightedRatingImage:(nullable UIImage *)highlightedRatingImage NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithRatingImage:(nullable UIImage *)image
             highlightedRatingImage:(nullable UIImage *)highlightedRatingImage
                       maximumValue:(NSInteger)maximumValue
                      fractionNumer:(NSInteger)fractionNumer NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame
                  ratingImage:(nullable UIImage *)image
       highlightedRatingImage:(nullable UIImage *)highlightedRatingImage NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFrame:(CGRect)frame
                  ratingImage:(nullable UIImage *)image
       highlightedRatingImage:(nullable UIImage *)highlightedRatingImage
                 maximumValue:(NSInteger)maximumValue
                fractionNumer:(NSInteger)fractionNumer NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

/// The rectangle in which the receiver draws its entire content.
@property (readonly, nonatomic) CGRect contentRect;

@end

NS_ASSUME_NONNULL_END
