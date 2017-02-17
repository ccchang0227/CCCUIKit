//
//  CCCCycleView.m
//
//  Created by realtouchapp on 2016/5/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCycleView.h"
#import <GLKit/GLKit.h>


#define kCCCCycleViewDefaultFPS             60.0
#define kCCCCycleViewDefaultDecelerateRate  (0.05*kCCCCycleViewDefaultFPS)
#define kCCCCycleViewDefaultDecelerateTime  3.0


@interface CCCCycleView () <UIGestureRecognizerDelegate> {
    CGFloat _angleBufferDuringPan;
    CGFloat _sum;
    BOOL _shouldNotifySelection;
    
    CGFloat _realDecelerateRate;
    CGFloat _realDecelerateTime;
    
    CGFloat _decelerateAngle;
    
    BOOL _innerDecelerateEnabled;
    
    CGRect _bounds;
}

@property (retain, nonatomic) NSMutableArray *values;

@property (retain, nonatomic) CADisplayLink *decelerateTimer;

@end

@implementation CCCCycleView
@synthesize decelerateRate = _decelerateRate;
@synthesize totalDecelerateTime = _totalDecelerateTime;

- (instancetype)init {
    self = [super init];
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    [_values removeAllObjects];
    [_decelerateTimer invalidate];
    
    [_pieChartView release];
    [_values release];
    [_decelerateTimer release];
    [super dealloc];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _pieChartView.frame = self.bounds;
    [self.pieChartView layoutIfNeeded];
    
    if (!CGRectEqualToRect(_bounds, self.bounds)) {
        self.pieChartView.pieRadius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))/2.0-10.0;
        
        _bounds = self.bounds;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _pieChartView.frame = self.bounds;
    [self.pieChartView layoutIfNeeded];
    
    if (!CGRectEqualToRect(_bounds, self.bounds)) {
        self.pieChartView.pieRadius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))/2.0-10.0;
        
        _bounds = self.bounds;
    }
}

#pragma mark - Setter

- (void)setDecelerateRate:(CGFloat)decelerateRate {
    _decelerateRate = decelerateRate;
    
    if (_decelerateRate == 0.0) {
        _totalDecelerateTime = kCCCCycleViewDefaultDecelerateTime;
    }
    else {
        _totalDecelerateTime = 0.0;
    }
}

- (void)setTotalDecelerateTime:(CGFloat)totalDecelerateTime {
    _totalDecelerateTime = totalDecelerateTime;
    
    if (_totalDecelerateTime == 0.0) {
        _decelerateRate = kCCCCycleViewDefaultDecelerateRate;
    }
    else {
        _decelerateRate = 0.0;
    }
}

#pragma mark - Getter

- (CGFloat)decelerateRate {
    return _realDecelerateRate;
}

- (CGFloat)totalDecelerateTime {
    return _realDecelerateTime;
}

- (NSUInteger)numberOfSlices {
    return self.values.count;
}

#pragma mark - Public

- (void)reloadData {
    _sum = 0.0;
    [self.values removeAllObjects];
    [self.pieChartView reloadData];
}

- (void)reloadSliceAtIndex:(NSInteger)index {
    [self.pieChartView reloadSliceAtIndex:index];
}

- (void)resetRotationAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^ {
            
            self.pieChartView.transform = CGAffineTransformIdentity;
            
        }completion:^(BOOL finished) {
            _currentRotation = 0.0;
        }];
    }
    else {
        self.pieChartView.transform = CGAffineTransformIdentity;
        _currentRotation = 0.0;
    }
    
}

- (void)rotateToSliceAtIndex:(NSUInteger)index animated:(BOOL)animated {
    CCCFloatRange range = [self angleRangeAtIndex:index];
    CGFloat midAngle = (range.location+CCCMaxRange(range))/2.0;
    [self rotateToAngle:midAngle animated:animated];
}

- (void)rotateToAngle:(CGFloat)angleByDegree animated:(BOOL)animated {
    angleByDegree = [self _limitRotationToEdge:angleByDegree];
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^ {
            
            self.pieChartView.transform = CGAffineTransformMakeRotation(GLKMathDegreesToRadians(angleByDegree));
            
        }completion:^(BOOL finished) {
            _currentRotation = angleByDegree;
        }];
    }
    else {
        self.pieChartView.transform = CGAffineTransformMakeRotation(GLKMathDegreesToRadians(angleByDegree));
        _currentRotation = angleByDegree;
    }
}

- (void)rotateInfinitelyWithVelocity:(CGFloat)velocity clockwise:(BOOL)clockwise {
    _clockwise = clockwise;
    if (clockwise) {
        _angularVelocity = fabs(velocity);
    }
    else {
        _angularVelocity = -fabs(velocity);
    }
    
    _innerDecelerateEnabled = NO;
    [self _startTimer];
}

- (void)rotateInfinitelyByIncreasingToVelocity:(CGFloat)velocity
                                     clockwise:(BOOL)clockwise
                                    completion:(void(^)(void))handler {
    _clockwise = clockwise;
    
    _innerDecelerateEnabled = YES;
    
    _realDecelerateRate = -kCCCCycleViewDefaultDecelerateRate;
    [self _startTimerWithoutDecelerateCalculating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        
        while (fabs(_angularVelocity) < fabs(velocity)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
        if (_realDecelerateRate < 0.0) {
            _innerDecelerateEnabled = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (handler) {
                handler();
            }
        });
        
    });
}

- (void)rotateInfinitelyByIncreasingToVelocity:(CGFloat)velocity
                                     inSeconds:(NSTimeInterval)seconds
                                     clockwise:(BOOL)clockwise
                                    completion:(void(^)(void))handler {
    _clockwise = clockwise;
    
    _innerDecelerateEnabled = YES;
    
    _realDecelerateRate = -fabs(velocity)/seconds;
    [self _startTimerWithoutDecelerateCalculating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        
        while (fabs(_angularVelocity) < fabs(velocity)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        
        if (_realDecelerateRate < 0.0) {
            _innerDecelerateEnabled = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (handler) {
                handler();
            }
        });
        
    });
}

- (void)decelerate {
    _decelerateAngle = CGFLOAT_MAX;
    _innerDecelerateEnabled = YES;
}

- (void)decelerateToAngle:(CGFloat)angle {
    angle = [self _limitRotationToEdge:angle];
    _decelerateAngle = angle;
    
    CGFloat currentAngle = _currentRotation;
    CGFloat angularDiff = 0.0;
    if (_clockwise) {
        // Angle should be increased
        angularDiff = angle-currentAngle;
    }
    else if (!_clockwise) {
        angularDiff = currentAngle-angle;
    }
    if (angularDiff < 0.0) {
        angularDiff = 360.0+angularDiff;
    }
    angularDiff += 360.0*MAX(1, (int)(_angularVelocity/5));
    
    if (_totalDecelerateTime > 0.0) {
        _realDecelerateTime = _totalDecelerateTime;
    }
    else {
        _realDecelerateTime = fabs(_angularVelocity)/_decelerateRate;
    }
    
//     s = v0*t-0.5*a*(t^2) (didn't work)
//    _realDecelerateRate = 2*fabs(angularDiff-fabs(_angularVelocity)*_realDecelerateTime*kCCCCycleViewDefaultFPS)/(pow((_realDecelerateTime*kCCCCycleViewDefaultFPS), 2.0));
    
//    (v^2) = (v0^2)-2*a*s
    _realDecelerateRate = pow(fabs(_angularVelocity), 2.0)/(2*angularDiff);
    _realDecelerateRate *= kCCCCycleViewDefaultFPS;
    
    _innerDecelerateEnabled = YES;
}

- (void)forceStopRotating {
    [self.layer removeAllAnimations];
    [self _stopTimer];
    
    _angularVelocity = 0.0;
    _dragging = NO;
    _rotating = NO;
    
    _innerDecelerateEnabled = YES;
}

- (NSUInteger)indexAtRotation:(CGFloat)rotation {
    rotation = [self _limitRotationToEdge:rotation];
    __block NSUInteger index = NSNotFound;
    __block CGFloat startAngle = 0.0;
    [_values enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        
        CGFloat value = [number floatValue];
        value = (value/_sum)*360.0;
        CGFloat endAngle = startAngle+value;
        if (startAngle <= rotation && endAngle > rotation) {
            index = idx;
            (*stop) = YES;
        }
        
        startAngle = endAngle;
    }];
    
    return index;
}

- (CCCFloatRange)angleRangeAtIndex:(NSUInteger)index {
    __block CCCFloatRange range = kCCCFloatEmptyRange;
    __block CGFloat startAngle = 0.0;
    [_values enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        
        CGFloat value = [number floatValue];
        value = (value/_sum)*360.0;
        CGFloat endAngle = startAngle+value;
        if (idx == index) {
            range = CCCMakeRange(startAngle, value);
            (*stop) = YES;
        }
        
        startAngle = endAngle;
    }];
    
    return range;
}

- (CGFloat)valueForSliceAtIndex:(NSUInteger)index {
    if (index >= self.values.count) {
        return 0.0;
    }
    
    return [self.values[index] floatValue];
}

- (CGFloat)percentageForSliceAtIndex:(NSUInteger)index {
    CGFloat value = [self valueForSliceAtIndex:index];
    return (value/_sum)*100.0;
}

#pragma mark - Private

- (void)_setup {
    self.exclusiveTouch = YES;
    self.multipleTouchEnabled = NO;
    
    _pieChartView = [[XYPieChart alloc] init];
    _pieChartView.backgroundColor = [UIColor clearColor];
    _pieChartView.userInteractionEnabled = NO;
    _pieChartView.showAnimated = NO;
    _pieChartView.showPercentage = NO;
    _pieChartView.delegate = self;
    _pieChartView.dataSource = self;
//    _pieChartView.frame = self.bounds;
//    _pieChartView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    //*
    _pieChartView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_pieChartView];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_pieChartView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieChartView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_pieChartView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_pieChartView)]];
     //*/
    
    _values = [[NSMutableArray alloc] init];
    _sum = 0.0;
    _shouldNotifySelection = YES;
    
    _currentRotation = 0.0;
    
    _draggable = YES;
    _clockwise = NO;
    _dragging = NO;
    
    _angularVelocity = 0.0;
    _rotating = NO;
    
    _decelerateEnabled = YES;
    _decelerating = NO;
    _decelerateRate = kCCCCycleViewDefaultDecelerateRate;
    _totalDecelerateTime = 0.0;
    
    _realDecelerateRate = _decelerateRate;
    _realDecelerateTime = _totalDecelerateTime;
    
    _decelerateAngle = CGFLOAT_MAX;
    
    _innerDecelerateEnabled = YES;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_pan:)];
    panGesture.delegate = self;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    [self addGestureRecognizer:panGesture];
    [panGesture release];
    
    _bounds = CGRectZero;
}

/**
 *  @author Chih-chieh Chang
 *
 *  Calculate the angle from given point and given view's center point. <br>
 *  The defination of angles is:<br>
 *  1. 0 is in the center top position.
 *  2. 90 is in the center left position.
 *  3. 180 is in the center bottom position.
 *  4. 270 is in the center right position.
 *
 *  @param point Point to estimate.
 *
 *  @return Angle in degree. Range from 0~359.
 */
- (CGFloat)_angleFromPoint:(CGPoint)point view:(UIView*)view {
    double dx = view.center.x - point.x;
    double dy = view.center.y - point.y;
    CGFloat angle = 0;
    double slope;
    if (dy == 0.0f) {
        if (dx > 0.0f) {
            angle = 90.0f;
        }
        else if (dx < 0.0f) {
            angle = 270.0f;
        }
        return angle;
    }
    
    slope = dx / dy;
    angle = atan(slope);
    angle = GLKMathRadiansToDegrees(angle);
    if (dy >= 0 && dx < 0) {
        angle = angle + 360.0;
    }
    else if (dy < 0) {
        angle = angle + 180.0;
    }
    
    return angle;
}

- (CGFloat)_distanceToViewCenter:(UIView*)view withPoint:(CGPoint)point {
    double dx = view.center.x - point.x;
    double dy = view.center.y - point.y;
    return sqrt(pow(dx, 2)+pow(dy, 2));
}

- (CGFloat)_limitRotationToEdge:(CGFloat)rotation {
    while (rotation >= 360.0) {
        rotation -= 360.0;
    }
    while (rotation < 0.0) {
        rotation += 360.0;
    }
    return rotation;
}

#pragma mark - GestureRecognizer

- (void)_pan:(UIPanGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self];
        _angleBufferDuringPan = [self _angleFromPoint:point view:self];
        
        _angularVelocity = 0.0;
        _dragging = NO;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleViewWillBeginDragging:)]) {
            [self.delegate cccCycleViewWillBeginDragging:self];
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        _dragging = YES;
        _rotating = YES;
        
        CGPoint point = [gestureRecognizer locationInView:self];
        CGFloat newAngle = [self _angleFromPoint:point view:self];
        _angularVelocity = _angleBufferDuringPan-newAngle;
        _pieChartView.transform = CGAffineTransformRotate([_pieChartView transform], GLKMathDegreesToRadians(_angularVelocity));
        _angleBufferDuringPan = newAngle;
        
        _clockwise = (_angularVelocity > 0);
        
        _currentRotation += _angularVelocity;
        _currentRotation = [self _limitRotationToEdge:_currentRotation];
        
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(cccCycleView:isDragging:)]) {
                [self.delegate cccCycleView:self isDragging:_currentRotation];
            }
            if ([self.delegate respondsToSelector:@selector(cccCycleView:isRotating:)]) {
                [self.delegate cccCycleView:self isRotating:_currentRotation];
            }
        }
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
             gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
             gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        
        if (_decelerateEnabled) {
            BOOL willDecelerate = YES;
            
            if (fabs(_angularVelocity) <= 0.5 && _decelerateAngle == CGFLOAT_MAX) {
                willDecelerate = NO;
            }
            
            if (willDecelerate) {
                [self _startTimer];
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleViewDidEndDragging:willDecelerate:)]) {
                [self.delegate cccCycleViewDidEndDragging:self willDecelerate:willDecelerate];
            }
        }
        
        _dragging = NO;
        _rotating = NO;
    }
//    NSLog(@"%f", _angularVelocity);
//    NSLog(@"angle:%f", _currentRotation);
//    NSLog(@"index:%ld", [self indexAtRotation:_currentRotation]);
    
    [gestureRecognizer setTranslation:CGPointZero inView:self];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return _draggable;
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint point = [[touches anyObject] locationInView:self];
    CGFloat distance = [self _distanceToViewCenter:self withPoint:point];
    if (distance > self.pieChartView.pieRadius) {
        // Tap on the outside of cycle.
        return;
    }
    
    if (self.decelerateTimer) {
        _shouldNotifySelection = NO;
    }
    else {
        _shouldNotifySelection = YES;
    }
    
    [self _stopTimer];
    
    _angularVelocity = 0.0;
    _dragging = NO;
    _rotating = NO;
    
    _innerDecelerateEnabled = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleView:touchesDidBegin:withEvents:)]) {
        [self.delegate cccCycleView:self touchesDidBegin:touches withEvents:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    CGPoint point = [[touches anyObject] locationInView:self];
    CGFloat distance = [self _distanceToViewCenter:self withPoint:point];
    if (distance > self.pieChartView.pieRadius) {
        // Tap on the outside of cycle.
        return;
    }
    
    if (!_shouldNotifySelection) {
        _angularVelocity = 0.0;
        _dragging = NO;
        _rotating = NO;
        return;
    }
    
    if ([self respondsToSelector:@selector(convertPoint:toCoordinateSpace:)]) {
        point = [self convertPoint:point toCoordinateSpace:self.pieChartView];
    }
    else {
        point = [self convertPoint:point toView:self.pieChartView];
    }
    CGFloat angle = [self _angleFromPoint:point view:self];
    
    _angularVelocity = 0.0;
    _dragging = NO;
    _rotating = NO;
    
    NSUInteger selectedIndex = [self indexAtRotation:angle];
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleView:didSelectSliceAtIndex:)]) {
        [self.delegate cccCycleView:self didSelectSliceAtIndex:selectedIndex];
    }
}

#pragma mark - Decelerate

- (void)_startTimer {
    if (self.decelerateTimer) {
        [self.decelerateTimer invalidate];
        self.decelerateTimer = nil;
    }
    _decelerating = NO;
    _rotating = NO;
    
    if (_totalDecelerateTime > 0.0) {
        _realDecelerateTime = _totalDecelerateTime;
        _realDecelerateRate = (fabs(_angularVelocity)/_realDecelerateTime);
    }
    else {
        _realDecelerateRate = _decelerateRate;
        _realDecelerateTime = fabs(_angularVelocity)/_realDecelerateRate;
    }
    _decelerateAngle = CGFLOAT_MAX;
    
    if (self.window) {
        self.decelerateTimer = [self.window.screen displayLinkWithTarget:self selector:@selector(_scheduledDecelerate:)];
    }
    else {
        self.decelerateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_scheduledDecelerate:)];
    }
    self.decelerateTimer.frameInterval = 1;
    [self.decelerateTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_startTimerWithoutDecelerateCalculating {
    if (self.decelerateTimer) {
        [self.decelerateTimer invalidate];
        self.decelerateTimer = nil;
    }
    _decelerating = NO;
    _rotating = NO;
    _decelerateAngle = CGFLOAT_MAX;
    
    if (self.window) {
        self.decelerateTimer = [self.window.screen displayLinkWithTarget:self selector:@selector(_scheduledDecelerate:)];
    }
    else {
        self.decelerateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_scheduledDecelerate:)];
    }
    self.decelerateTimer.frameInterval = 1;
    [self.decelerateTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_stopTimer {
    if (self.decelerateTimer) {
        [self.decelerateTimer invalidate];
        self.decelerateTimer = nil;
    }
    
    _angularVelocity = 0.0;
    _decelerating = NO;
    _rotating = NO;
    _decelerateAngle = CGFLOAT_MAX;
}

- (void)_scheduledDecelerate:(CADisplayLink*)timer {
    NSInteger fps = kCCCCycleViewDefaultFPS;
    CGFloat accuracy = _realDecelerateRate/fps;
    CGFloat accuracyThreshold = MAX(accuracy, 0.1);
    if (accuracy < 0.0) {
        accuracyThreshold = MIN(accuracy, -0.1);
    }
    if (_decelerateAngle != CGFLOAT_MAX) {
        if (fabs(_currentRotation-_decelerateAngle) <= accuracyThreshold &&
            (fabs(_angularVelocity) <= accuracyThreshold ||
             (_clockwise && _angularVelocity < 0) ||
             (!_clockwise && _angularVelocity > 0))) {
            [self _stopTimer];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleViewDidEndDecelerating:)]) {
                [self.delegate cccCycleViewDidEndDecelerating:self];
            }
            return;
        }
        else if (fabs(_angularVelocity) < accuracyThreshold ||
                 (_clockwise && _angularVelocity <= 0) ||
                 (!_clockwise && _angularVelocity >= 0)) {
            if (_clockwise) {
//                _angularVelocity = 0.5*accuracy;
                _angularVelocity = 0.5*accuracyThreshold;
            }
            else {
//                _angularVelocity = -0.5*accuracy;
                _angularVelocity = -0.5*accuracyThreshold;
            }
        }
    }
    else if (fabs(_angularVelocity) <= accuracyThreshold && _decelerateAngle == CGFLOAT_MAX) {
        [self _stopTimer];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleViewDidEndDecelerating:)]) {
            [self.delegate cccCycleViewDidEndDecelerating:self];
        }
        return;
    }
    
    if (_decelerateEnabled && _innerDecelerateEnabled) {
        if (fabs(_angularVelocity) > accuracy) {
            if (_clockwise) {
                _angularVelocity -= accuracy;
            }
            else {
                _angularVelocity += accuracy;
            }
        }
        
        _decelerating = YES;
    }
    else {
        _decelerating = NO;
    }
    _rotating = YES;
    
    _pieChartView.transform = CGAffineTransformRotate([_pieChartView transform], GLKMathDegreesToRadians(_angularVelocity));
    _currentRotation += _angularVelocity;
    _currentRotation = [self _limitRotationToEdge:_currentRotation];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccCycleView:isRotating:)]) {
        [self.delegate cccCycleView:self isRotating:_currentRotation];
    }
}

#pragma mark - XYPieChartDataSource

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart {
    _sum = 0.0;
    [_values removeAllObjects];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfSlicesInCCCCycleView:)]) {
        return [self.dataSource numberOfSlicesInCCCCycleView:self];
    }
    
    return 0;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:valueForSliceAtIndex:)]) {
        
        CGFloat value = [self.dataSource cccCycleView:self valueForSliceAtIndex:index];
        _sum += value;
        [_values addObject:@(value)];
        return value;
    }
    
    return 0;
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:colorForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self colorForSliceAtIndex:index];
    }
    
    return [UIColor clearColor];
}

- (NSString *)pieChart:(XYPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:textForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self textForSliceAtIndex:index];
    }
    
    return @"";
}

- (UIColor *)pieChart:(XYPieChart *)pieChart textColorForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:textColorForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self textColorForSliceAtIndex:index];
    }
    
    return [UIColor whiteColor];
}

- (BOOL)pieChart:(XYPieChart *)pieChart showImageForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:showImageForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self showImageForSliceAtIndex:index];
    }
    
    return NO;
}

- (UIImage *)pieChart:(XYPieChart *)pieChart imageForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:imageForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self imageForSliceAtIndex:index];
    }
    
    return nil;
}

- (UIColor *)pieChart:(XYPieChart *)pieChart imageBackgroundColorForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:imageBackgroundColorForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self imageBackgroundColorForSliceAtIndex:index];
    }
    
    return nil;
}

- (UIColor *)pieChart:(XYPieChart *)pieChart imageBorderColorForSliceAtIndex:(NSUInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(cccCycleView:imageBorderColorForSliceAtIndex:)]) {
        return [self.dataSource cccCycleView:self imageBorderColorForSliceAtIndex:index];
    }
    
    return nil;
}

@end
