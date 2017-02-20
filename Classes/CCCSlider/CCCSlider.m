//
//  CCCSlider.m
//
//  Created by CHIEN-HSU WU on 2015/3/4.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCSlider.h"


@interface CCCSlider () {
    CGPoint _currentPoint;
    CGPoint _previousPoint;
    
    BOOL _dragging;
}

@property (retain, nonatomic) CAShapeLayer *sliderBackgroundLayer;
@property (retain, nonatomic) CAGradientLayer *sliderTrackingLayer;
@property (retain, nonatomic) CAShapeLayer *thumbLayer;

@property (retain, nonatomic) CALayer *leftImageLayer;
@property (retain, nonatomic) CALayer *rightImageLayer;

@end

@implementation CCCSlider
@synthesize sliderBackgroundLayer = _sliderBackgroundLayer;
@synthesize sliderTrackingLayer = _sliderTrackingLayer;
@synthesize thumbLayer = _thumbLayer;
@synthesize leftImageLayer = _leftImageLayer;
@synthesize rightImageLayer = _rightImageLayer;


- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_sliderBorderColor release];
    [_sliderBackgroundColor release];
    [_sliderTrackingColors release];
    [_thumbBorderColor release];
    [_thumbTintColor release];
    [_minimumValueImage release];
    [_maximumValueImage release];
    [_thumbImage release];
    [_sliderBackgroundLayer release];
    [_sliderTrackingLayer release];
    [_thumbLayer release];
    [_leftImageLayer release];
    [_rightImageLayer release];
    [super dealloc];
#endif
    
}

#pragma mark - Assign

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [self _setupLayers];
    [self _resizeLayers];
}

- (void)updateConstraints {
    [super updateConstraints];
    
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    
    [self setNeedsDisplay];
}

- (void)setValue:(CGFloat)value {
    CGFloat newValue = (value >= _maximumValue)? _maximumValue: ((value <= _minimumValue)? _minimumValue: value);
    
    if (self.isEdged) {
        newValue = round(newValue);
    }
    _value = newValue;
    
    [self _setupValueAnimated:NO];
}

- (void)setMinimumValue:(CGFloat)minimumValue {
    _minimumValue = minimumValue;
    if (_minimumValue > _maximumValue) {
        _maximumValue = _minimumValue;
    }
    
    self.value = _value;
}

- (void)setMaximumValue:(CGFloat)maximumValue {
    _maximumValue = maximumValue;
    if (_maximumValue < _minimumValue) {
        _minimumValue = _maximumValue;
    }
    
    self.value = _value;
}

- (void)setSliderBorderColor:(UIColor *)sliderBorderColor {
    if (CGColorEqualToColor(sliderBorderColor.CGColor, _sliderBorderColor.CGColor)) {
        return;
    }
    
    if (_sliderBorderColor != sliderBorderColor) {
#if !__has_feature(objc_arc)
        if (_sliderBorderColor) {
            [_sliderBorderColor release];
        }
#endif
        _sliderBorderColor = [sliderBorderColor retain];
        
        self.sliderBackgroundLayer.strokeColor = self.sliderBorderColor.CGColor;
    }

}

- (void)setSliderBackgroundColor:(UIColor *)sliderBackgroundColor {
    if (CGColorEqualToColor(sliderBackgroundColor.CGColor, _sliderBackgroundColor.CGColor)) {
        return;
    }
    
    if (_sliderBackgroundColor != sliderBackgroundColor) {
#if !__has_feature(objc_arc)
        if (_sliderBackgroundColor) {
            [_sliderBackgroundColor release];
        }
#endif
        _sliderBackgroundColor = [sliderBackgroundColor retain];
        
        self.sliderBackgroundLayer.fillColor = self.sliderBackgroundColor.CGColor;
    }
    
}

- (void)setSliderTrackingColors:(NSArray *)sliderTrackingColors {
    if (_sliderTrackingColors != sliderTrackingColors) {
#if !__has_feature(objc_arc)
        if (_sliderTrackingColors) {
            [_sliderTrackingColors release];
        }
#endif
        _sliderTrackingColors = [sliderTrackingColors retain];
        
        if (_sliderTrackingColors == nil) {
            self.sliderTrackingColors = @[[UIColor blueColor]];
            return;
        }
        
        if (self.sliderTrackingColors.count == 1) {
            self.sliderTrackingLayer.backgroundColor = ((UIColor *)self.sliderTrackingColors[0]).CGColor;
            self.sliderTrackingLayer.colors = nil;
        }
        else {
            self.sliderTrackingLayer.backgroundColor = [UIColor clearColor].CGColor;
            NSMutableArray *arrayCGColor = [NSMutableArray arrayWithCapacity:0];
            for (UIColor *color in self.sliderTrackingColors) {
                [arrayCGColor addObject:(id)color.CGColor];
            }
            self.sliderTrackingLayer.colors = arrayCGColor;
        }
    }
    
}

- (void)setThumbBorderColor:(UIColor *)thumbBorderColor {
    if (CGColorEqualToColor(thumbBorderColor.CGColor, _thumbBorderColor.CGColor)) {
        return;
    }
    
    if (_thumbBorderColor != thumbBorderColor) {
#if !__has_feature(objc_arc)
        if (_thumbBorderColor) {
            [_thumbBorderColor release];
        }
#endif
        _thumbBorderColor = [thumbBorderColor retain];
        
        self.thumbLayer.strokeColor = self.thumbBorderColor.CGColor;
    }
    
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    if (CGColorEqualToColor(thumbTintColor.CGColor, _thumbTintColor.CGColor)) {
        return;
    }
    
    if (_thumbTintColor != thumbTintColor) {
#if !__has_feature(objc_arc)
        if (_thumbTintColor) {
            [_thumbTintColor release];
        }
#endif
        _thumbTintColor = [thumbTintColor retain];
        
        self.thumbLayer.fillColor = self.thumbTintColor.CGColor;
    }

}

- (void)setEdged:(BOOL)edged {
    if (_edged != edged) {
        _edged = edged;
        
        if (_edged) {
            self.value = round(_value);
        }
    }
}

- (void)setMinimumValueImage:(UIImage *)minimumValueImage {
    if (_minimumValueImage != minimumValueImage) {
#if !__has_feature(objc_arc)
        if (_minimumValueImage) {
            [_minimumValueImage release];
        }
#endif
        _minimumValueImage = [minimumValueImage retain];
        
        self.leftImageLayer.contents = (id)_minimumValueImage.CGImage;
        
        [self _resizeLayers];
    }
}

- (void)setMaximumValueImage:(UIImage *)maximumValueImage {
    if (_maximumValueImage != maximumValueImage) {
#if !__has_feature(objc_arc)
        if (_maximumValueImage) {
            [_maximumValueImage release];
        }
#endif
        _maximumValueImage = [maximumValueImage retain];
        
        self.rightImageLayer.contents = (id)_maximumValueImage.CGImage;
        
        [self _resizeLayers];
    }
}

- (void)setThumbImage:(UIImage *)thumbImage {
    if (_thumbImage != thumbImage) {
#if !__has_feature(objc_arc)
        if (_thumbImage) {
            [_thumbImage release];
        }
#endif
        _thumbImage = [thumbImage retain];
        
        self.thumbLayer.contents = (id)_thumbImage.CGImage;
        if (_thumbImage) {
            self.thumbLayer.path = nil;
        }
        else {
            CGMutablePathRef pathThumbLayer = CGPathCreateMutable();
            CGPathAddEllipseInRect(pathThumbLayer, &CGAffineTransformIdentity, self.thumbLayer.bounds);
            self.thumbLayer.path = pathThumbLayer;
            CGPathRelease(pathThumbLayer);
        }
    }
}

- (BOOL)isThumbHidden {
    if (!self.thumbLayer) {
        [self _setupLayers];
    }
    return self.thumbLayer.hidden;
}

- (void)setThumbHidden:(BOOL)hidden {
    if (!self.thumbLayer) {
        [self _setupLayers];
    }
    self.thumbLayer.hidden = hidden;
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated {
    CGFloat newValue = (value >= _maximumValue)? _maximumValue: ((value <= _minimumValue)? _minimumValue: value);
    
    if (self.isEdged) {
        newValue = round(newValue);
    }
    
    _value = newValue;
    [self _setupValueAnimated:YES];
}

#pragma mark - Getter

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
    CGRect rectMinVal = {{0, 0}, {10, 30}};
    if (self.minimumValueImage) {
        rectMinVal.size.width = 40;
    }
    rectMinVal.origin.y = (CGRectGetHeight(bounds)-CGRectGetHeight(rectMinVal))/2.0;
    return rectMinVal;
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
    CGRect rectMaxVal = {{0, 0}, {10, 30}};
    if (self.maximumValueImage) {
        rectMaxVal.size.width = 40;
    }
    rectMaxVal.origin.x = CGRectGetWidth(bounds)-CGRectGetWidth(rectMaxVal);
    rectMaxVal.origin.y = (CGRectGetHeight(bounds)-CGRectGetHeight(rectMaxVal))/2.0;
    return rectMaxVal;
}
    
- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect rectMinVal = [self minimumValueImageRectForBounds:bounds];
    CGRect rectMaxVal = [self maximumValueImageRectForBounds:bounds];
    
    CGRect rectTrack = {{0, 0}, {0, 10}};
    rectTrack.size.width = CGRectGetWidth(bounds)-CGRectGetWidth(rectMinVal)-CGRectGetWidth(rectMaxVal);
    rectTrack.origin.x = CGRectGetWidth(rectMinVal);
    rectTrack.origin.y = (CGRectGetHeight(bounds)-CGRectGetHeight(rectTrack))/2.0;
    return rectTrack;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds {
    return [self thumbRectForBounds:bounds trackRect:[self trackRectForBounds:bounds] value:self.value];
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
    CGRect rectThumb = {{0, 0}, {25, 25}};
    rectThumb.origin.y = (CGRectGetHeight(bounds)-CGRectGetHeight(rectThumb))/2.0;
    
    CGFloat realVal = (value >= _maximumValue)? _maximumValue: ((value <= _minimumValue)? _minimumValue: value);
    realVal = (realVal-self.minimumValue)/(self.maximumValue-self.minimumValue);
    if (self.minimumValue == self.maximumValue) {
        realVal = 1.0;
    }
    CGFloat trackWidth = CGRectGetWidth(rect)*realVal;
    
    rectThumb.origin.x = trackWidth+CGRectGetMinX(rect)-5-CGRectGetWidth(rectThumb);
    return rectThumb;
}

#pragma mark - Setup

- (void)_setup {
    _minimumValue = 0.0f;
    _maximumValue = 1.0f;
    _value = 0.5f;
    
    self.sliderBorderColor = [UIColor blackColor];
    self.sliderBackgroundColor = [UIColor whiteColor];
    self.sliderTrackingColors = @[[UIColor blueColor]];
    
    self.thumbBorderColor = [UIColor blackColor];
    self.thumbTintColor = [UIColor whiteColor];
    
    self.continuous = YES;
    self.edged = NO;
    
    self.minimumValueImage = nil;
    self.maximumValueImage = nil;
}

- (void)_setupLayers {
    if (self.leftImageLayer == nil) {
        CGRect rect = [self minimumValueImageRectForBounds:self.bounds];
        self.leftImageLayer = [CALayer layer];
        self.leftImageLayer.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
        self.leftImageLayer.position = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        self.leftImageLayer.contentsGravity = kCAGravityResizeAspect;
        self.leftImageLayer.contents = nil;
        [self.layer addSublayer:self.leftImageLayer];
    }
    
    if (self.rightImageLayer == nil) {
        CGRect rect = [self maximumValueImageRectForBounds:self.bounds];
        self.rightImageLayer = [CALayer layer];
        self.rightImageLayer.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
        self.rightImageLayer.position = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        self.rightImageLayer.contentsGravity = kCAGravityResizeAspect;
        self.rightImageLayer.contents = nil;
        [self.layer addSublayer:self.rightImageLayer];
    }
    
    if (self.sliderBackgroundLayer == nil) {
        CGRect rect = [self trackRectForBounds:self.bounds];
        self.sliderBackgroundLayer = [CAShapeLayer layer];
        self.sliderBackgroundLayer.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
        self.sliderBackgroundLayer.position = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        self.sliderBackgroundLayer.fillColor = self.sliderBackgroundColor.CGColor;
        self.sliderBackgroundLayer.strokeColor = self.sliderBorderColor.CGColor;
        [self.layer addSublayer:self.sliderBackgroundLayer];
    }
    
    if (self.sliderTrackingLayer == nil) {
        self.sliderTrackingLayer = [CAGradientLayer layer];
        self.sliderTrackingLayer.bounds = self.sliderBackgroundLayer.bounds;
        self.sliderTrackingLayer.position = self.sliderBackgroundLayer.position;
        if (self.sliderTrackingColors.count == 1) {
            self.sliderTrackingLayer.backgroundColor = ((UIColor *)self.sliderTrackingColors[0]).CGColor;
            self.sliderTrackingLayer.colors = nil;
        }
        else {
            self.sliderTrackingLayer.backgroundColor = [UIColor clearColor].CGColor;
            NSMutableArray *arrayCGColor = [NSMutableArray arrayWithCapacity:0];
            for (UIColor *color in self.sliderTrackingColors) {
                [arrayCGColor addObject:(id)color.CGColor];
            }
            self.sliderTrackingLayer.colors = arrayCGColor;
        }
        self.sliderTrackingLayer.startPoint = CGPointMake(0.0, 0.5);
        self.sliderTrackingLayer.endPoint = CGPointMake(1.0, 0.5);
        [self.layer addSublayer:self.sliderTrackingLayer];
        
        CALayer *trackingMaskLayer = [CALayer layer];
        trackingMaskLayer.frame = CGRectInset(self.sliderTrackingLayer.bounds, 0, 0.5);
        trackingMaskLayer.cornerRadius = CGRectGetHeight(self.sliderTrackingLayer.frame)/2.0;
        trackingMaskLayer.backgroundColor = [UIColor blackColor].CGColor;
        self.sliderTrackingLayer.mask = trackingMaskLayer;
    }
    
    if (self.thumbLayer == nil) {
        CGMutablePathRef pathThumbLayer = CGPathCreateMutable();
        
        CGRect rect = [self thumbRectForBounds:self.bounds];
        self.thumbLayer = [CAShapeLayer layer];
        self.thumbLayer.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
        self.thumbLayer.position = CGPointMake(CGRectGetMinX(self.sliderTrackingLayer.frame), CGRectGetMidY(rect));
        self.thumbLayer.contentsGravity = kCAGravityResizeAspect;
        self.thumbLayer.contents = nil;
        
        CGPathAddEllipseInRect(pathThumbLayer, &CGAffineTransformIdentity, self.thumbLayer.bounds);
        self.thumbLayer.path = pathThumbLayer;
        self.thumbLayer.fillColor = self.thumbTintColor.CGColor;
        self.thumbLayer.strokeColor = self.thumbBorderColor.CGColor;
        [self.layer addSublayer:self.thumbLayer];
        
        CGPathRelease(pathThumbLayer);
    }
}

- (void)_resizeLayers {
    CGRect rectMinVal = [self minimumValueImageRectForBounds:self.bounds];
    self.leftImageLayer.bounds = CGRectMake(0, 0, rectMinVal.size.width, rectMinVal.size.height);
    self.leftImageLayer.position = CGPointMake(CGRectGetMidX(rectMinVal), CGRectGetMidY(rectMinVal));
    
    CGRect rectMaxVal = [self maximumValueImageRectForBounds:self.bounds];
    self.rightImageLayer.bounds = CGRectMake(0, 0, rectMaxVal.size.width, rectMaxVal.size.height);
    self.rightImageLayer.position = CGPointMake(CGRectGetMidX(rectMaxVal), CGRectGetMidY(rectMaxVal));
    
    CGRect rectTrack = [self trackRectForBounds:self.bounds];
    self.sliderBackgroundLayer.bounds = CGRectMake(0, 0, rectTrack.size.width, rectTrack.size.height);
    self.sliderBackgroundLayer.position = CGPointMake(CGRectGetMidX(rectTrack), CGRectGetMidY(rectTrack));
    
    self.sliderTrackingLayer.bounds = self.sliderBackgroundLayer.bounds;
    self.sliderTrackingLayer.position = self.sliderBackgroundLayer.position;
    
    CALayer *trackingMaskLayer = self.sliderTrackingLayer.mask;
    trackingMaskLayer.frame = CGRectInset(self.sliderTrackingLayer.bounds, 0, 0.5);
    
    CGRect rectThumb = [self thumbRectForBounds:self.bounds trackRect:rectTrack value:self.value];
    self.thumbLayer.bounds = CGRectMake(0, 0, rectThumb.size.width, rectThumb.size.height);
    self.thumbLayer.position = CGPointMake(CGRectGetMinX(self.sliderTrackingLayer.frame), CGRectGetMidY(rectThumb));
    
    [self _setupSlider];
}

- (void)_setupSlider {
    CGMutablePathRef pathBKLayer = CGPathCreateMutable();
    CGPathAddRoundedRect(pathBKLayer,
                         &CGAffineTransformIdentity,
                         self.sliderBackgroundLayer.bounds,
                         CGRectGetHeight(self.sliderBackgroundLayer.bounds)/2.0,
                         CGRectGetHeight(self.sliderBackgroundLayer.bounds)/2.0);
    
    self.sliderBackgroundLayer.path = pathBKLayer;
    
    CGPathRelease(pathBKLayer);
    
    [self _setupValueAnimated:NO];
}

- (void)_setupValueAnimated:(BOOL)animated {
    [CATransaction begin];
    
    CGRect rectThumb = [self thumbRectForBounds:self.bounds];
    self.thumbLayer.bounds = CGRectMake(0, 0, rectThumb.size.width, rectThumb.size.height);
    
    CGFloat value = (self.value-self.minimumValue)/(self.maximumValue-self.minimumValue);
    if (self.minimumValue == self.maximumValue) {
        value = 1.0;
    }
    CGFloat width = CGRectGetMinX(rectThumb)-CGRectGetMinX(self.sliderTrackingLayer.frame)+5+CGRectGetWidth(rectThumb);
    
    if (!animated) {
        [CATransaction setDisableActions:YES];
    }
    else {
        [CATransaction setDisableActions:NO];
        [CATransaction setAnimationDuration:0.25];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    
    CALayer *maskLayer = self.sliderTrackingLayer.mask;
    maskLayer.frame = CGRectMake(maskLayer.frame.origin.x, maskLayer.frame.origin.y, width, maskLayer.frame.size.height);
    
    width = (width <= CGRectGetHeight(self.sliderTrackingLayer.bounds))? CGRectGetHeight(self.sliderTrackingLayer.bounds): width;
    self.thumbLayer.position = CGPointMake(width+CGRectGetMinX(self.sliderTrackingLayer.frame)-5, CGRectGetMidY(rectThumb));
    
    [CATransaction commit];
}

#pragma mark - Tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    _dragging = NO;
    _currentPoint = [touch locationInView:self];
    _previousPoint = _currentPoint;
    
    if (!CGRectContainsPoint(self.thumbLayer.frame, _currentPoint)) {
        if (_currentPoint.x <= CGRectGetMinX(self.sliderBackgroundLayer.frame)) {
            _value = self.minimumValue;
        }
        else if (_currentPoint.x >= CGRectGetMaxX(self.sliderBackgroundLayer.frame)) {
            _value = self.maximumValue;
        }
        else {
            _value = ((_currentPoint.x-CGRectGetMinX(self.sliderBackgroundLayer.frame))/CGRectGetWidth(self.sliderBackgroundLayer.frame))*(self.maximumValue-self.minimumValue) + self.minimumValue;
        }
        
        if (self.isEdged) {
            _value = round(_value);
        }
        
        [self _setupValueAnimated:NO];
        
        if (self.isContinuous)
            [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    
    _dragging = YES;
    _currentPoint = [touch locationInView:self];
    
    if (_currentPoint.x <= CGRectGetMinX(self.sliderBackgroundLayer.frame)) {
        _value = self.minimumValue;
    }
    else if (_currentPoint.x >= CGRectGetMaxX(self.sliderBackgroundLayer.frame)) {
        _value = self.maximumValue;
    }
    else {
        _value = ((_currentPoint.x-CGRectGetMinX(self.sliderBackgroundLayer.frame))/CGRectGetWidth(self.sliderBackgroundLayer.frame))*(self.maximumValue-self.minimumValue) + self.minimumValue;
    }
    
    if (self.isEdged) {
        _value = round(_value);
    }
    
    [self _setupValueAnimated:NO];
    
    if (self.isContinuous)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    _previousPoint = _currentPoint;
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    if (!self.isContinuous)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    
    if (!self.isContinuous)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
