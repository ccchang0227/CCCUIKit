//
//  CCCRatingControl.m
//
//  Created by RealTouch on 2014/10/20.
//  Copyright (c) 2014年 RealTouch. All rights reserved.
//

#import "CCCRatingControl.h"


#define kCCCRatingControlDisabledAlpha 0.5


UIImage *starImage(CGSize size, UIColor *strokeColor, UIColor *fillColor, BOOL fill) {
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [fillColor setFill];
    [strokeColor setStroke];
    
    CGContextSetLineWidth(context, 1.0);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    // 确定中心点
    CGPoint centerPoint = CGPointMake(size.width/2.0, size.height/2.0);
    // 确定半径
    CGFloat radius = MIN(size.width/2.0, size.height/2.0);
    // 五角星到顶点
    CGPoint p1 = CGPointMake(centerPoint.x, centerPoint.y-radius);
    CGContextMoveToPoint(context, p1.x, p1.y);
    // 五角星每个点之间点夹角，采用弧度计算。没两个点进行连线就可以画出五角星
    // 点与点之间点夹角为2*M_PI/5.0，
    CGFloat angle = 2*2*M_PI/5.0;
    CGFloat maxLine = 0.0;
    CGPoint p2;
    p2.x = centerPoint.x-sinf(angle)*radius;
    p2.y = centerPoint.y-cosf(angle)*radius;
    maxLine = sqrt(pow((p1.x-p2.x), 2.0)+pow((p1.y-p2.y), 2.0));
    
    CGFloat innerLength = maxLine/(2+sqrt(5.0));
    innerLength /= 2.0;
    angle = 2*M_PI/10.0;
    CGFloat radiusCorner = innerLength/sinf(angle);
    for (int i = 1; i <= 10; i ++) {
        if (i%2 != 0) {
            CGFloat x = centerPoint.x-sinf(i*angle)*radiusCorner;
            CGFloat y = centerPoint.y-cosf(i*angle)*radiusCorner;
            CGContextAddLineToPoint(context, x, y);
        }
        else {
            CGFloat x = centerPoint.x-sinf(i*angle)*radius;
            CGFloat y = centerPoint.y-cosf(i*angle)*radius;
            CGContextAddLineToPoint(context, x, y);
        }
    }
    if (fill) {
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    else {
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@interface CCCRatingControl () {
    
    UIViewContentMode _contentMode;
    
    CGRect _contentRect;
    
    CGPoint _currentPoint;
}

@property (retain, nonatomic) NSArray *itemLayers;

+ (UIImage *)_defaultRatingImage;
+ (UIImage *)_defaultHighlightedRatingImage;

@end

@implementation CCCRatingControl
@synthesize contentVerticalAlignment = _contentVerticalAlignment;
@synthesize contentHorizontalAlignment = _contentHorizontalAlignment;

- (instancetype)init {
    self = [self initWithRatingImage:nil
              highlightedRatingImage:nil];
    
    if (self) {
        [self _setup];
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithRatingImage:(UIImage *)image
             highlightedRatingImage:(UIImage *)highlightedRatingImage {
    
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self _setup];
        
        _ratingImage = [image retain];
        _highlightedRatingImage = [highlightedRatingImage retain];
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithRatingImage:(UIImage *)image
             highlightedRatingImage:(UIImage *)highlightedRatingImage
                       maximumValue:(NSInteger)maximumValue
                      fractionNumer:(NSInteger)fractionNumer {
    
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self _setup];
        
        _maximumValue = maximumValue;
        _fractionNumber = fractionNumer;
        _ratingImage = [image retain];
        _highlightedRatingImage = [highlightedRatingImage retain];
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [self initWithFrame:frame
                   ratingImage:nil
        highlightedRatingImage:nil];
    
    if (self) {
        [self _setup];
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                  ratingImage:(UIImage *)image
       highlightedRatingImage:(UIImage *)highlightedRatingImage {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
        
        _ratingImage = [image retain];
        _highlightedRatingImage = [highlightedRatingImage retain];
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                  ratingImage:(UIImage *)image
       highlightedRatingImage:(UIImage *)highlightedRatingImage
                 maximumValue:(NSInteger)maximumValue
                fractionNumer:(NSInteger)fractionNumer {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
        
        _maximumValue = maximumValue;
        _fractionNumber = fractionNumer;
        _ratingImage = [image retain];
        _highlightedRatingImage = [highlightedRatingImage retain];
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    return self;
}

- (void)dealloc {

#if !__has_feature(objc_arc)
    [_ratingImage release];
    [_highlightedRatingImage release];
    [_itemLayers release];
    [super dealloc];
#endif
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [self _setupRatingItems];
    [self _setupRatingHighlighted];
}

#pragma mark - Static

+ (UIImage*)_defaultRatingImage {
    return starImage(CGSizeMake(80, 80), [UIColor yellowColor], [UIColor whiteColor], YES);
}

+ (UIImage*)_defaultHighlightedRatingImage {
    return starImage(CGSizeMake(80, 80), [UIColor yellowColor], [UIColor yellowColor], YES);
}

#pragma mark - Getter

- (UIViewContentMode)contentMode {
    return _contentMode;
}

- (CGRect)contentRect {
    return _contentRect;
}

#pragma mark - Setter

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    [self _setupRatingEnabled:enabled];
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    if (_contentMode != contentMode) {
        _contentMode = contentMode;
        
        [self _setupRatingContentMode:_contentMode];
    }
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    if (_contentVerticalAlignment != contentVerticalAlignment) {
        _contentVerticalAlignment = contentVerticalAlignment;
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    [super setContentVerticalAlignment:contentVerticalAlignment];
}

- (void)setContentHorizontalAlignment:(UIControlContentHorizontalAlignment)contentHorizontalAlignment {
    if (_contentHorizontalAlignment != contentHorizontalAlignment) {
        _contentHorizontalAlignment = contentHorizontalAlignment;
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
    
    [super setContentHorizontalAlignment:contentHorizontalAlignment];
}

- (void)setValue:(CGFloat)value {
    CGFloat newValue = (value < 0? 0: (value > self.maximumValue? self.maximumValue: value));
    
    double intPart;
    double fracPart = modf(newValue, &intPart);
    double newIntPart;
    if (modf(fracPart*self.fractionNumber, &newIntPart) > 0.0) {
        newValue = intPart+newIntPart/(CGFloat)self.fractionNumber;
    }
    _value = newValue;
    
    [self _setupRatingHighlighted];
}

- (void)setMaximumValue:(NSUInteger)maximumValue {
    if (maximumValue < 1) {
        _maximumValue = kCCCRatingControlDefaultMaximumValue;
    }
    else {
        _maximumValue = maximumValue;
    }
    [self _setupRatingItems];
    
    self.value = self.value;
}

- (void)setFractionNumber:(NSUInteger)fractionNumber {
    if (fractionNumber < 1) {
        _fractionNumber = kCCCRatingControlDefaultFractionNumber;
    }
    else {
        _fractionNumber = fractionNumber;
    }
    
    self.value = self.value;
}

- (void)setRatingImage:(UIImage *)ratingImage {
    if (_ratingImage != ratingImage) {
#if !__has_feature(objc_arc)
        if (_ratingImage) {
            [_ratingImage release];
        }
#endif
        _ratingImage = [ratingImage retain];
        
        [self _setupRatingHighlighted];
    }
}

- (void)setHighlightedRatingImage:(UIImage *)highlightedRatingImage {
    if (_highlightedRatingImage != highlightedRatingImage) {
#if !__has_feature(objc_arc)
        if (_highlightedRatingImage) {
            [_highlightedRatingImage release];
        }
#endif
        _highlightedRatingImage = [highlightedRatingImage retain];
        
        [self _setupRatingHighlighted];
    }
}

- (void)setUnitSize:(CGSize)unitSize {
    if (!CGSizeEqualToSize(_unitSize, unitSize)) {
        _unitSize = unitSize;
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
}

- (void)setEdgeBetweenUnits:(CGFloat)edgeBetweenUnits {
    if (_edgeBetweenUnits != edgeBetweenUnits) {
        _edgeBetweenUnits = edgeBetweenUnits;
        
        [self _setupRatingItems];
        [self _setupRatingHighlighted];
    }
}

#pragma mark - Override

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    
    CGSize unitSize = self.unitSize;
    if (CGSizeEqualToSize(unitSize, CGSizeZero)) {
        unitSize = CGSizeMake(30, 30);
    }
    CGFloat edge = self.edgeBetweenUnits;
    CGFloat contentWidth = unitSize.width*self.maximumValue+edge*(self.maximumValue-1);
    if (contentWidth < fitSize.width) {
        fitSize.width = contentWidth;
    }
    if (unitSize.height < fitSize.height) {
        fitSize.height = unitSize.height;
    }
    
    return fitSize;
}

- (CGSize)intrinsicContentSize {
    CGSize unitSize = self.unitSize;
    if (CGSizeEqualToSize(unitSize, CGSizeZero)) {
        unitSize = CGSizeMake(30, 30);
    }
    CGFloat edge = self.edgeBetweenUnits;
    CGFloat contentWidth = unitSize.width*self.maximumValue+edge*(self.maximumValue-1);
    
    return CGSizeMake(contentWidth, unitSize.height);
}

#pragma mark - Other

- (UIImage*)_combinedImageFromLeftSrcImage:(UIImage *)leftSrcImage
                             rightSrcImage:(UIImage *)rightSrcImage
                                     ratio:(CGFloat)ratio {
    
    CGSize size = CGSizeMake(CGImageGetWidth(leftSrcImage.CGImage), CGImageGetHeight(leftSrcImage.CGImage));
    
    UIGraphicsBeginImageContextWithOptions(size, NO, leftSrcImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1, -1);
    
    CGImageRef clipLeftSrcImage = CGImageCreateWithImageInRect(leftSrcImage.CGImage, CGRectMake(0, 0, size.width*ratio, size.height));
    CGContextDrawImage(context, CGRectMake(0, 0, size.width*ratio, size.height), clipLeftSrcImage);
    CGImageRelease(clipLeftSrcImage);
    clipLeftSrcImage = NULL;
    
    CGImageRef clipRightSrcImage = CGImageCreateWithImageInRect(rightSrcImage.CGImage, CGRectMake(CGImageGetWidth(rightSrcImage.CGImage)*ratio, 0, CGImageGetWidth(rightSrcImage.CGImage)*(1-ratio), CGImageGetHeight(rightSrcImage.CGImage)));
    CGContextDrawImage(context, CGRectMake(size.width*ratio, 0, size.width*(1-ratio), size.height), clipRightSrcImage);
    CGImageRelease(clipRightSrcImage);
    clipRightSrcImage = NULL;
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    image = [UIImage imageWithCGImage:image.CGImage scale:leftSrcImage.scale orientation:image.imageOrientation];
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Setup

- (void)_setup {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    _contentMode = UIViewContentModeScaleAspectFit;
    [super setContentMode:UIViewContentModeRedraw];
    
    _value = 0.0;
    _maximumValue = kCCCRatingControlDefaultMaximumValue;
    _fractionNumber = kCCCRatingControlDefaultFractionNumber;
    _ratingImage = nil;
    //starImage(CGSizeMake(48, 48), [UIColor colorWithRed:0.541 green:0.784 blue:0.761 alpha:1.0], [UIColor whiteColor], YES);
    _highlightedRatingImage = nil;
    //starImage(CGSizeMake(48, 48), [UIColor colorWithRed:0.541 green:0.784 blue:0.761 alpha:1.0], [UIColor colorWithRed:0.541 green:0.784 blue:0.761 alpha:1.0], YES);
    
    _unitSize = CGSizeMake(30, 30);
    _edgeBetweenUnits = 0.0;
    
    _continuous = YES;
}

- (void)_setupRatingItems {
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return;
    }
    
    UIControlContentVerticalAlignment verticalAlignment = self.contentVerticalAlignment;
    UIControlContentHorizontalAlignment horizontalAlignment = self.contentHorizontalAlignment;
    
    CGSize size = self.unitSize;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = CGSizeMake(30, 30);
    }
    CGFloat edge = self.edgeBetweenUnits;
    CGFloat contentWidth = size.width*self.maximumValue+edge*(self.maximumValue-1);
    CGPoint offset = CGPointMake((CGRectGetWidth(self.bounds)-contentWidth)/2.0,
                                 (CGRectGetHeight(self.bounds)-size.height)/2.0);
    
    // adjust vertical size
    if (verticalAlignment == UIControlContentVerticalAlignmentFill) {
        size.height = CGRectGetHeight(self.bounds);
    }
    else if (offset.y < 0) {
        size.height = CGRectGetHeight(self.bounds);
    }
    // adjust horizontal size
    if (horizontalAlignment == UIControlContentHorizontalAlignmentFill) {
        contentWidth = CGRectGetWidth(self.bounds);
        
        edge = 0;
        size.width = CGRectGetWidth(self.bounds)/(CGFloat)self.maximumValue;
    }
    else if (offset.x < 0) {
        if (edge > 0) {
            edge = 0;
            contentWidth = size.width*self.maximumValue+edge*(self.maximumValue-1);
        }
        if (contentWidth > CGRectGetWidth(self.bounds)) {
            size.width = CGRectGetWidth(self.bounds)/(CGFloat)self.maximumValue;
            contentWidth = size.width*self.maximumValue+edge*(self.maximumValue-1);
        }
    }
    offset = CGPointMake((CGRectGetWidth(self.bounds)-contentWidth)/2.0,
                         (CGRectGetHeight(self.bounds)-size.height)/2.0);
    
    // adjust vertical offset
    switch (verticalAlignment) {
        case UIControlContentVerticalAlignmentTop:
            offset.y = 0;
            break;
        case UIControlContentVerticalAlignmentBottom:
            offset.y = CGRectGetHeight(self.bounds)-size.height;
            break;
        default:
            break;
    }
    // adjust horizontal offset
    switch (horizontalAlignment) {
        case UIControlContentHorizontalAlignmentLeft:
            offset.x = 0;
            break;
        case UIControlContentHorizontalAlignmentRight:
            offset.x = CGRectGetWidth(self.bounds)-contentWidth;
            break;
        default:
            break;
    }
    
    NSString *contentModeString = [self _contentModeStringByMappingFromContentMode:_contentMode];
    
    NSMutableArray *itemLayers = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < self.maximumValue; i ++) {
        CGFloat x = offset.x+i*(size.width+edge);
        
        CALayer *itemLayer = [CALayer layer];
        itemLayer.frame = CGRectMake(x, offset.y, size.width, size.height);
        itemLayer.backgroundColor = [UIColor clearColor].CGColor;
        itemLayer.opacity = self.isEnabled? 1.0: kCCCRatingControlDisabledAlpha;
        itemLayer.contents = (id)self.ratingImage.CGImage;
        if (!self.ratingImage) {
            itemLayer.contents = (id)CCCRatingControl._defaultRatingImage.CGImage;
        }
        itemLayer.contentsGravity = contentModeString;
        [self.layer addSublayer:itemLayer];
        [itemLayers addObject:itemLayer];
    }
    self.itemLayers = itemLayers;
    
    _contentRect = CGRectMake(offset.x, offset.y, contentWidth, size.height);
}

- (void)_setupRatingHighlighted {
    CGFloat value = self.value;
    
    UIImage *ratingImage = self.ratingImage;
    if (!self.ratingImage) {
        ratingImage = CCCRatingControl._defaultRatingImage;
    }
    UIImage *highlightedImage = self.highlightedRatingImage;
    if (!self.highlightedRatingImage) {
        highlightedImage = CCCRatingControl._defaultHighlightedRatingImage;
    }
    
    for (CALayer *itemLayer in self.itemLayers) {
        if (value >= 1.0) {
            itemLayer.contents = (id)highlightedImage.CGImage;
        }
        else if (value <= 0.0) {
            itemLayer.contents = (id)ratingImage.CGImage;
        }
        else {
            UIImage *combinedRatingImage = [self _combinedImageFromLeftSrcImage:highlightedImage
                                                                  rightSrcImage:ratingImage
                                                                          ratio:value];
            itemLayer.contents = (id)combinedRatingImage.CGImage;
        }
        
        value -= 1.0;
    }
}

- (void)_setupRatingEnabled:(BOOL)enabled {
    for (CALayer *itemLayer in self.itemLayers) {
        itemLayer.opacity = enabled? 1.0: kCCCRatingControlDisabledAlpha;
    }
}

- (NSString *)_contentModeStringByMappingFromContentMode:(UIViewContentMode)contentMode {
    NSDictionary *contentModeMap = @{@(UIViewContentModeTop):kCAGravityTop,
                                     @(UIViewContentModeBottom):kCAGravityBottom,
                                     @(UIViewContentModeRight):kCAGravityRight,
                                     @(UIViewContentModeLeft):kCAGravityLeft,
                                     @(UIViewContentModeCenter):kCAGravityCenter,
                                     @(UIViewContentModeTopLeft):kCAGravityTopLeft,
                                     @(UIViewContentModeTopRight):kCAGravityTopRight,
                                     @(UIViewContentModeBottomLeft):kCAGravityBottomLeft,
                                     @(UIViewContentModeBottomRight):kCAGravityBottomRight,
                                     @(UIViewContentModeRedraw):kCAGravityResizeAspect,
                                     @(UIViewContentModeScaleToFill):kCAGravityResize,
                                     @(UIViewContentModeScaleAspectFit):kCAGravityResizeAspect,
                                     @(UIViewContentModeScaleAspectFill):kCAGravityResizeAspectFill};
    
    NSString *contentModeString = [contentModeMap objectForKey:@(contentMode)];
    
    return contentModeString;
}

- (void)_setupRatingContentMode:(UIViewContentMode)contentMode {
    NSString *contentModeString = [self _contentModeStringByMappingFromContentMode:contentMode];
    for (CALayer *itemLayer in self.itemLayers) {
        itemLayer.contentsGravity = contentModeString;
    }
}

#pragma mark - Tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    _currentPoint = [touch locationInView:self];
    
    if (_currentPoint.x <= CGRectGetMinX(_contentRect)) {
        self.value = 0.0;
    }
    else if (_currentPoint.x >= CGRectGetMaxX(_contentRect)) {
        self.value = self.maximumValue;
    }
    else {
        self.value = ((_currentPoint.x-CGRectGetMinX(_contentRect))/CGRectGetWidth(_contentRect))*self.maximumValue;
    }
    
    if (self.isContinuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    
    _currentPoint = [touch locationInView:self];
    
    if (_currentPoint.x <= CGRectGetMinX(_contentRect)) {
        self.value = 0.0;
    }
    else if (_currentPoint.x >= CGRectGetMaxX(_contentRect)) {
        self.value = self.maximumValue;
    }
    else {
        self.value = ((_currentPoint.x-CGRectGetMinX(_contentRect))/CGRectGetWidth(_contentRect))*self.maximumValue;
    }
    
    if (self.isContinuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {

    if (!self.isContinuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    
    if (!self.isContinuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    [super cancelTrackingWithEvent:event];
}

@end
