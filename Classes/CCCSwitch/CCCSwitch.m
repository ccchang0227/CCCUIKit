//
//  CCCSwitch.m
//
//  Created by CHIEN-HSU WU on 2015/4/3.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCSwitch.h"

UIImage *powerKeyImageInSize(CGSize size) {
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 10.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    
    CGContextAddArc(context, size.width/2.0, size.height/2.0, MIN(size.width/2.0, size.height/2.0)*0.6, 20*M_PI/180.0-M_PI_2, 340*M_PI/180.0-M_PI_2, 0);
    
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextSaveGState(context);
    
    CGContextMoveToPoint(context, size.width/2.0, size.height/2.0);
    CGFloat y = MIN(size.width, size.height)*0.1;
    if (size.height > size.width) {
        y += (size.height-size.width)/2.0;
    }
    CGContextAddLineToPoint(context, size.width/2.0, y);
    
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}


@interface CCCSwitch () {
    BOOL _valueChanged;
    BOOL _didDrag;
}

@property (retain, nonatomic) UIView *contentView;

@property (retain, nonatomic) CALayer *backgroundLayer;
@property (retain, nonatomic) CALayer *switchLayer;
@property (retain, nonatomic) CALayer *thumbLayer;

@property (retain, nonatomic) NSLayoutConstraint *widthConstraint;
@property (retain, nonatomic) NSLayoutConstraint *heightConstraint;
@property (retain, nonatomic) NSLayoutConstraint *centerXConstraint;
@property (retain, nonatomic) NSLayoutConstraint *centerYConstraint;

@end

@implementation CCCSwitch

- (instancetype)initWithStyle:(CCCSwitchStyle)style {
    self = [super init];
    if (self) {
        [self setup];
        self.style = style;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame style:(CCCSwitchStyle)style {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        self.style = style;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_contentView release];
    [_backgroundLayer release];
    [_switchLayer release];
    [_thumbLayer release];
    [_onTintColor release];
    [_widthConstraint release];
    [_heightConstraint release];
    [_centerXConstraint release];
    [_centerYConstraint release];
    [super dealloc];
#endif
    
}

#pragma mark - Assign

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    
    [self setupDisplay];
}

- (void)layoutSubviews {
    [self setupDisplay];
    
    [super layoutSubviews];
}

- (void)setTranslatesAutoresizingMaskIntoConstraints:(BOOL)translatesAutoresizingMaskIntoConstraints {
    [super setTranslatesAutoresizingMaskIntoConstraints:translatesAutoresizingMaskIntoConstraints];
    
    [self setupDisplay];
}

- (void)setStyle:(CCCSwitchStyle)style {
    _style = style;
    
    [self setupDisplay];
}

- (void)setOnTintColor:(UIColor *)onTintColor {
    if (_onTintColor != onTintColor) {
#if !__has_feature(objc_arc)
        [_onTintColor release];
#endif
        _onTintColor = [onTintColor copy];
        
        [self setupSwitchOnTintColor];
    }
}

- (void)setOn:(BOOL)on {
    _on = on;
    
    [self setupOn];
}

#pragma mark - setup

- (void)setup {
    _style = CCCSwitchStyleDefault;
    _on = NO;
    _onTintColor = [[UIColor greenColor] copy];
}

- (void)setupDisplay {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = NO;
        [self addSubview:_contentView];
    }
    CGRect newFrame = [self switchFrameFromCurrentStyle];
    _contentView.frame = newFrame;
    
    if (!self.translatesAutoresizingMaskIntoConstraints) {
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        if (!self.centerXConstraint) {
            self.centerXConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
            [self addConstraint:self.centerXConstraint];
        }
        if (!self.centerYConstraint) {
            self.centerYConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
            [self addConstraint:self.centerYConstraint];
        }
        
        if (!self.widthConstraint) {
            self.widthConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:newFrame.size.width];
            [self addConstraint:self.widthConstraint];
        }
        else {
            self.widthConstraint.constant = newFrame.size.width;
        }
        if (!self.heightConstraint) {
            self.heightConstraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:newFrame.size.height];
            [self addConstraint:self.heightConstraint];
        }
        else {
            self.heightConstraint.constant = newFrame.size.height;
        }
        
//        [self setNeedsLayout];
//        [self layoutIfNeeded];
    }
    
    [self setupSwitch];
}

- (CGRect)switchFrameFromCurrentStyle {
    CGRect frame = self.frame;
    if (self.style == CCCSwitchStyleDefault) {
        frame.size.width = 60.0;
        frame.size.height = 40.0;
    }
    else if (self.style == CCCSwitchStyleValue1) {
        frame.size.width = 100.0;
        frame.size.height = 70.0;
    }
    else if (self.style == CCCSwitchStyleValue2) {
        frame.size.width = 100.0;
        frame.size.height = 50.0;
    }
    else if (self.style == CCCSwitchStyleValue3) {
        frame.size.width = 90.0;
        frame.size.height = 100.0;
    }
    else if (self.style == CCCSwitchStylePowerKey) {
        frame.size.width = MIN(frame.size.width, frame.size.height);
        if (frame.size.width <= 0) {
            frame.size.width = 60.0;
        }
        frame.size.height = frame.size.width;
    }
    
    frame.origin.x = (CGRectGetWidth(self.frame)-CGRectGetWidth(frame))/2.0;
    frame.origin.y = (CGRectGetHeight(self.frame)-CGRectGetHeight(frame))/2.0;
    
    return frame;
}

- (void)setupSwitch {
    [self.contentView.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    if (self.style == CCCSwitchStyleDefault) {
        CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
        backgroundLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.contentView.bounds)-20, 10);
        backgroundLayer.position = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2.0, CGRectGetHeight(self.contentView.bounds)/2.0);
        CGMutablePathRef pathBKLayer = CGPathCreateMutable();
        CGPathAddRoundedRect(pathBKLayer, &CGAffineTransformIdentity, backgroundLayer.bounds, CGRectGetHeight(backgroundLayer.bounds)/2.0, CGRectGetHeight(backgroundLayer.bounds)/2.0);
        backgroundLayer.path = pathBKLayer;
        CGPathRelease(pathBKLayer);
        backgroundLayer.fillColor = [UIColor whiteColor].CGColor;
        backgroundLayer.strokeColor = [UIColor blackColor].CGColor;
        [self.contentView.layer addSublayer:backgroundLayer];
        self.backgroundLayer = backgroundLayer;
        
        CALayer *switchLayer = [CALayer layer];
        switchLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(backgroundLayer.bounds), CGRectGetHeight(backgroundLayer.bounds)-1);
        switchLayer.position = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2.0, CGRectGetHeight(self.contentView.bounds)/2.0);
        switchLayer.cornerRadius = CGRectGetHeight(switchLayer.bounds)/2.0;
        switchLayer.backgroundColor = self.onTintColor.CGColor;
        [self.contentView.layer addSublayer:switchLayer];
        self.switchLayer = switchLayer;
        
        CAShapeLayer *thumbLayer = [CAShapeLayer layer];
        thumbLayer.bounds = CGRectMake(0, 0, 25, 25);
        thumbLayer.position = CGPointMake(CGRectGetMinX(self.switchLayer.frame), CGRectGetHeight(self.contentView.bounds)/2.0);
        thumbLayer.contentsGravity = kCAGravityResizeAspect;
        thumbLayer.contents = nil;
        CGMutablePathRef pathThumbLayer = CGPathCreateMutable();
        CGPathAddEllipseInRect(pathThumbLayer, &CGAffineTransformIdentity, thumbLayer.bounds);
        thumbLayer.path = pathThumbLayer;
        CGPathRelease(pathThumbLayer);
        thumbLayer.fillColor = [UIColor whiteColor].CGColor;
        thumbLayer.strokeColor = [UIColor blackColor].CGColor;
        [self.contentView.layer addSublayer:thumbLayer];
        self.thumbLayer = thumbLayer;
    }
    else if (self.style == CCCSwitchStyleValue1) {
        CALayer *backgroundLayer = [CALayer layer];
        backgroundLayer.frame = CGRectInset(self.contentView.bounds, 5, 5);
        backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
        backgroundLayer.borderColor = [UIColor blackColor].CGColor;
        backgroundLayer.borderWidth = 2.0;
        [self.contentView.layer addSublayer:backgroundLayer];
        self.backgroundLayer = backgroundLayer;
        
        CATransformLayer *switchLayer = [CATransformLayer layer];
        switchLayer.frame = CGRectInset(self.contentView.bounds, 10, 10);
        
        [self addSublayersOnSwitchLayer:switchLayer];
        
        [self.contentView.layer addSublayer:switchLayer];
        self.switchLayer = switchLayer;
    }
    else if (self.style == CCCSwitchStyleValue2) {
        CALayer *backgroundLayer = [CALayer layer];
        backgroundLayer.frame = CGRectInset(self.contentView.bounds, 5, 5);
        backgroundLayer.backgroundColor = [UIColor whiteColor].CGColor;
        backgroundLayer.borderColor = [UIColor blackColor].CGColor;
        backgroundLayer.borderWidth = 2.0;
        [self.contentView.layer addSublayer:backgroundLayer];
        self.backgroundLayer = backgroundLayer;
        
        CATransformLayer *switchLayer = [CATransformLayer layer];
        switchLayer.frame = CGRectInset(self.contentView.bounds, 10, 10);
        
        [self addSublayersOnSwitchLayer:switchLayer];
        
        [self.contentView.layer addSublayer:switchLayer];
        self.switchLayer = switchLayer;
    }
    else if (self.style == CCCSwitchStyleValue3) {
        
    }
    else if (self.style == CCCSwitchStylePowerKey) {
        CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
        backgroundLayer.frame = CGRectInset(self.contentView.bounds, CGRectGetWidth(self.contentView.bounds)*0.05, CGRectGetWidth(self.contentView.bounds)*0.05);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, backgroundLayer.bounds);
        backgroundLayer.path = path;
        CGPathRelease(path);
        backgroundLayer.strokeColor = [UIColor blackColor].CGColor;
        backgroundLayer.fillColor = [UIColor whiteColor].CGColor;
        backgroundLayer.lineWidth = CGRectGetWidth(self.contentView.bounds)*0.1;
        [self.contentView.layer addSublayer:backgroundLayer];
        self.backgroundLayer = backgroundLayer;
        
        CALayer *switchLayer = [CALayer layer];
        switchLayer.frame = CGRectInset(self.contentView.bounds, CGRectGetWidth(self.contentView.bounds)*0.1, CGRectGetWidth(self.contentView.bounds)*0.1);
        UIImage *image = powerKeyImageInSize(CGSizeApplyAffineTransform(self.contentView.bounds.size, CGAffineTransformMakeScale(2.0, 2.0)));
        switchLayer.contentsGravity = kCAGravityResizeAspect;
        switchLayer.contents = (id)image.CGImage;
        [self.contentView.layer addSublayer:switchLayer];
        self.switchLayer = switchLayer;
        
        switchLayer.shadowColor = self.onTintColor.CGColor;
        switchLayer.shadowOpacity = 0.8;
        path = CGPathCreateMutable();
        CGRect shadowRect = CGRectInset(switchLayer.bounds, -3, -3);
        shadowRect.origin.y += 3;
        CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, shadowRect);
        switchLayer.shadowPath = path;
        CGPathRelease(path);
        
    }
    
    [self setupOn];
}

- (void)addSublayersOnSwitchLayer:(CALayer*)switchLayer {
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1/500.0;
//    perspective = CATransform3DRotate(perspective, atan(20/CGRectGetWidth(switchLayer.frame)), 0, 1, 0);
    switchLayer.transform = perspective;
    
    perspective = CATransform3DIdentity;
    perspective.m34 = -1/500.0;
    perspective = CATransform3DRotate(perspective, 70*M_PI/180.0, 1, 0, 0);
//    perspective = CATransform3DRotate(perspective, 20*M_PI/180.0, 0, 0, 1);
//    perspective = CATransform3DRotate(perspective, 45*M_PI/180.0, 0, 1, 0);
//    self.layer.sublayerTransform = perspective;
    
    if (self.style == CCCSwitchStyleValue1) {
        CALayer *sublayer = [CALayer layer];
        sublayer.frame = switchLayer.bounds;
        sublayer.backgroundColor = [UIColor whiteColor].CGColor;
        sublayer.borderColor = [UIColor blackColor].CGColor;
        sublayer.borderWidth = 2.0;
        CATransform3D transform = CATransform3DMakeTranslation(0, 0, 10);
        sublayer.transform = transform;
        [switchLayer addSublayer:sublayer];
        
        CALayer *onDirectionLayer = [CALayer layer];
        onDirectionLayer.frame = CGRectMake(CGRectGetWidth(sublayer.frame)*0.8, CGRectGetHeight(sublayer.frame)*0.25, 10, CGRectGetHeight(sublayer.frame)*0.5);
        onDirectionLayer.backgroundColor = [UIColor clearColor].CGColor;
        onDirectionLayer.cornerRadius = CGRectGetWidth(onDirectionLayer.frame)/2.0;
        onDirectionLayer.borderColor = [UIColor blackColor].CGColor;
        onDirectionLayer.borderWidth = 2.0;
        [sublayer addSublayer:onDirectionLayer];
        
        sublayer.shadowColor = [UIColor blackColor].CGColor;
        sublayer.shadowOpacity = 1.0;
        sublayer.shadowOffset = CGSizeMake(-3, 1);
    }
    else if (self.style == CCCSwitchStyleValue2) {
        CGFloat angle = 2*asin(10/(CGRectGetWidth(switchLayer.bounds)/2.0+1));
        
        CGFloat w = (CGRectGetWidth(switchLayer.frame)/2.0)*cos(angle)+1;
        
        CALayer *sublayer = [CALayer layer];
        sublayer.frame = CGRectMake(CGRectGetWidth(self.contentView.bounds)/2.0-w, switchLayer.frame.origin.y, 2*w, switchLayer.frame.size.height);
        sublayer.backgroundColor = [UIColor whiteColor].CGColor;
        sublayer.borderColor = [UIColor blackColor].CGColor;
        sublayer.borderWidth = 1.0;
        sublayer.name = @"shadowLayer";
        [self.contentView.layer insertSublayer:sublayer below:switchLayer];
        
        sublayer.shadowColor = [UIColor blackColor].CGColor;
        sublayer.shadowOpacity = 1.0;
        sublayer.shadowOffset = CGSizeMake(-4, 1);
        
        CALayer *sublayer0 = [CALayer layer];
        sublayer0.anchorPoint = CGPointMake(1, 0.5);
        sublayer0.frame = CGRectMake(0, 0, CGRectGetWidth(switchLayer.bounds)/2.0+1, CGRectGetHeight(switchLayer.bounds));
        sublayer0.backgroundColor = [UIColor whiteColor].CGColor;
        sublayer0.borderColor = [UIColor blackColor].CGColor;
        sublayer0.borderWidth = 2.0;
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DRotate(transform, asin(10/CGRectGetWidth(sublayer0.frame)), 0, 1, 0);
        sublayer0.transform = transform;
        sublayer0.name = @"sublayer0";
        [switchLayer addSublayer:sublayer0];
        
        sublayer0.shadowColor = [UIColor blackColor].CGColor;
        sublayer0.shadowOpacity = 1.0;
        sublayer0.shadowOffset = CGSizeMake(-4, 0);
        
        CALayer *offSymbolLayer = [CALayer layer];
        offSymbolLayer.frame = CGRectMake(CGRectGetWidth(sublayer0.frame)*0.1, CGRectGetHeight(sublayer0.frame)/2.0-5, 10, 10);
        offSymbolLayer.backgroundColor = [UIColor clearColor].CGColor;
        offSymbolLayer.cornerRadius = CGRectGetHeight(offSymbolLayer.frame)/2.0;
        offSymbolLayer.borderColor = [UIColor blackColor].CGColor;
        offSymbolLayer.borderWidth = 2.0;
        [sublayer0 addSublayer:offSymbolLayer];
        
        CALayer *sublayer1 = [CALayer layer];
        sublayer1.anchorPoint = CGPointMake(0, 0.5);
        sublayer1.frame = CGRectMake(CGRectGetWidth(switchLayer.bounds)/2.0-1, 0, CGRectGetWidth(switchLayer.bounds)/2.0+1, CGRectGetHeight(switchLayer.bounds));
        sublayer1.backgroundColor = [UIColor whiteColor].CGColor;
        sublayer1.borderColor = [UIColor blackColor].CGColor;
        sublayer1.borderWidth = 2.0;
        transform = CATransform3DIdentity;
        transform = CATransform3DRotate(transform, -asin(10/CGRectGetWidth(sublayer1.frame)), 0, 1, 0);
        sublayer1.transform = transform;
        sublayer1.name = @"sublayer1";
        [switchLayer addSublayer:sublayer1];
        
        sublayer1.shadowColor = [UIColor blackColor].CGColor;
        sublayer1.shadowOpacity = 1.0;
        sublayer1.shadowOffset = CGSizeMake(0, 0);
        
        CALayer *onSymbolLayer = [CALayer layer];
        onSymbolLayer.frame = CGRectMake(CGRectGetWidth(sublayer1.frame)*0.7, CGRectGetHeight(sublayer1.frame)/2.0-1, CGRectGetWidth(sublayer1.frame)*0.2, 2);
        onSymbolLayer.backgroundColor = [UIColor blackColor].CGColor;
        [sublayer1 addSublayer:onSymbolLayer];
        
//        CALayer *tmpLayer = [CALayer layer];
//        tmpLayer.anchorPoint = CGPointMake(1, 0.5);
//        tmpLayer.frame = CGRectMake((CGRectGetWidth(switchLayer.bounds)-CGRectGetWidth(sublayer.frame))/2.0, (CGRectGetHeight(switchLayer.bounds)-CGRectGetHeight(sublayer.frame))/2.0, CGRectGetWidth(sublayer.frame), CGRectGetHeight(sublayer.frame));
//        tmpLayer.backgroundColor = [UIColor colorWithRed:1.000 green:0.000 blue:0.000 alpha:0.400].CGColor;
//        [switchLayer addSublayer:tmpLayer];
//        transform = CATransform3DIdentity;
//        transform = CATransform3DRotate(transform, -(M_PI_2-angle/2.0), 0, 1, 0);
//        transform = CATransform3DTranslate(transform, 50, 0, 0);
//        tmpLayer.transform = transform;
    }
}

- (void)setupSwitchOnTintColor {
    if (self.style == CCCSwitchStyleDefault) {
        self.switchLayer.backgroundColor = self.onTintColor.CGColor;
    }
    else if (self.style == CCCSwitchStyleValue1) {
        CALayer *sublayer = [self.switchLayer.sublayers firstObject];
        CALayer *onDirectionLayer = [sublayer.sublayers firstObject];
        
        if (self.isOn) {
            onDirectionLayer.backgroundColor = self.onTintColor.CGColor;
        }
    }
    else if (self.style == CCCSwitchStyleValue2) {
        
    }
    else if (self.style == CCCSwitchStyleValue3) {
        
    }
    else if (self.style == CCCSwitchStylePowerKey) {
        CAShapeLayer *backgroundLayer = (CAShapeLayer*)self.backgroundLayer;
        if (self.isOn) {
            backgroundLayer.fillColor = self.onTintColor.CGColor;
        }
        
        self.switchLayer.shadowColor = self.onTintColor.CGColor;
    }
}

- (void)setupOn {
    if (self.style == CCCSwitchStyleDefault) {
        CALayer *switchLayer = self.switchLayer;
        CGFloat width = CGRectGetWidth(self.backgroundLayer.bounds)*(self.isOn%2);
        
        switchLayer.frame = CGRectMake(switchLayer.frame.origin.x, switchLayer.frame.origin.y, width, switchLayer.frame.size.height);
        
        width = (width <= CGRectGetHeight(switchLayer.bounds))? CGRectGetHeight(switchLayer.bounds): width;
        self.thumbLayer.position = CGPointMake(width+CGRectGetMinX(switchLayer.frame)-5, self.thumbLayer.position.y);
    }
    else if (self.style == CCCSwitchStyleValue1) {
        CALayer *sublayer = [self.switchLayer.sublayers firstObject];
        CALayer *onDirectionLayer = [sublayer.sublayers firstObject];
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = -1/500.0;
        
        if (self.isOn) {
            sublayer.shadowOffset = CGSizeMake(-3, 1);
            onDirectionLayer.backgroundColor = self.onTintColor.CGColor;
            perspective = CATransform3DRotate(perspective, atan(20/CGRectGetWidth(self.switchLayer.frame)), 0, 1, 0);
        }
        else {
            sublayer.shadowOffset = CGSizeMake(3, 1);
            onDirectionLayer.backgroundColor = [UIColor clearColor].CGColor;
            perspective = CATransform3DRotate(perspective, -atan(20/CGRectGetWidth(self.switchLayer.frame)), 0, 1, 0);
        }
        self.switchLayer.transform = perspective;
    }
    else if (self.style == CCCSwitchStyleValue2) {
        CATransform3D perspective = CATransform3DIdentity;
        perspective.m34 = -1/500.0;
        
        CGFloat angle = asin(10/(CGRectGetWidth(self.switchLayer.bounds)/2.0+1));
        
        if (self.isOn) {
            perspective = CATransform3DRotate(perspective, angle, 0, 1, 0);
            for (CALayer *shadowLayer in self.contentView.layer.sublayers) {
                if ([shadowLayer.name isEqualToString:@"shadowLayer"]) {
                    shadowLayer.shadowOffset = CGSizeMake(-4, 1);
                    break;
                }
            }
            for (CALayer *sublayer in self.switchLayer.sublayers) {
                if ([sublayer.name isEqualToString:@"sublayer1"]) {
                    sublayer.shadowOffset = CGSizeMake(0, 0);
                }
                else if ([sublayer.name isEqualToString:@"sublayer0"]) {
                    sublayer.shadowOffset = CGSizeMake(-4, 0);
                }
            }
        }
        else {
            perspective = CATransform3DRotate(perspective, -angle, 0, 1, 0);
            for (CALayer *shadowLayer in self.contentView.layer.sublayers) {
                if ([shadowLayer.name isEqualToString:@"shadowLayer"]) {
                    shadowLayer.shadowOffset = CGSizeMake(4, 1);
                    break;
                }
            }
            for (CALayer *sublayer in self.switchLayer.sublayers) {
                if ([sublayer.name isEqualToString:@"sublayer0"]) {
                    sublayer.shadowOffset = CGSizeMake(0, 0);
                }
                else if ([sublayer.name isEqualToString:@"sublayer1"]) {
                    sublayer.shadowOffset = CGSizeMake(4, 0);
                }
            }
        }
        self.switchLayer.transform = perspective;
    }
    else if (self.style == CCCSwitchStyleValue3) {
        
    }
    else if (self.style == CCCSwitchStylePowerKey) {
        CAShapeLayer *backgroundLayer = (CAShapeLayer*)self.backgroundLayer;
        if (self.isOn) {
            backgroundLayer.fillColor = self.onTintColor.CGColor;
            self.switchLayer.shadowOpacity = 0.8;
        }
        else {
            backgroundLayer.fillColor = [UIColor whiteColor].CGColor;
            self.switchLayer.shadowOpacity = 0.0;
        }
    }
}

#pragma mark - Traking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
#if !TARGET_OS_TV
    [super beginTrackingWithTouch:touch withEvent:event];
#endif
    
    _didDrag = NO;
    CGPoint currentPoint = [touch locationInView:self];
    
    _valueChanged = NO;
    if (self.style == CCCSwitchStyleValue1) {
        if (currentPoint.x < self.bounds.size.width/2.0 && self.isOn) {
            self.on = NO;
            _valueChanged = YES;
        }
        else if (currentPoint.x >= self.bounds.size.width/2.0 && !self.isOn) {
            self.on = YES;
            _valueChanged = YES;
        }
    }
    else if (self.style == CCCSwitchStyleValue2) {
        if (currentPoint.x < self.bounds.size.width/2.0 && self.isOn) {
            self.on = NO;
            _valueChanged = YES;
        }
        else if (currentPoint.x >= self.bounds.size.width/2.0 && !self.isOn) {
            self.on = YES;
            _valueChanged = YES;
        }
    }
    else if (self.style == CCCSwitchStyleValue3) {
        
    }
    
    
    
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
#if !TARGET_OS_TV
    [super continueTrackingWithTouch:touch withEvent:event];
#endif
    
    _didDrag = YES;
    CGPoint currentPoint = [touch locationInView:self];
    
    //valueChanged = NO;
    if (self.style == CCCSwitchStyleDefault) {
        if (currentPoint.x < self.bounds.size.width/2.0 && self.isOn) {
            self.on = NO;
            _valueChanged = YES;
        }
        else if (currentPoint.x >= self.bounds.size.width/2.0 && !self.isOn) {
            self.on = YES;
            _valueChanged = YES;
        }
    }
    else if (self.style == CCCSwitchStyleValue1) {
        if (currentPoint.x < self.bounds.size.width/2.0 && self.isOn) {
            self.on = NO;
            _valueChanged = YES;
        }
        else if (currentPoint.x >= self.bounds.size.width/2.0 && !self.isOn) {
            self.on = YES;
            _valueChanged = YES;
        }
    }
    else if (self.style == CCCSwitchStyleValue2) {
        if (currentPoint.x < self.bounds.size.width/2.0 && self.isOn) {
            self.on = NO;
            _valueChanged = YES;
        }
        else if (currentPoint.x >= self.bounds.size.width/2.0 && !self.isOn) {
            self.on = YES;
            _valueChanged = YES;
        }
    }
    else if (self.style == CCCSwitchStyleValue3) {
        
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
#if !TARGET_OS_TV
    [super endTrackingWithTouch:touch withEvent:event];
#endif
    
    CGPoint currentPoint = [touch locationInView:self];
    
    if (self.style == CCCSwitchStyleDefault && !_didDrag) {
        self.on = !self.on;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if (self.style == CCCSwitchStylePowerKey) {
        CGFloat lengthToCenter = sqrt(pow((currentPoint.x-CGRectGetWidth(self.bounds)/2.0), 2.0)+pow((currentPoint.y-CGRectGetHeight(self.bounds)/2.0), 2.0));
        if (lengthToCenter < MIN(CGRectGetWidth(self.switchLayer.bounds)/2.0, CGRectGetHeight(self.switchLayer.bounds)/2.0)-1) {
            self.on = !self.on;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
    else if (_valueChanged) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
#if !TARGET_OS_TV
    [super cancelTrackingWithEvent:event];
#endif
}

@end
