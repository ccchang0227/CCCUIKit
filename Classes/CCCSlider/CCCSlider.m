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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
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
    
    [self setupLayers];
    [self resizeLayers];
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
    
    [self setupValueAnimated:NO];
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
    
#if !__has_feature(objc_arc)
    if (_sliderBorderColor) {
        [_sliderBorderColor release];
    }
#endif
    _sliderBorderColor = [sliderBorderColor retain];
    
    self.sliderBackgroundLayer.strokeColor = self.sliderBorderColor.CGColor;
}

- (void)setSliderBackgroundColor:(UIColor *)sliderBackgroundColor {
    if (CGColorEqualToColor(sliderBackgroundColor.CGColor, _sliderBackgroundColor.CGColor)) {
        return;
    }
    
#if !__has_feature(objc_arc)
    if (_sliderBackgroundColor) {
        [_sliderBackgroundColor release];
    }
#endif
    _sliderBackgroundColor = [sliderBackgroundColor retain];
    
    self.sliderBackgroundLayer.fillColor = self.sliderBackgroundColor.CGColor;
}

- (void)setSliderTrackingColors:(NSArray *)sliderTrackingColors {
    if (_sliderTrackingColors != sliderTrackingColors) {
#if !__has_feature(objc_arc)
        if (_sliderTrackingColors) {
            [_sliderTrackingColors release];
        }
#endif
        _sliderTrackingColors = [sliderTrackingColors retain];
        
    }
    
    if (_sliderTrackingColors == nil) {
        self.sliderTrackingColors = @[[UIColor blueColor]];
        return;
    }
    
    if (self.sliderTrackingColors.count == 1) {
        self.sliderTrackingLayer.backgroundColor = ((UIColor*)self.sliderTrackingColors[0]).CGColor;
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

- (void)setThumbBorderColor:(UIColor *)thumbBorderColor {
    if (CGColorEqualToColor(thumbBorderColor.CGColor, _thumbBorderColor.CGColor)) {
        return;
    }
    
#if !__has_feature(objc_arc)
    if (_thumbBorderColor) {
        [_thumbBorderColor release];
    }
#endif
    _thumbBorderColor = [_thumbBorderColor retain];
    
    self.thumbLayer.strokeColor = self.thumbBorderColor.CGColor;
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    if (CGColorEqualToColor(thumbTintColor.CGColor, _thumbTintColor.CGColor)) {
        return;
    }
    
#if !__has_feature(objc_arc)
    if (_thumbTintColor) {
        [_thumbTintColor release];
    }
#endif
    _thumbTintColor = [thumbTintColor retain];
    
    self.thumbLayer.fillColor = self.thumbTintColor.CGColor;
}

- (void)setEdged:(BOOL)edged {
    _edged = edged;
    
    if (edged) {
        self.value = round(_value);
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
    }
    self.leftImageLayer.contents = (id)_minimumValueImage.CGImage;
    
    [self resizeLayers];
}

- (void)setMaximumValueImage:(UIImage *)maximumValueImage {
    if (_maximumValueImage != maximumValueImage) {
#if !__has_feature(objc_arc)
        if (_maximumValueImage) {
            [_maximumValueImage release];
        }
#endif
        _maximumValueImage = [maximumValueImage retain];
    }
    
    self.rightImageLayer.contents = (id)_maximumValueImage.CGImage;
    
    [self resizeLayers];
}

- (void)setThumbImage:(UIImage *)thumbImage {
    if (_thumbImage != thumbImage) {
#if !__has_feature(objc_arc)
        if (_thumbImage) {
            [_thumbImage release];
        }
#endif
        _thumbImage = [thumbImage retain];
    }
    
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

- (void)setValue:(CGFloat)value animated:(BOOL)animated {
    CGFloat newValue = (value >= _maximumValue)? _maximumValue: ((value <= _minimumValue)? _minimumValue: value);
    
    if (self.isEdged) {
        newValue = round(newValue);
    }
    
    _value = newValue;
    [self setupValueAnimated:YES];
    
}

- (void)setThumbHidden:(BOOL)hidden {
    if (!self.thumbLayer) {
        [self setupLayers];
    }
    self.thumbLayer.hidden = hidden;
}

#pragma mark - Getter

- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
    return CGRectMake((CGRectGetWidth(bounds)-40)/2.0, (CGRectGetHeight(bounds)-30)/2.0, 40, 30);
}

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
    return CGRectMake((CGRectGetWidth(bounds)-40)/2.0, (CGRectGetHeight(bounds)-30)/2.0, 40, 30);
}
    
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(10, (CGRectGetHeight(bounds)-10)/2.0, CGRectGetWidth(bounds)-20, 10);
}

- (CGRect)thumbRectForBounds:(CGRect)bounds {
    return CGRectMake((CGRectGetWidth(bounds)-25)/2.0, (CGRectGetHeight(bounds)-25)/2.0, 25, 25);
}

#pragma mark - Setup

- (void)setup {
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

- (void)setupLayers {
    if (self.leftImageLayer == nil) {
        self.leftImageLayer = [CALayer layer];
        self.leftImageLayer.bounds = CGRectMake(0, 0, 10, 30);
        self.leftImageLayer.position = CGPointMake(CGRectGetWidth(self.leftImageLayer.bounds)/2.0, CGRectGetHeight(self.bounds)/2.0);
        self.leftImageLayer.contentsGravity = kCAGravityResizeAspect;
        self.leftImageLayer.contents = nil;
        [self.layer addSublayer:self.leftImageLayer];
    }
    
    if (self.rightImageLayer == nil) {
        self.rightImageLayer = [CALayer layer];
        self.rightImageLayer.bounds = CGRectMake(0, 0, 10, 30);
        self.rightImageLayer.position = CGPointMake(CGRectGetWidth(self.bounds)-CGRectGetWidth(self.rightImageLayer.bounds)/2.0, CGRectGetHeight(self.bounds)/2.0);
        self.rightImageLayer.contentsGravity = kCAGravityResizeAspect;
        self.rightImageLayer.contents = nil;
        [self.layer addSublayer:self.rightImageLayer];
    }
    
    if (self.sliderBackgroundLayer == nil) {
        self.sliderBackgroundLayer = [CAShapeLayer layer];
        self.sliderBackgroundLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.bounds)-CGRectGetWidth(self.leftImageLayer.frame)-CGRectGetWidth(self.rightImageLayer.frame), 10);
        self.sliderBackgroundLayer.position = CGPointMake(CGRectGetWidth(self.bounds)/2.0, CGRectGetHeight(self.bounds)/2.0);
        self.sliderBackgroundLayer.fillColor = self.sliderBackgroundColor.CGColor;
        self.sliderBackgroundLayer.strokeColor = self.sliderBorderColor.CGColor;
        [self.layer addSublayer:self.sliderBackgroundLayer];
    }
    
    if (self.sliderTrackingLayer == nil) {
        self.sliderTrackingLayer = [CAGradientLayer layer];
        self.sliderTrackingLayer.bounds = self.sliderBackgroundLayer.bounds;
        self.sliderTrackingLayer.position = self.sliderBackgroundLayer.position;
        if (self.sliderTrackingColors.count == 1) {
            self.sliderTrackingLayer.backgroundColor = ((UIColor*)self.sliderTrackingColors[0]).CGColor;
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
        
        self.thumbLayer = [CAShapeLayer layer];
        self.thumbLayer.bounds = CGRectMake(0, 0, 25, 25);
        self.thumbLayer.position = CGPointMake(CGRectGetMinX(self.sliderTrackingLayer.frame), CGRectGetHeight(self.bounds)/2.0);
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

- (void)resizeLayers {
    if (self.minimumValueImage) {
        self.leftImageLayer.bounds = CGRectMake(0, 0, 40, 30);
    }
    else {
        self.leftImageLayer.bounds = CGRectMake(0, 0, 10, 30);
    }
    self.leftImageLayer.position = CGPointMake(CGRectGetWidth(self.leftImageLayer.bounds)/2.0, CGRectGetHeight(self.bounds)/2.0);
    
    if (self.maximumValueImage) {
        self.rightImageLayer.bounds = CGRectMake(0, 0, 40, 30);
    }
    else {
        self.rightImageLayer.bounds = CGRectMake(0, 0, 10, 30);
    }
    self.rightImageLayer.position = CGPointMake(CGRectGetWidth(self.bounds)-CGRectGetWidth(self.rightImageLayer.bounds)/2.0, CGRectGetHeight(self.bounds)/2.0);
    
    self.sliderBackgroundLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.bounds)-CGRectGetWidth(self.leftImageLayer.frame)-CGRectGetWidth(self.rightImageLayer.frame), 10);
    self.sliderBackgroundLayer.position = CGPointMake(CGRectGetWidth(self.sliderBackgroundLayer.bounds)/2.0+CGRectGetWidth(self.leftImageLayer.frame), CGRectGetHeight(self.bounds)/2.0);
    
    self.sliderTrackingLayer.bounds = self.sliderBackgroundLayer.bounds;
    self.sliderTrackingLayer.position = self.sliderBackgroundLayer.position;
    
    CALayer *trackingMaskLayer = self.sliderTrackingLayer.mask;
    trackingMaskLayer.frame = CGRectInset(self.sliderTrackingLayer.bounds, 0, 0.5);
    
    self.thumbLayer.position = CGPointMake(CGRectGetMinX(self.sliderTrackingLayer.frame), CGRectGetHeight(self.bounds)/2.0);
    
    [self setupSlider];
}

- (void)setupSlider {
    CGMutablePathRef pathBKLayer = CGPathCreateMutable();
    CGPathAddRoundedRect(pathBKLayer, &CGAffineTransformIdentity, self.sliderBackgroundLayer.bounds, CGRectGetHeight(self.sliderBackgroundLayer.bounds)/2.0, CGRectGetHeight(self.sliderBackgroundLayer.bounds)/2.0);
    
    self.sliderBackgroundLayer.path = pathBKLayer;
    
    CGPathRelease(pathBKLayer);
    
    [self setupValueAnimated:NO];
}

- (void)setupValueAnimated:(BOOL)animated {
    [CATransaction begin];
    
    CGFloat value = (self.value-self.minimumValue)/(self.maximumValue-self.minimumValue);
    if (self.minimumValue == self.maximumValue) value = 1.0;
    CGFloat width = CGRectGetWidth(self.sliderTrackingLayer.bounds)*value;
    
    if (!animated) {
        [CATransaction setDisableActions:YES];
    }
    else {
        [CATransaction setAnimationDuration:0.25];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    
    CALayer *maskLayer = self.sliderTrackingLayer.mask;
    maskLayer.frame = CGRectMake(maskLayer.frame.origin.x, maskLayer.frame.origin.y, width, maskLayer.frame.size.height);
    
    width = (width <= CGRectGetHeight(self.sliderTrackingLayer.bounds))? CGRectGetHeight(self.sliderTrackingLayer.bounds): width;
    self.thumbLayer.position = CGPointMake(width+CGRectGetMinX(self.sliderTrackingLayer.frame)-5, self.thumbLayer.position.y);
    
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
        
        [self setupValueAnimated:NO];
        
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
    
    [self setupValueAnimated:NO];
    
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
