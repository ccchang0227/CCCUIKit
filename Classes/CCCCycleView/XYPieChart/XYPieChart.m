//
//  XYPieChart.m
//  XYPieChart
//
//  Created by XY Feng on 2/24/12.
//  Copyright (c) 2012 Xiaoyang Feng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "XYPieChart.h"
#import <QuartzCore/QuartzCore.h>

@interface SliceLayer : CAShapeLayer
@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, strong) NSString  *text;
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate;
@end

@implementation SliceLayer
@synthesize text = _text;
@synthesize value = _value;
@synthesize percentage = _percentage;
@synthesize startAngle = _startAngle;
@synthesize endAngle = _endAngle;
@synthesize isSelected = _isSelected;
- (NSString*)description
{
    return [NSString stringWithFormat:@"value:%f, percentage:%0.0f, start:%f, end:%f", _value, _percentage, _startAngle/M_PI*180, _endAngle/M_PI*180];
}
+ (BOOL)needsDisplayForKey:(NSString *)key 
{
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    else {
        return [super needsDisplayForKey:key];
    }
}
- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer])
    {
        if ([layer isKindOfClass:[SliceLayer class]]) {
            self.startAngle = [(SliceLayer *)layer startAngle];
            self.endAngle = [(SliceLayer *)layer endAngle];
        }
    }
    return self;
}
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate
{
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    if(!currentAngle) currentAngle = from;
    [arcAnimation setFromValue:currentAngle];
    [arcAnimation setToValue:to];         
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    [self addAnimation:arcAnimation forKey:key];
    [self setValue:to forKey:key];
}
@end

@interface XYPieChart (Private)
- (void)updateTimerFired:(NSTimer *)timer;
- (SliceLayer *)createSliceLayer;
- (CGSize)sizeThatFitsString:(NSString *)string;
- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(CGFloat)value;
- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection;
@end

@implementation XYPieChart
{
    NSInteger _selectedSliceIndex;
    //pie view, contains all slices
    UIView  *_pieView;
    
    //animation control
    NSTimer *_animationTimer;
    NSMutableArray *_animations;
    
    // -- C.C.C.
    BOOL _dataLoaded;
    
    BOOL _shouldOverridePieRadius;
    BOOL _shouldOverridePieCenter;
    BOOL _shouldOverrideLabelFont;
    BOOL _shouldOverrideLabelRadius;
    BOOL _shouldOverrideSelectedSliceOffsetRadius;
    
    CGFloat _maxImageContentSize;
    CGFloat _minImageContentSize;
    // -- C.C.C.
}

static NSUInteger kDefaultSliceZOrder = 100;

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize startPieAngle = _startPieAngle;
@synthesize animationSpeed = _animationSpeed;
@synthesize pieCenter = _pieCenter;
@synthesize pieRadius = _pieRadius;
@synthesize showLabel = _showLabel;
@synthesize labelFont = _labelFont;
@synthesize labelShadowColor = _labelShadowColor;
@synthesize labelRadius = _labelRadius;
@synthesize selectedSliceStroke = _selectedSliceStroke;
@synthesize selectedSliceOffsetRadius = _selectedSliceOffsetRadius;
@synthesize showPercentage = _showPercentage;

// -- C.C.C.
@synthesize showAnimated = _showAnimated;
@synthesize sliceStrokeColor = _sliceStrokeColor;
@synthesize sliceStrokeWidth = _sliceStrokeWidth;
@synthesize verticalContent = _verticalContent;
// -- C.C.C.


static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle) 
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);
    
    return path;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _pieView = [[UIView alloc] initWithFrame:self.bounds];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self insertSubview:_pieView atIndex:0];
        
        _pieView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        /*
        _pieView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
         */
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        CGRect bounds = [[self layer] bounds];
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _labelRadius = _pieRadius/2;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
        _showLabel = YES;
        _showPercentage = YES;
        
        _showAnimated = YES;
        _sliceStrokeColor = [UIColor whiteColor];
        _sliceStrokeWidth = 0.0;
        _verticalContent = NO;
        _dataLoaded = NO;
        
        _shouldOverridePieRadius = YES;
        _shouldOverridePieCenter = YES;
        _shouldOverrideLabelFont = YES;
        _shouldOverrideLabelRadius = YES;
        _shouldOverrideSelectedSliceOffsetRadius = YES;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        _pieView = [[UIView alloc] initWithFrame:frame];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_pieView];
        
        _pieView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        /*
         _pieView.translatesAutoresizingMaskIntoConstraints = NO;
         [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
         [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
         */
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        self.pieRadius = MIN(frame.size.width/2, frame.size.height/2) - 10;
        self.pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _labelRadius = _pieRadius/2;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
        _showLabel = YES;
        _showPercentage = YES;
        
        _showAnimated = YES;
        _sliceStrokeColor = [UIColor whiteColor];
        _sliceStrokeWidth = 0.0;
        _verticalContent = NO;
        _dataLoaded = NO;
        
        _shouldOverridePieRadius = YES;
        _shouldOverridePieCenter = YES;
        _shouldOverrideLabelFont = YES;
        _shouldOverrideLabelRadius = YES;
        _shouldOverrideSelectedSliceOffsetRadius = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius
{
    self = [self initWithFrame:frame];
    if (self)
    {
        self.pieCenter = center;
        self.pieRadius = radius;
        
        _shouldOverridePieRadius = YES;
        _shouldOverridePieCenter = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _pieView = [[UIView alloc] initWithFrame:self.bounds];
        [_pieView setBackgroundColor:[UIColor clearColor]];
        [self insertSubview:_pieView atIndex:0];
        
        _pieView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        /*
         _pieView.translatesAutoresizingMaskIntoConstraints = NO;
         [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
         [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pieView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieView)]];
         */
        
        _selectedSliceIndex = -1;
        _animations = [[NSMutableArray alloc] init];
        
        _animationSpeed = 0.5;
        _startPieAngle = M_PI_2*3;
        _selectedSliceStroke = 3.0;
        
        CGRect bounds = [[self layer] bounds];
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _labelRadius = _pieRadius/2;
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
        _showLabel = YES;
        _showPercentage = YES;
        
        _showAnimated = YES;
        _sliceStrokeColor = [UIColor whiteColor];
        _sliceStrokeWidth = 0.0;
        _verticalContent = NO;
        _dataLoaded = NO;
        
        _shouldOverridePieRadius = YES;
        _shouldOverridePieCenter = YES;
        _shouldOverrideLabelFont = YES;
        _shouldOverrideLabelRadius = YES;
        _shouldOverrideSelectedSliceOffsetRadius = YES;
    }
    return self;
}

- (void)setPieCenter:(CGPoint)pieCenter
{
    [_pieView setCenter:pieCenter];
    _pieCenter = CGPointMake(_pieView.frame.size.width/2, _pieView.frame.size.height/2);
    
    _shouldOverridePieCenter = NO;
}

- (void)setPieRadius:(CGFloat)pieRadius
{
    _pieRadius = pieRadius;
    CGPoint origin = _pieView.frame.origin;
    CGRect frame = CGRectMake(origin.x+_pieCenter.x-pieRadius, origin.y+_pieCenter.y-pieRadius, pieRadius*2, pieRadius*2);
    _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    [_pieView setFrame:frame];
    [_pieView.layer setCornerRadius:_pieRadius];
    
    _maxImageContentSize = (2*M_PI*_pieRadius)/8.0;
    _minImageContentSize = (2*M_PI*_pieRadius)/20.0;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    double minAngle = 2*M_PI*[[pieLayers valueForKeyPath:@"@min.percentage"] doubleValue];
    double arcLength = minAngle*_pieRadius;
    if (arcLength < _minImageContentSize) {
        arcLength = _minImageContentSize;
    }
    if (arcLength > _maxImageContentSize) {
        arcLength = _maxImageContentSize;
    }
    
    [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
        
        CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
        CALayer *imageLayer = [[obj sublayers] objectAtIndex:1];
        
        [imageLayer setBounds:CGRectMake(0, 0, arcLength*0.8, arcLength*0.8)];
        imageLayer.cornerRadius = imageLayer.bounds.size.width/2.0;
        
        CGFloat interpolatedMidAngle = (obj.startAngle + obj.endAngle) / 2;
        [CATransaction setDisableActions:YES];
        [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
        [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(interpolatedMidAngle)), _pieCenter.y + ((_pieRadius*0.9) * sin(interpolatedMidAngle)))];
        
        [CATransaction setDisableActions:NO];
        
        [self updateLabelForLayer:obj value:obj.value];
    }];
    
    _shouldOverridePieRadius = NO;
}

- (void)setPieBackgroundColor:(UIColor *)color
{
    [_pieView setBackgroundColor:color];
}

- (void)setLabelRadius:(CGFloat)labelRadius {
    _labelRadius = labelRadius;
    _shouldOverrideLabelRadius = NO;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
        
        CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
        CALayer *imageLayer = [[obj sublayers] objectAtIndex:1];
        
        CGFloat interpolatedMidAngle = (obj.startAngle + obj.endAngle) / 2;
        [CATransaction setDisableActions:YES];
        [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
        [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(interpolatedMidAngle)), _pieCenter.y + ((_pieRadius*0.9) * sin(interpolatedMidAngle)))];
        
        if (_verticalContent) {
            labelLayer.anchorPoint = CGPointMake(0.7, 0.5);
            
            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
        }
        else {
            labelLayer.anchorPoint = CGPointMake(0.5, 0);
            
            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
        }
        
        [CATransaction setDisableActions:NO];
        
        [self updateLabelForLayer:obj value:obj.value];
    }];
}

- (void)setLabelFont:(UIFont *)labelFont {
    if (_labelFont != labelFont) {
        _labelFont = labelFont;
        _shouldOverrideLabelFont = NO;
        
        CALayer *parentLayer = [_pieView layer];
        NSArray *pieLayers = [parentLayer sublayers];
        
        [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
            [self updateLabelForLayer:obj value:obj.value];
        }];
    }
}

- (void)setSliceStrokeColor:(UIColor *)sliceStrokeColor {
    if (_sliceStrokeColor != sliceStrokeColor) {
        _sliceStrokeColor = sliceStrokeColor;
        
        CALayer *parentLayer = [_pieView layer];
        NSArray *pieLayers = [parentLayer sublayers];
        
        [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
            if (!obj.isSelected) {
                obj.strokeColor = _sliceStrokeColor.CGColor;
            }
        }];
    }
}

- (void)setSliceStrokeWidth:(CGFloat)sliceStrokeWidth {
    _sliceStrokeWidth = sliceStrokeWidth;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
        if (!obj.isSelected) {
            obj.lineWidth = _sliceStrokeWidth;
        }
    }];
}

- (void)setSelectedSliceOffsetRadius:(CGFloat)selectedSliceOffsetRadius {
    _selectedSliceOffsetRadius = selectedSliceOffsetRadius;
    _shouldOverrideSelectedSliceOffsetRadius = NO;
}

- (void)setVerticalContent:(BOOL)verticalContent {
    _verticalContent = verticalContent;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(SliceLayer * obj, NSUInteger idx, BOOL *stop) {
        
        CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
        CALayer *imageLayer = [[obj sublayers] objectAtIndex:1];
        
        CGFloat interpolatedMidAngle = (obj.startAngle + obj.endAngle) / 2;
        [CATransaction setDisableActions:YES];
        
        if (_verticalContent) {
            labelLayer.anchorPoint = CGPointMake(0.7, 0.5);
            
            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
        }
        else {
            labelLayer.anchorPoint = CGPointMake(0.5, 0);
            
            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
        }
        
        [CATransaction setDisableActions:NO];
        
        [self updateLabelForLayer:obj value:obj.value];
    }];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGRect bounds = [[self layer] bounds];
    if (_shouldOverridePieRadius) {
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        _shouldOverridePieRadius = YES;
    }
    if (_shouldOverridePieCenter) {
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        _shouldOverridePieCenter = YES;
    }
    if (_shouldOverrideLabelFont) {
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _shouldOverrideLabelFont = YES;
    }
    if (_shouldOverrideLabelRadius) {
        _labelRadius = _pieRadius/2;
    }
    if (_shouldOverrideSelectedSliceOffsetRadius) {
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
    }
    
    if (_dataLoaded) {
        [self reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = [[self layer] bounds];
    if (_shouldOverridePieRadius) {
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        _shouldOverridePieRadius = YES;
    }
    if (_shouldOverridePieCenter) {
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        _shouldOverridePieCenter = YES;
    }
    if (_shouldOverrideLabelFont) {
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        _shouldOverrideLabelFont = YES;
    }
    if (_shouldOverrideLabelRadius) {
        _labelRadius = _pieRadius/2;
    }
    if (_shouldOverrideSelectedSliceOffsetRadius) {
        _selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
    }
    
    if (_dataLoaded) {
        [self reloadData];
    }
}

#pragma mark - manage settings

- (void)setShowPercentage:(BOOL)showPercentage
{
    _showPercentage = showPercentage;
    for(SliceLayer *layer in _pieView.layer.sublayers) {
        [self updateLabelForLayer:layer value:layer.value];
    }
}

#pragma mark - Pie Reload Data With Animation

- (void)reloadData
{
    _dataLoaded = YES;
    
    if (_dataSource)
    {
        CALayer *parentLayer = [_pieView layer];
        NSArray *slicelayers = [parentLayer sublayers];
        
        _selectedSliceIndex = -1;
        [slicelayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SliceLayer *layer = (SliceLayer *)obj;
            if(layer.isSelected)
                [self setSliceDeselectedAtIndex:idx];
        }];
        
        double startToAngle = 0.0;
        double endToAngle = startToAngle;
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieChart:self];
        
        double sum = 0.0;
        double values[sliceCount];
        for (int index = 0; index < sliceCount; index++) {
            values[index] = [_dataSource pieChart:self valueForSliceAtIndex:index];
            sum += values[index];
        }
        
        double angles[sliceCount];
        double minAngle = 2*M_PI;
        for (int index = 0; index < sliceCount; index++) {
            double div;
            if (sum == 0)
                div = 0;
            else
                div = values[index] / sum; 
            angles[index] = M_PI * 2 * div;
            
            if (angles[index] < minAngle) {
                minAngle = angles[index];
            }
        }
        
        double arcLength = minAngle*_pieRadius;
        if (arcLength < _minImageContentSize) {
            arcLength = _minImageContentSize;
        }
        if (arcLength > _maxImageContentSize) {
            arcLength = _maxImageContentSize;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:_animationSpeed];
        
        [_pieView setUserInteractionEnabled:NO];
        
        __block NSMutableArray *layersToRemove = nil;
        
        BOOL isOnStart = ([slicelayers count] == 0 && sliceCount);
        NSInteger diff = sliceCount - [slicelayers count];
        layersToRemove = [NSMutableArray arrayWithArray:slicelayers];
        
        BOOL isOnEnd = ([slicelayers count] && (sliceCount == 0 || sum <= 0));
        if(isOnEnd)
        {
            for(SliceLayer *layer in _pieView.layer.sublayers){
                [self updateLabelForLayer:layer value:0];
                
                CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
                [imageLayer setBounds:CGRectMake(0, 0, arcLength*0.8, arcLength*0.8)];
                imageLayer.cornerRadius = imageLayer.bounds.size.width/2.0;
                imageLayer.contents = NULL;
                imageLayer.hidden = YES;
                
                if (_showAnimated) {
                    [layer createArcAnimationForKey:@"startAngle"
                                          fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                            toValue:[NSNumber numberWithDouble:_startPieAngle]
                                           Delegate:self];
                    [layer createArcAnimationForKey:@"endAngle"
                                          fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                            toValue:[NSNumber numberWithDouble:_startPieAngle]
                                           Delegate:self];
                }else {
                    CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, _startPieAngle, _startPieAngle);
                    [layer setPath:path];
                    CFRelease(path);
                    
                    layer.startAngle = _startPieAngle;
                    layer.endAngle = _startPieAngle;
                    
                    {
                        CALayer *labelLayer = [[layer sublayers] objectAtIndex:0];
                        CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
                        
                        CGFloat interpolatedMidAngle = (_startPieAngle + _startPieAngle) / 2;
                        [CATransaction setDisableActions:YES];
                        [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
                        
                        [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(interpolatedMidAngle)), _pieCenter.y + ((_pieRadius*0.9) * sin(interpolatedMidAngle)))];
                        
                        if (_verticalContent) {
                            labelLayer.anchorPoint = CGPointMake(0.7, 0.5);
                            
                            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
                            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
                        }
                        else {
                            labelLayer.anchorPoint = CGPointMake(0.5, 0);
                            
                            labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
                            imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
                        }
                        
                        [CATransaction setDisableActions:NO];
                    }
                }
            }
            [CATransaction commit];
            return;
        }
        
        for(int index = 0; index < sliceCount; index ++)
        {
            SliceLayer *layer;
            double angle = angles[index];
            endToAngle += angle;
            double startFromAngle = _startPieAngle + startToAngle;
            double endFromAngle = _startPieAngle + endToAngle;
            
            if( index >= [slicelayers count] )
            {
                layer = [self createSliceLayer];
                if (isOnStart)
                    startFromAngle = endFromAngle = _startPieAngle;
                [parentLayer addSublayer:layer];
                diff--;
            }
            else
            {
                SliceLayer *onelayer = [slicelayers objectAtIndex:index];
                if(diff == 0 || onelayer.value == (CGFloat)values[index])
                {
                    layer = onelayer;
                    [layersToRemove removeObject:layer];
                }
                else if(diff > 0)
                {
                    layer = [self createSliceLayer];
                    [parentLayer insertSublayer:layer atIndex:index];
                    diff--;
                }
                else if(diff < 0)
                {
                    while(diff < 0) 
                    {
                        [onelayer removeFromSuperlayer];
                        [parentLayer addSublayer:onelayer];
                        diff++;
                        onelayer = [slicelayers objectAtIndex:index];
                        if(onelayer.value == (CGFloat)values[index] || diff == 0)
                        {
                            layer = onelayer;
                            [layersToRemove removeObject:layer];
                            break;
                        }
                    }
                }
            }
            
            layer.name = [NSString stringWithFormat:@"%ld", (long)(index+1)];
            
            layer.value = values[index];
            layer.percentage = (sum)?layer.value/sum:0;
            UIColor *color = nil;
            if([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)])
            {
                color = [_dataSource pieChart:self colorForSliceAtIndex:index];
            }
            
            if(!color)
            {
                color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
            }
            
            [layer setFillColor:color.CGColor];
            if([_dataSource respondsToSelector:@selector(pieChart:textForSliceAtIndex:)])
            {
                layer.text = [_dataSource pieChart:self textForSliceAtIndex:index];
            }
            UIColor *textColor = [UIColor whiteColor];
            if([_dataSource respondsToSelector:@selector(pieChart:textColorForSliceAtIndex:)])
            {
                textColor = [_dataSource pieChart:self textColorForSliceAtIndex:index];
            }
            CATextLayer *textLayer = (CATextLayer*)[[layer sublayers] objectAtIndex:0];
            textLayer.foregroundColor = textColor.CGColor;
            
            [self updateLabelForLayer:layer value:values[index]];
            
            CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
            [imageLayer setBounds:CGRectMake(0, 0, arcLength*0.8, arcLength*0.8)];
            imageLayer.cornerRadius = imageLayer.bounds.size.width/2.0;
            imageLayer.borderWidth = _sliceStrokeWidth;
            BOOL showImage = NO;
            if ([_dataSource respondsToSelector:@selector(pieChart:showImageForSliceAtIndex:)]) {
                showImage = [_dataSource pieChart:self showImageForSliceAtIndex:index];
            }
            if (showImage) {
                imageLayer.hidden = NO;
                if ([_dataSource respondsToSelector:@selector(pieChart:imageBackgroundColorForSliceAtIndex:)]) {
                    imageLayer.backgroundColor = [_dataSource pieChart:self imageBackgroundColorForSliceAtIndex:index].CGColor;
                }
                else {
                    imageLayer.backgroundColor = [UIColor clearColor].CGColor;
                }
                if ([_dataSource respondsToSelector:@selector(pieChart:imageBorderColorForSliceAtIndex:)]) {
                    imageLayer.borderColor = [_dataSource pieChart:self imageBorderColorForSliceAtIndex:index].CGColor;
                }
                else {
                    imageLayer.borderColor = [UIColor clearColor].CGColor;
                }
                if ([_dataSource respondsToSelector:@selector(pieChart:imageForSliceAtIndex:)]) {
                    UIImage *image = [_dataSource pieChart:self imageForSliceAtIndex:index];
                    imageLayer.contents = (id)image.CGImage;
                }
                else {
                    imageLayer.contents = NULL;
                }
            }
            else {
                imageLayer.hidden = YES;
                imageLayer.backgroundColor = [UIColor clearColor].CGColor;
                imageLayer.borderColor = [UIColor clearColor].CGColor;
                imageLayer.contents = NULL;
            }
            
            if (_showAnimated) {
                [layer createArcAnimationForKey:@"startAngle"
                                      fromValue:[NSNumber numberWithDouble:startFromAngle]
                                        toValue:[NSNumber numberWithDouble:startToAngle+_startPieAngle]
                                       Delegate:self];
                [layer createArcAnimationForKey:@"endAngle"
                                      fromValue:[NSNumber numberWithDouble:endFromAngle]
                                        toValue:[NSNumber numberWithDouble:endToAngle+_startPieAngle]
                                       Delegate:self];
            }else {
                CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, startToAngle+_startPieAngle, endToAngle+_startPieAngle);
                [layer setPath:path];
                CFRelease(path);
                
                layer.startAngle = startToAngle+_startPieAngle;
                layer.endAngle = endToAngle+_startPieAngle;
                
                {
                    CALayer *labelLayer = [[layer sublayers] objectAtIndex:0];
                    CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
                    
                    CGFloat interpolatedMidAngle = (endToAngle+_startPieAngle + startToAngle+_startPieAngle) / 2;
                    [CATransaction setDisableActions:YES];
                    [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
                    [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(interpolatedMidAngle)), _pieCenter.y + ((_pieRadius*0.9) * sin(interpolatedMidAngle)))];
                    
                    if (_verticalContent) {
                        labelLayer.anchorPoint = CGPointMake(0.7, 0.5);
                        
                        labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
                        imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
                    }
                    else {
                        labelLayer.anchorPoint = CGPointMake(0.5, 0);
                        
                        labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
                        imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
                    }
                    
                    [CATransaction setDisableActions:NO];
                }
            }
            startToAngle = endToAngle;
        }
        [CATransaction setDisableActions:YES];
        for(SliceLayer *layer in layersToRemove)
        {
            layer.name = nil;
            [layer setFillColor:[self backgroundColor].CGColor];
            [layer setDelegate:nil];
            [layer setZPosition:0];
            CATextLayer *textLayer = (CATextLayer*)[[layer sublayers] objectAtIndex:0];
            [textLayer setHidden:YES];
            CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
            imageLayer.contents = NULL;
            [imageLayer setHidden:YES];
        }
        [layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj removeFromSuperlayer];
        }];
        
        [layersToRemove removeAllObjects];
        
        for(SliceLayer *layer in _pieView.layer.sublayers)
        {
            [layer setZPosition:kDefaultSliceZOrder];
            [layer setLineWidth:_sliceStrokeWidth];
            [layer setStrokeColor:_sliceStrokeColor.CGColor];
        }
        [_pieView setUserInteractionEnabled:YES];
        
        [CATransaction setDisableActions:NO];
        [CATransaction commit];
    }
}

- (void)reloadSliceAtIndex:(NSInteger)index {
    if (index < 0 || index > _pieView.layer.sublayers.count) {
        return;
    }
    
    [_pieView setUserInteractionEnabled:NO];
    
    double minAngle = 2*M_PI*[[_pieView.layer.sublayers valueForKeyPath:@"@min.percentage"] doubleValue];
    double arcLength = minAngle*_pieRadius;
    if (arcLength < _minImageContentSize) {
        arcLength = _minImageContentSize;
    }
    if (arcLength > _maxImageContentSize) {
        arcLength = _maxImageContentSize;
    }
    
    for(SliceLayer *layer in _pieView.layer.sublayers) {
        if ([layer.name isEqualToString:[NSString stringWithFormat:@"%ld", (long)(index+1)]]) {
            UIColor *color = nil;
            if([_dataSource respondsToSelector:@selector(pieChart:colorForSliceAtIndex:)])
            {
                color = [_dataSource pieChart:self colorForSliceAtIndex:index];
            }
            
            if(!color)
            {
                color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
            }
            
            [layer setFillColor:color.CGColor];
            if([_dataSource respondsToSelector:@selector(pieChart:textForSliceAtIndex:)])
            {
                layer.text = [_dataSource pieChart:self textForSliceAtIndex:index];
            }
            UIColor *textColor = [UIColor whiteColor];
            if([_dataSource respondsToSelector:@selector(pieChart:textColorForSliceAtIndex:)])
            {
                textColor = [_dataSource pieChart:self textColorForSliceAtIndex:index];
            }
            CATextLayer *textLayer = (CATextLayer*)[[layer sublayers] objectAtIndex:0];
            textLayer.foregroundColor = textColor.CGColor;
            
            [self updateLabelForLayer:layer value:layer.value];
            
            CALayer *imageLayer = [[layer sublayers] objectAtIndex:1];
            [imageLayer setBounds:CGRectMake(0, 0, arcLength*0.8, arcLength*0.8)];
            imageLayer.cornerRadius = imageLayer.bounds.size.width/2.0;
            imageLayer.borderWidth = _sliceStrokeWidth;
            BOOL showImage = NO;
            if ([_dataSource respondsToSelector:@selector(pieChart:showImageForSliceAtIndex:)]) {
                showImage = [_dataSource pieChart:self showImageForSliceAtIndex:index];
            }
            if (showImage) {
                imageLayer.hidden = NO;
                if ([_dataSource respondsToSelector:@selector(pieChart:imageBackgroundColorForSliceAtIndex:)]) {
                    imageLayer.backgroundColor = [_dataSource pieChart:self imageBackgroundColorForSliceAtIndex:index].CGColor;
                }
                else {
                    imageLayer.backgroundColor = [UIColor clearColor].CGColor;
                }
                if ([_dataSource respondsToSelector:@selector(pieChart:imageBorderColorForSliceAtIndex:)]) {
                    imageLayer.borderColor = [_dataSource pieChart:self imageBorderColorForSliceAtIndex:index].CGColor;
                }
                else {
                    imageLayer.borderColor = [UIColor clearColor].CGColor;
                }
                if ([_dataSource respondsToSelector:@selector(pieChart:imageForSliceAtIndex:)]) {
                    UIImage *image = [_dataSource pieChart:self imageForSliceAtIndex:index];
                    imageLayer.contents = (id)image.CGImage;
                }
                else {
                    imageLayer.contents = NULL;
                }
            }
            else {
                imageLayer.hidden = YES;
                imageLayer.backgroundColor = [UIColor clearColor].CGColor;
                imageLayer.borderColor = [UIColor clearColor].CGColor;
                imageLayer.contents = NULL;
            }
            
            break;
        }
    }
    
    [_pieView setUserInteractionEnabled:YES];
    
}

#pragma mark - Animation Delegate + Run Loop Timer

- (void)updateTimerFired:(NSTimer *)timer;
{   
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];

    [pieLayers enumerateObjectsUsingBlock:^(CAShapeLayer * obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber *presentationLayerStartAngle = [[obj presentationLayer] valueForKey:@"startAngle"];
        CGFloat interpolatedStartAngle = [presentationLayerStartAngle doubleValue];
        
        NSNumber *presentationLayerEndAngle = [[obj presentationLayer] valueForKey:@"endAngle"];
        CGFloat interpolatedEndAngle = [presentationLayerEndAngle doubleValue];

        CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, interpolatedStartAngle, interpolatedEndAngle);
        [obj setPath:path];
        CFRelease(path);
        
        {
            CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
            CALayer *imageLayer = [[obj sublayers] objectAtIndex:1];
            
            CGFloat interpolatedMidAngle = (interpolatedEndAngle + interpolatedStartAngle) / 2;        
            [CATransaction setDisableActions:YES];
            [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)), _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];
            [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(interpolatedMidAngle)), _pieCenter.y + ((_pieRadius*0.9) * sin(interpolatedMidAngle)))];
            
            
            if (_verticalContent) {
                labelLayer.anchorPoint = CGPointMake(0.7, 0.5);
                
                labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
                imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle);
            }
            else {
                labelLayer.anchorPoint = CGPointMake(0.5, 0);
                
                labelLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
                imageLayer.affineTransform = CGAffineTransformMakeRotation(interpolatedMidAngle+0.5*M_PI);
            }
            
            [CATransaction setDisableActions:NO];
        }
    }];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    if (_animationTimer == nil) {
        static float timeInterval = 1.0/60.0;
        // Run the animation timer on the main thread.
        // We want to allow the user to interact with the UI while this timer is running.
        // If we run it on this thread, the timer will be halted while the user is touching the screen (that's why the chart was disappearing in our collection view).
        _animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
    }
    
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted
{
    [_animations removeObject:anim];
    
    if ([_animations count] == 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

#pragma mark - Touch Handing (Selection Notification)

- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSUInteger selectedIndex = -1;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *pieLayer = (SliceLayer *)obj;
        CGPathRef path = [pieLayer path];
        
        if (CGPathContainsPoint(path, &transform, point, 0)) {
            [pieLayer setLineWidth:_selectedSliceStroke];
            [pieLayer setStrokeColor:[UIColor whiteColor].CGColor];
            [pieLayer setLineJoin:kCALineJoinBevel];
            [pieLayer setZPosition:MAXFLOAT];
            selectedIndex = idx;
        } else {
            [pieLayer setZPosition:kDefaultSliceZOrder];
            [pieLayer setLineWidth:_sliceStrokeWidth];
            [pieLayer setStrokeColor:_sliceStrokeColor.CGColor];
        }
    }];
    return selectedIndex;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    [self getCurrentSelectedOnTouch:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    NSInteger selectedIndex = [self getCurrentSelectedOnTouch:point];
    [self notifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:selectedIndex];
    [self touchesCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    for (SliceLayer *pieLayer in pieLayers) {
        [pieLayer setZPosition:kDefaultSliceZOrder];
        [pieLayer setLineWidth:_sliceStrokeWidth];
        [pieLayer setStrokeColor:_sliceStrokeColor.CGColor];
    }
}

#pragma mark - Selection Notification

- (void)notifyDelegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection
{
    if (previousSelection != newSelection){
        if(previousSelection != -1){
            NSUInteger tempPre = previousSelection;
            if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
                [_delegate pieChart:self willDeselectSliceAtIndex:tempPre];
            [self setSliceDeselectedAtIndex:tempPre];
            previousSelection = newSelection;
            if([_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
                [_delegate pieChart:self didDeselectSliceAtIndex:tempPre];
        }
        
        if (newSelection != -1){
            if([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
                [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
            [self setSliceSelectedAtIndex:newSelection];
            _selectedSliceIndex = newSelection;
            if([_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
                [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
        }
    }else if (newSelection != -1){
        SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:newSelection];
        if(_selectedSliceOffsetRadius > 0 && layer){
            if (layer.isSelected) {
                if ([_delegate respondsToSelector:@selector(pieChart:willDeselectSliceAtIndex:)])
                    [_delegate pieChart:self willDeselectSliceAtIndex:newSelection];
                [self setSliceDeselectedAtIndex:newSelection];
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didDeselectSliceAtIndex:)])
                    [_delegate pieChart:self didDeselectSliceAtIndex:newSelection];
                previousSelection = _selectedSliceIndex = -1;
            }else{
                if ([_delegate respondsToSelector:@selector(pieChart:willSelectSliceAtIndex:)])
                    [_delegate pieChart:self willSelectSliceAtIndex:newSelection];
                [self setSliceSelectedAtIndex:newSelection];
                previousSelection = _selectedSliceIndex = newSelection;
                if (newSelection != -1 && [_delegate respondsToSelector:@selector(pieChart:didSelectSliceAtIndex:)])
                    [_delegate pieChart:self didSelectSliceAtIndex:newSelection];
            }
        }
    }
}
#pragma mark - Selection Programmatically Without Notification

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    if(_selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.isSelected) {
        CGPoint currPos = layer.position;
        double middleAngle = (layer.startAngle + layer.endAngle)/2.0;
        CGPoint newPos = CGPointMake(currPos.x + _selectedSliceOffsetRadius*cos(middleAngle), currPos.y + _selectedSliceOffsetRadius*sin(middleAngle));
        layer.position = newPos;
        layer.isSelected = YES;
    }
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    if(_selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = (SliceLayer*)[_pieView.layer.sublayers objectAtIndex:index];
    if (layer && layer.isSelected) {
        layer.position = CGPointMake(0, 0);
        layer.isSelected = NO;
    }
}

#pragma mark - Pie Layer Creation Method

- (SliceLayer *)createSliceLayer
{
    SliceLayer *pieLayer = [SliceLayer layer];
    [pieLayer setZPosition:0];
    [pieLayer setStrokeColor:_sliceStrokeColor.CGColor];
    [pieLayer setLineWidth:_sliceStrokeWidth];
    [pieLayer setLineJoin:kCALineJoinBevel];
    
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        [textLayer setFont:font];
        CFRelease(font);
    }
    [textLayer setFontSize:self.labelFont.pointSize];
    if (_verticalContent) {
        [textLayer setAnchorPoint:CGPointMake(0.7, 0.5)];
    }
    else {
        [textLayer setAnchorPoint:CGPointMake(0.5, 0)];
    }
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setWrapped:YES];
    [textLayer setTruncationMode:kCATruncationEnd];
    [textLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [textLayer setForegroundColor:[UIColor whiteColor].CGColor];
    if (self.labelShadowColor) {
        [textLayer setShadowColor:self.labelShadowColor.CGColor];
        [textLayer setShadowOffset:CGSizeZero];
        [textLayer setShadowOpacity:1.0f];
        [textLayer setShadowRadius:2.0f];
    }
    CGSize size;
    if ([@"0" respondsToSelector:@selector(sizeWithAttributes:)]) {
        size = [@"0" sizeWithAttributes:self.labelFont.fontDescriptor.fontAttributes];
    }
    [CATransaction setDisableActions:YES];
    [textLayer setFrame:CGRectMake(0, 0, size.width, size.height)];
    [textLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(0)), _pieCenter.y + (_labelRadius * sin(0)))];
    [CATransaction setDisableActions:NO];
    [pieLayer addSublayer:textLayer];
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.backgroundColor = [UIColor redColor].CGColor;
    imageLayer.contentsGravity = kCAGravityResizeAspectFill;
    imageLayer.hidden = YES;
    imageLayer.masksToBounds = YES;
    [CATransaction setDisableActions:YES];
    [imageLayer setFrame:CGRectMake(0, 0, size.width, size.height)];
    [imageLayer setPosition:CGPointMake(_pieCenter.x + ((_pieRadius*0.9) * cos(0)), _pieCenter.y + ((_pieRadius*0.9) * sin(0)))];
    [CATransaction setDisableActions:NO];
    [pieLayer addSublayer:imageLayer];
    
    return pieLayer;
}

- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(CGFloat)value
{
    CATextLayer *textLayer = (CATextLayer*)[[pieLayer sublayers] objectAtIndex:0];
    [textLayer setHidden:!_showLabel];
    if(!_showLabel) {
        return;
    }
    
    NSString *label;
    if(_showPercentage) {
        label = [NSString stringWithFormat:@"%0.0f", pieLayer.percentage*100];
    }
    else {
        label = (pieLayer.text)?pieLayer.text:[NSString stringWithFormat:@"%0.0f", value];
    }
    
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        [textLayer setFont:font];
        CFRelease(font);
    }
    [textLayer setFontSize:self.labelFont.pointSize];
    
    // 有最大label寬度的height
    CGFloat maxLabelRadius = _pieRadius*cos((M_PI*pieLayer.percentage));
    CGFloat realWidth;
    if (_labelRadius >= maxLabelRadius) {
        realWidth = 2*sqrt(pow(_pieRadius, 2)-pow(_labelRadius, 2));
    }
    else {
        realWidth = 2*_labelRadius*tan((M_PI*pieLayer.percentage));
    }
    realWidth *= 0.85;
    CGFloat arcLength = M_PI*2*_labelRadius*pieLayer.percentage;
    CGFloat width = realWidth;
    CGFloat height = _labelRadius*0.9;
    if (_verticalContent) {
        width = height;
    }
    
    CGSize size;
    if ([label respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *attribute = @{NSFontAttributeName:self.labelFont, NSParagraphStyleAttributeName:paragraphStyle};
        size = [label boundingRectWithSize:CGSizeMake(width, 9999) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine attributes:attribute context:nil].size;
    }
    
    [CATransaction setDisableActions:YES];
    if((arcLength < size.height && _verticalContent) ||
       (height < size.height && !_verticalContent) ||
       value <= 0)
    {
        [textLayer setString:@""];
    }
    else
    {
        [textLayer setString:label];
    }
    [textLayer setBounds:CGRectMake(0, 0, size.width, size.height+5)];
    [CATransaction setDisableActions:NO];
}

@end
