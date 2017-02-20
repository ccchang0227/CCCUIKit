//
//  CCCSlider.h
//
//  Created by CHIEN-HSU WU on 2015/3/4.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Custom UISlider (Mutiple color assignable)
 *
 * @version 1.1.0
 * @author Chih-chieh Chang
 * @date 2017-02-20
 */
@interface CCCSlider : UIControl {
@protected
    CAShapeLayer *_sliderBackgroundLayer;
    CAGradientLayer *_sliderTrackingLayer;
    CAShapeLayer *_thumbLayer;
    
    CALayer *_leftImageLayer;
    CALayer *_rightImageLayer;
}

@property (nonatomic) CGFloat value; //default is 0.5.
@property (nonatomic) CGFloat minimumValue; // default is 0.0.
@property (nonatomic) CGFloat maximumValue; // default is 1.0.

@property (retain, nonatomic) UIColor *sliderBorderColor; // default is [UIColor blackColor].
@property (retain, nonatomic) UIColor *sliderBackgroundColor; // default is [UIColor whiteColor].
@property (retain, nonatomic) NSArray *sliderTrackingColors; // default is an array contains [UIColor blueColor].

@property (retain, nonatomic) UIColor *thumbBorderColor; // default is [UIColor blackColor].
@property (retain, nonatomic) UIColor *thumbTintColor; // default is [UIColor whiteColor].

@property (nonatomic, getter=isContinuous) BOOL continuous; // if set, value change events are generated any time the value changes due to dragging. default = YES.
@property (nonatomic, getter=isEdged) BOOL edged; // if set, value will changed with integer. default = NO.

@property(retain, nonatomic) UIImage *minimumValueImage; // default is nil. image that appears to left of control.
@property(retain, nonatomic) UIImage *maximumValueImage; // default is nil. image that appears to right of control.
@property(retain, nonatomic) UIImage *thumbImage; // default is nil.
@property (nonatomic, getter=isThumbHidden) BOOL thumbHidden; // default is NO.

- (void)setValue:(CGFloat)value animated:(BOOL)animated;

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds;
- (CGRect)trackRectForBounds:(CGRect)bounds;
- (CGRect)thumbRectForBounds:(CGRect)bounds;
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value;

@end
