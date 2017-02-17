//
//  CCCCanvas.m
//
//  Created by CHIEN-HSU WU on 2015/5/19.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCanvas.h"

#import <AVFoundation/AVFoundation.h>


NS_INLINE BOOL isValidCGPointValue(NSValue *pointValue) {
    if (!pointValue) {
        return NO;
    }
    
    if ((NSNull*)pointValue != [NSNull null] && [pointValue isKindOfClass:[NSValue class]]) {
        if (strcmp([pointValue objCType], @encode(CGPoint)) == 0) {
            return YES;
        }
    }
    
    return NO;
}


NSString *const CCCCanvasPathObjectModeKey          = @"CCCCanvasPathObjectMode";
NSString *const CCCCanvasPathObjectPointsKey        = @"CCCCanvasPathObjectPoints";
NSString *const CCCCanvasPathObjectStrokeColorKey   = @"CCCCanvasPathObjectStrokeColor";
NSString *const CCCCanvasPathObjectFillColorKey     = @"CCCCanvasPathObjectFillColor";
NSString *const CCCCanvasPathObjectLineWidthKey     = @"CCCCanvasPathObjectLineWidth";
NSString *const CCCCanvasPathObjectShadowEffectKey  = @"CCCCanvasPathObjectHasShadowEffect";
NSString *const CCCCanvasPathObjectFinishedKey      = @"CCCCanvasPathObjectIsFinished";

@interface CCCCanvasPathObject ()

@property (nonatomic) CCCCanvasPath pathMode;
@property (retain, nonatomic) NSMutableArray *points;
@property (copy, nonatomic) UIColor *strokeColor;
@property (copy, nonatomic) UIColor *fillColor;
@property (nonatomic) CGFloat lineWidth;

@property (nonatomic) BOOL hasShadowEffect;

@property (nonatomic) BOOL finished;

@property (nonatomic, readonly) CGRect boundingRect;

- (void)calculateBoundingRect;

@end

@implementation CCCCanvasPathObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.points = [NSMutableArray arrayWithCapacity:0];
        self.finished = NO;
    }
    
    return self;
}

- (void)dealloc {
    [_points removeAllObjects];
    
#if !__has_feature(objc_arc)
    [_points release];
    [_strokeColor release];
    [_fillColor release];
    [super dealloc];
#endif
    
}

- (NSString*)description {
    NSMutableString *descriptionString = [NSMutableString stringWithString:[super description]];
    
    [descriptionString appendFormat:@" <pathMode="];
    switch (self.pathMode) {
        case CCCCanvasPathPen:
            [descriptionString appendFormat:@"Pen"];
            break;
        case CCCCanvasPathStraightLine:
            [descriptionString appendFormat:@"Straight Line"];
            break;
        case CCCCanvasPathCurveLine:
            [descriptionString appendFormat:@"Curve Line"];
            break;
        case CCCCanvasPathFillPolygon:
            [descriptionString appendFormat:@"Fill Polygon"];
            break;
        case CCCCanvasPathStrokePolygon:
            [descriptionString appendFormat:@"Stroke Polygon"];
            break;
        case CCCCanvasPathFillRect:
            [descriptionString appendFormat:@"Fill Rect"];
            break;
        case CCCCanvasPathStrokeRect:
            [descriptionString appendFormat:@"Stroke Rect"];
            break;
        case CCCCanvasPathFillEllipse:
            [descriptionString appendFormat:@"Fill Ellipse"];
            break;
        case CCCCanvasPathStrokeEllipse:
            [descriptionString appendFormat:@"Stroke Ellipse"];
            break;
        case CCCCanvasPathEraser:
            [descriptionString appendFormat:@"Eraser"];
            break;
        default:
            break;
    }
    
    [descriptionString appendFormat:@", point count=%d", (int)self.points.count];
    [descriptionString appendFormat:@", stroke color(r g b a)=%@", self.strokeColor];
    [descriptionString appendFormat:@", fill color(r g b a)=%@", self.fillColor];
    [descriptionString appendFormat:@", line width=%.2f", self.lineWidth];
    [descriptionString appendFormat:@", finished="];
    if (self.finished) {
        [descriptionString appendFormat:@"YES"];
    }
    else {
        [descriptionString appendFormat:@"NO"];
    }
    
    [descriptionString appendFormat:@", boundingRect=%@>", NSStringFromCGRect(self.boundingRect)];
    
    return descriptionString;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) copyObject = [[[self class] allocWithZone:zone] init];
    copyObject.pathMode = self.pathMode;
    [copyObject.points addObjectsFromArray:self.points];
    copyObject.strokeColor = self.strokeColor;
    copyObject.fillColor = self.fillColor;
    copyObject.lineWidth = self.lineWidth;
    copyObject.hasShadowEffect = self.hasShadowEffect;
    copyObject.finished = self.finished;
    
    [copyObject calculateBoundingRect];
    
    return copyObject;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:@(_pathMode) forKey:CCCCanvasPathObjectModeKey];
    if (_points) {
        [aCoder encodeObject:_points forKey:CCCCanvasPathObjectPointsKey];
    }
    if (_strokeColor) {
        [aCoder encodeObject:_strokeColor forKey:CCCCanvasPathObjectStrokeColorKey];
    }
    if (_fillColor) {
        [aCoder encodeObject:_fillColor forKey:CCCCanvasPathObjectFillColorKey];
    }
    [aCoder encodeObject:@(_lineWidth) forKey:CCCCanvasPathObjectLineWidthKey];
    [aCoder encodeObject:@(_hasShadowEffect) forKey:CCCCanvasPathObjectShadowEffectKey];
    [aCoder encodeObject:@(_finished) forKey:CCCCanvasPathObjectFinishedKey];
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _pathMode = [[aDecoder decodeObjectForKey:CCCCanvasPathObjectModeKey] integerValue];
        NSArray *points = [aDecoder decodeObjectForKey:CCCCanvasPathObjectPointsKey];
        if (points) {
            self.points = [NSMutableArray arrayWithArray:points];
        }
        else {
            self.points = [NSMutableArray arrayWithCapacity:0];
        }
        UIColor *strokeColor = [aDecoder decodeObjectForKey:CCCCanvasPathObjectStrokeColorKey];
        if (strokeColor) {
            self.strokeColor = strokeColor;
        }
        else {
            self.strokeColor = [UIColor blackColor];
        }
        UIColor *fillColor = [aDecoder decodeObjectForKey:CCCCanvasPathObjectFillColorKey];
        if (fillColor) {
            self.fillColor = fillColor;
        }
        else {
            self.fillColor = [UIColor blackColor];
        }
        _lineWidth = [[aDecoder decodeObjectForKey:CCCCanvasPathObjectLineWidthKey] floatValue];
        _hasShadowEffect = [[aDecoder decodeObjectForKey:CCCCanvasPathObjectShadowEffectKey] boolValue];
        _finished = [[aDecoder decodeObjectForKey:CCCCanvasPathObjectFinishedKey] boolValue];
        
    }
    return self;
}

#pragma mark -

- (void)calculateBoundingRect {
    _boundingRect = CGRectZero;
    
    if (self.points.count == 0) {
        return;
    }
    else if (self.points.count == 1) {
        NSValue *pointValue = [self.points objectAtIndex:0];
        if (isValidCGPointValue(pointValue)) {
            CGPoint point = [pointValue CGPointValue];
            _boundingRect = CGRectMake(point.x-self.lineWidth/2.0, point.y-self.lineWidth/2.0, self.lineWidth, self.lineWidth);
//            _boundingRect = CGRectMake(0, 0, self.lineWidth, self.lineWidth);
        }
    }
    else {
        CGFloat minX = 0, maxX = 0;
        CGFloat minY = 0, maxY = 0;
        for (NSValue *value in self.points) {
            if (isValidCGPointValue(value)) {
                CGPoint point = [value CGPointValue];
                if (point.x >= maxX) {
                    maxX = point.x;
                }
                if (point.x <= minX) {
                    minX = point.x;
                }
                if (point.y >= maxY) {
                    maxY = point.y;
                }
                if (point.y <= minY) {
                    minY = point.y;
                }
            }
        }
        
        _boundingRect = CGRectMake(minX, minY, maxX-minX, maxY-minY);
//        _boundingRect = CGRectMake(0, 0, maxX-minX, maxY-minY);
    }
}

@end


@interface CCCCanvas () {
    UIColor *_backgroundColor;
    
    CGPoint _currentPoint;
    
    NSInteger _currentCurveIndex;
    
    CGLayerRef _drawingLayer;
    
    CGFloat _scale;
    
    CGRect _bounds;
}

@property (retain, nonatomic) NSMutableArray *paths;

@property (retain, nonatomic) NSMutableArray *undoPaths;

@end

@implementation CCCCanvas

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _paletteView = [[CCCCanvasPaletteView alloc] init];
        _paletteView.delegate = self;
        
        _lineWidthSelectionView = [[CCCCanvasLineWidthSelectionView alloc] init];
        _lineWidthSelectionView.delegate = self;
        
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        if (!_paletteView) {
            _paletteView = [[CCCCanvasPaletteView alloc] init];
        }
        _paletteView.delegate = self;
        
        if (!_lineWidthSelectionView) {
            _lineWidthSelectionView = [[CCCCanvasLineWidthSelectionView alloc] init];
        }
        _lineWidthSelectionView.delegate = self;
        
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _paletteView = [[CCCCanvasPaletteView alloc] init];
        _paletteView.delegate = self;
        
        _lineWidthSelectionView = [[CCCCanvasLineWidthSelectionView alloc] init];
        _lineWidthSelectionView.delegate = self;
        
        [self setup];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    CGContextSetFlatness(context, 0.1f);
    
    @synchronized(self) {
        if (!_backgroundErasable) {
            // draw backgroundColor
            CGContextSetFillColorWithColor(context, _backgroundColor.CGColor);
            CGContextFillRect(context, rect);
            
            if (self.backgroundImage) {
                CGRect fitRect = AVMakeRectWithAspectRatioInsideRect(self.backgroundImage.size, rect);
                if (!CGRectIsEmpty(fitRect) && !CGRectIsInfinite(fitRect)) {
                    [self.backgroundImage drawInRect:fitRect];
                }
            }
        }
        
        [self drawPathsInRect:rect context:context];
        CGContextDrawLayerInRect(context, rect, _drawingLayer);
    }
    
}

- (void)dealloc {
    [_paths removeAllObjects];
    [_undoPaths removeAllObjects];
    
    if (_drawingLayer) {
        CGLayerRelease(_drawingLayer);
        _drawingLayer = NULL;
    }
    
#if !__has_feature(objc_arc)
    [_paletteView release];
    [_lineWidthSelectionView release];
    [_backgroundImage release];
    [_strokeColor release];
    [_fillColor release];
    [_paths release];
    [_undoPaths release];
    [super dealloc];
#endif
    
}

- (void)drawPathsInRect:(CGRect)rect context:(CGContextRef)ctx {
    if (_drawingLayer == NULL) {
        CGFloat width = CGRectGetWidth(rect);
        CGFloat height = CGRectGetHeight(rect);
        width *= _scale;
        height *= _scale;
        rect.size.width = width;
        rect.size.height = height;
        
        _drawingLayer = CGLayerCreateWithContext(ctx, rect.size, NULL);
    }
    
    rect.size.width = CGLayerGetSize(_drawingLayer).width;
    rect.size.height = CGLayerGetSize(_drawingLayer).height;
    
    CGContextRef context = CGLayerGetContext(_drawingLayer);
    
    CGContextClearRect(context, rect);
    
    if (_backgroundErasable) {
        // draw backgroundColor
        CGContextSetFillColorWithColor(context, _backgroundColor.CGColor);
        CGContextAddRect(context, rect);
        CGContextDrawPath(context, kCGPathFill);
        
        if (self.backgroundImage) {
            CGRect fitRect = AVMakeRectWithAspectRatioInsideRect(self.backgroundImage.size, rect);
            if (!CGRectIsEmpty(fitRect) && !CGRectIsInfinite(fitRect)) {
                [self.backgroundImage drawInRect:fitRect];
            }
        }
    }
    
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    CGContextSetFlatness(context, 0.1f);
    
    CGContextSaveGState(context);
    // draw paths
    for (CCCCanvasPathObject *pathObject in self.paths) {
        CGContextSetStrokeColorWithColor(context, pathObject.strokeColor.CGColor);
        CGContextSetFillColorWithColor(context, pathObject.fillColor.CGColor);
        CGContextSetLineWidth(context, pathObject.lineWidth*_scale);
        
        [self drawPathWithContext:context path:pathObject];
    }
    CGContextRestoreGState(context);
    
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (_drawingLayer) {
        CGLayerRelease(_drawingLayer);
        _drawingLayer = NULL;
    }
    
    CGRect newBounds = self.bounds;
    if (!CGRectEqualToRect(newBounds, _bounds)) {
        if (!CGRectIsEmpty(_bounds) &&
            !CGRectEqualToRect(_bounds, CGRectZero) &&
            !CGRectIsInfinite(_bounds)) {
            
            @synchronized(self.paths) {
                for (CCCCanvasPathObject *pathObject in self.paths) {
                    CCCCanvasPathObject *copiedObject = [pathObject copy];
                    [copiedObject.points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
                        
                        if (isValidCGPointValue(pointValue)) {
                            CGPoint point = [pointValue CGPointValue];
                            point.x *= (CGRectGetWidth(newBounds)/CGRectGetWidth(_bounds));
                            point.y *= (CGRectGetHeight(newBounds)/CGRectGetHeight(_bounds));
                            
                            [pathObject.points replaceObjectAtIndex:idx withObject:[NSValue valueWithCGPoint:point]];
                        }
                        
                    }];
                    [copiedObject release];
                    
                    [pathObject calculateBoundingRect];
                }
            }
        }
        
        _bounds = newBounds;
    }
    
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_drawingLayer) {
        CGLayerRelease(_drawingLayer);
        _drawingLayer = NULL;
    }
    
    CGRect newBounds = self.bounds;
    if (!CGRectEqualToRect(newBounds, _bounds)) {
        if (!CGRectIsEmpty(_bounds) &&
            !CGRectEqualToRect(_bounds, CGRectZero) &&
            !CGRectIsInfinite(_bounds)) {
            
            @synchronized(self.paths) {
                for (CCCCanvasPathObject *pathObject in self.paths) {
                    CCCCanvasPathObject *copiedObject = [pathObject copy];
                    [copiedObject.points enumerateObjectsUsingBlock:^(NSValue *pointValue, NSUInteger idx, BOOL *stop) {
                        
                        if (isValidCGPointValue(pointValue)) {
                            CGPoint point = [pointValue CGPointValue];
                            point.x *= (CGRectGetWidth(newBounds)/CGRectGetWidth(_bounds));
                            point.y *= (CGRectGetHeight(newBounds)/CGRectGetHeight(_bounds));
                            
                            [pathObject.points replaceObjectAtIndex:idx withObject:[NSValue valueWithCGPoint:point]];
                        }
                        
                    }];
                    [copiedObject release];
                    
                    [pathObject calculateBoundingRect];
                }
            }
        }
        
        _bounds = newBounds;
    }
    
    [self setNeedsDisplay];
}

#pragma mark - public methods

- (void)undo {
    if (!self.canUndo) {
        return;
    }
    
    CCCCanvasPathObject *pathObject = [self.paths lastObject];
    if (pathObject.pathMode == CCCCanvasPathCurveLine) {
        if (!pathObject.finished && pathObject.points.count > 2) {
            CCCCanvasPathObject *copyPathObject = [pathObject copy];
            [self.undoPaths addObject:copyPathObject];
            if (pathObject.points.count == 3) {
                [pathObject.points removeObjectAtIndex:1];
            }
            else {
                [pathObject.points removeObjectAtIndex:_currentCurveIndex];
            }
            [copyPathObject release];
        }
        else {
            //pathObject.finished = YES;
            [self.undoPaths addObject:pathObject];
            [self.paths removeLastObject];
        }
    }
    else if (pathObject.pathMode == CCCCanvasPathFillPolygon || pathObject.pathMode == CCCCanvasPathStrokePolygon) {
        if (!pathObject.finished && pathObject.points.count > 2) {
            CCCCanvasPathObject *copyPathObject = [pathObject copy];
            [self.undoPaths addObject:copyPathObject];
            [pathObject.points removeLastObject];
            [copyPathObject release];
        }
        else {
            //pathObject.finished = YES;
            [self.undoPaths addObject:pathObject];
            [self.paths removeLastObject];
        }
    }
    else {
        pathObject.finished = YES;
        [self.undoPaths addObject:pathObject];
        [self.paths removeLastObject];
    }
    
    [self setNeedsDisplay];
}

- (void)redo {
    if (!self.canRedo) {
        return;
    }
    
    CCCCanvasPathObject *pathObject = [self.undoPaths lastObject];
    if (self.paths.count > 0 && !pathObject.finished) {
        CCCCanvasPathObject *lastPathObject = [self.paths lastObject];
        if (!lastPathObject.finished) {
            [self.paths replaceObjectAtIndex:self.paths.count-1 withObject:pathObject];
        }
        else {
            [self.paths addObject:pathObject];
        }
    }
    else {
        [self.paths addObject:pathObject];
    }
    [self.undoPaths removeLastObject];
    
    [self setNeedsDisplay];
}

- (void)clear {
    [self.paths removeAllObjects];
    [self.undoPaths removeAllObjects];
    
    [self setNeedsDisplay];
}

- (UIImage*)outputImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0);
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:NO];
    }
    else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    self.layer.contents = NULL;
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - setter

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[UIColor clearColor]];
    if (_backgroundColor != backgroundColor) {
#if !__has_feature(objc_arc)
        [_backgroundColor release];
#endif
        _backgroundColor = [backgroundColor retain];
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (_backgroundImage != backgroundImage) {
#if !__has_feature(objc_arc)
        [_backgroundImage release];
#endif
        _backgroundImage = [backgroundImage retain];
        
        [self setNeedsDisplay];
    }
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    if (_strokeColor != strokeColor) {
#if !__has_feature(objc_arc)
        [_strokeColor release];
#endif
        _strokeColor = [strokeColor copy];
        
        [self.paletteView saveColorWithStrokeColor:_strokeColor fillColor:nil];
    }
}

- (void)setFillColor:(UIColor *)fillColor {
    if (_fillColor != fillColor) {
#if !__has_feature(objc_arc)
        [_fillColor release];
#endif
        _fillColor = [fillColor copy];
        
        [self.paletteView saveColorWithStrokeColor:nil fillColor:_fillColor];
    }
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    
    [self.lineWidthSelectionView saveLineWidthWithWidth:_lineWidth];
}

- (void)setCanvasMode:(CCCCanvasPath)canvasMode {
    _canvasMode = canvasMode;
    
    if (self.paths.count > 0) {
        CCCCanvasPathObject *pathObject = [self.paths lastObject];
        pathObject.finished = YES;
    }
    
    if (self.undoPaths.count > 0) {
        NSArray *arrayNotFinished = [self.undoPaths filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.finished=NO"]];
        
        [self.undoPaths removeObjectsInArray:arrayNotFinished];
    }
}

#pragma mark - getter

- (BOOL)canUndo {
    return (self.paths.count > 0);
}

- (BOOL)canRedo {
    return (self.undoPaths.count > 0);
}

#pragma mark - Save & Load

- (NSArray<CCCCanvasPathObject *> *)paintingPaths {
    return self.paths;
}

- (void)restorePaintingWithPaths:(NSArray<CCCCanvasPathObject *> *)paintingPaths {
    self.paths = [NSMutableArray arrayWithArray:paintingPaths];
    
    [self setNeedsDisplay];
}

#pragma mark - setup

- (void)setup {
    self.multipleTouchEnabled = YES;
    self.exclusiveTouch = YES;
    
    _backgroundErasable = NO;
    
    _backgroundImage = nil;
    
    _strokeColor = [_paletteView.strokeColor copy];
    _fillColor = [_paletteView.fillColor copy];
    
    _lineWidth = _lineWidthSelectionView.lineWidth;
    
    _canvasMode = CCCCanvasPathPen;
    
    self.paths = [NSMutableArray arrayWithCapacity:0];
    self.undoPaths = [NSMutableArray arrayWithCapacity:0];
    
    _hasShadowEffect = NO;
    
    _drawingLayer = NULL;
    _scale = [UIScreen mainScreen].scale;
    
    _bounds = CGRectZero;
}

/// may return NULL, if not, the return result should be free using free().
- (CGPoint *)pointsFromPathObject:(CCCCanvasPathObject *)object {
    if (!object.points || object.points.count == 0) {
        return NULL;
    }
    
    CGPoint *points = (CGPoint*)calloc(object.points.count, sizeof(CGPoint));
    for (int i = 0; i < object.points.count; i ++) {
        NSValue *pointValue = [object.points objectAtIndex:i];
        if (isValidCGPointValue(pointValue)) {
            points[i] = [pointValue CGPointValue];
            points[i].x *= _scale;
            points[i].y *= _scale;
        }
    }
    
    return points;
}

- (void)drawPathWithContext:(CGContextRef)context path:(CCCCanvasPathObject *)pathObject {
    if (pathObject.points.count == 0) {
        return;
    }
    
    CGContextBeginPath(context);
    
    if (pathObject.pathMode != CCCCanvasPathEraser && pathObject.hasShadowEffect) {
        CGContextSetShadowWithColor(context, CGSizeZero, pathObject.lineWidth*_scale+4, pathObject.strokeColor.CGColor);
    }
    else {
        CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
    }
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    switch (pathObject.pathMode) {
        case CCCCanvasPathPen: {
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            if (pathObject.points.count == 1) {
                NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
                if (isValidCGPointValue(pointValue1)) {
                    CGPoint point1 = [pointValue1 CGPointValue];
                    CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                    CGContextAddLineToPoint(context, point1.x*_scale, point1.y*_scale);
                }
            }
            else {
                CGPoint *points = [self pointsFromPathObject:pathObject];
                
                CGContextAddLines(context, points, pathObject.points.count);
                
                if (points != NULL) {
                    free(points);
                }
                
//                for (NSValue *pointValue in pathObject.points) {
//                    if (![self isValidPointValue:pointValue]) return;
//                    
//                    CGPoint point1 = [pointValue CGPointValue];
//                    
//                    CGContextMoveToPoint(context, point1.x, point1.y);
//                    CGContextAddLineToPoint(context, point1.x, point1.y);
//                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathStraightLine: {
            CGContextSetLineCap(context, kCGLineCapRound);
            
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                
                if (pathObject.points.count > 1) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        CGContextAddLineToPoint(context, point2.x*_scale, point2.y*_scale);
                    }
                }
                else {
                    CGContextAddLineToPoint(context, point1.x*_scale, point1.y*_scale);
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathCurveLine: {
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                
                if (pathObject.points.count == 2) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        CGContextAddLineToPoint(context, point2.x*_scale, point2.y*_scale);
                    }
                }
                else if (pathObject.points.count == 3) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    NSValue *pointValue3 = [pathObject.points objectAtIndex:2];
                    if (!isValidCGPointValue(pointValue3)) {
                        CGPoint point3 = [pointValue3 CGPointValue];
                        CGContextAddLineToPoint(context, point3.x*_scale, point3.y*_scale);
                    }
                    else if (!isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        CGContextAddLineToPoint(context, point2.x*_scale, point2.y*_scale);
                    }
                    else {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        CGPoint point3 = [pointValue3 CGPointValue];
                        CGContextAddQuadCurveToPoint(context, point2.x*_scale, point2.y*_scale, point3.x*_scale, point3.y*_scale);
                        
//                        CGContextMoveToPoint(context, point1.x, point1.y);
//                        CGContextAddLineToPoint(context, point2.x, point2.y);
//                        CGContextAddLineToPoint(context, point3.x, point3.y);
                    }
                }
                else if (pathObject.points.count == 4) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    NSValue *pointValue3 = [pathObject.points objectAtIndex:2];
                    NSValue *pointValue4 = [pathObject.points objectAtIndex:3];
                    if (isValidCGPointValue(pointValue2) && isValidCGPointValue(pointValue3) && isValidCGPointValue(pointValue4)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        CGPoint point3 = [pointValue3 CGPointValue];
                        CGPoint point4 = [pointValue4 CGPointValue];
                        CGContextAddCurveToPoint(context, point2.x*_scale, point2.y*_scale, point3.x*_scale, point3.y*_scale, point4.x*_scale, point4.y*_scale);
                        
//                        CGContextMoveToPoint(context, point1.x, point1.y);
//                        CGContextAddLineToPoint(context, point2.x, point2.y);
//                        CGContextAddLineToPoint(context, point4.x, point4.y);
//                        
//                        CGContextMoveToPoint(context, point1.x, point1.y);
//                        CGContextAddLineToPoint(context, point3.x, point3.y);
//                        CGContextAddLineToPoint(context, point4.x, point4.y);
                    }
                }
                else {
                    CGContextAddLineToPoint(context, point1.x, point1.y);
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathFillPolygon: {
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            BOOL isClosedPath = NO;
            if (pathObject.points.count == 1) {
                NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
                if (isValidCGPointValue(pointValue1)) {
                    CGPoint point1 = [pointValue1 CGPointValue];
                    CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                    CGContextAddLineToPoint(context, point1.x*_scale, point1.y*_scale);
                }
            }
            else {
                CGPoint *points = [self pointsFromPathObject:pathObject];
                
                CGContextAddLines(context, points, pathObject.points.count);
                
                if (points != NULL) {
                    free(points);
                }
                
                NSValue *pointValueFirst = [pathObject.points firstObject];
                NSValue *pointValueLast = [pathObject.points lastObject];
                if (isValidCGPointValue(pointValueFirst) && isValidCGPointValue(pointValueLast)) {
                    CGPoint firstPoint = [pointValueFirst CGPointValue];
                    CGPoint lastPoint = [pointValueLast CGPointValue];
                    
                    if (CGPointEqualToPoint(firstPoint, lastPoint)) {
                        isClosedPath = YES;
                    }
                }
            }
                        
            if (pathObject.finished || isClosedPath) {
                CGContextClosePath(context);
                CGContextDrawPath(context, kCGPathFillStroke);
            }
            else {
                CGContextDrawPath(context, kCGPathStroke);
            }
            
            break;
        }
        case CCCCanvasPathStrokePolygon: {
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            if (pathObject.points.count == 1) {
                NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
                if (isValidCGPointValue(pointValue1)) {
                    CGPoint point1 = [pointValue1 CGPointValue];
                    CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                    CGContextAddLineToPoint(context, point1.x*_scale, point1.y*_scale);
                }
            }
            else {
                CGPoint *points = [self pointsFromPathObject:pathObject];
                
                CGContextAddLines(context, points, pathObject.points.count);
                
                if (points != NULL) {
                    free(points);
                }
            }
            
            if (pathObject.finished) {
                CGContextClosePath(context);
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathFillRect: {
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                
                if (pathObject.points.count == 2) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        
                        CGContextAddRect(context, CGRectMake(point1.x*_scale, point1.y*_scale, (point2.x-point1.x)*_scale, (point2.y-point1.y)*_scale));
                    }
                }
            }
            
            CGContextDrawPath(context, kCGPathFillStroke);
            
            break;
        }
        case CCCCanvasPathStrokeRect: {
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                
                if (pathObject.points.count == 2) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        
                        CGContextAddRect(context, CGRectMake(point1.x*_scale, point1.y*_scale, (point2.x-point1.x)*_scale, (point2.y-point1.y)*_scale));
                    }
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathFillEllipse: {
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                
                if (pathObject.points.count == 2) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        
                        CGContextAddEllipseInRect(context, CGRectMake(point1.x*_scale, point1.y*_scale, (point2.x-point1.x)*_scale, (point2.y-point1.y)*_scale));
                    }
                }
            }
            
            CGContextDrawPath(context, kCGPathFillStroke);
            
            break;
        }
        case CCCCanvasPathStrokeEllipse: {
            NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue1)) {
                CGPoint point1 = [pointValue1 CGPointValue];
                
                if (pathObject.points.count == 2) {
                    NSValue *pointValue2 = [pathObject.points objectAtIndex:1];
                    if (isValidCGPointValue(pointValue2)) {
                        CGPoint point2 = [pointValue2 CGPointValue];
                        
                        CGContextAddEllipseInRect(context, CGRectMake(point1.x*_scale, point1.y*_scale, (point2.x-point1.x)*_scale, (point2.y-point1.y)*_scale));
                    }
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        case CCCCanvasPathEraser: {
            CGContextSetBlendMode(context, kCGBlendModeClear);
            CGContextSetLineWidth(context, pathObject.lineWidth*_scale*2);
            
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            
            if (pathObject.points.count == 1) {
                NSValue *pointValue1 = [pathObject.points objectAtIndex:0];
                if (isValidCGPointValue(pointValue1)) {
                    CGPoint point1 = [pointValue1 CGPointValue];
                    CGContextMoveToPoint(context, point1.x*_scale, point1.y*_scale);
                    CGContextAddLineToPoint(context, point1.x*_scale, point1.y*_scale);
                }
            }
            else {
                CGPoint *points = [self pointsFromPathObject:pathObject];
                
                CGContextAddLines(context, points, pathObject.points.count);
                
                if (points != NULL) {
                    free(points);
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            break;
        }
        default:
            break;
    }
}

- (void)newTouchWithPoint:(CGPoint)point {
    [self.undoPaths removeAllObjects];
    
    CCCCanvasPathObject *pathObject = [self.paths lastObject];
    
    if (pathObject) {
        if (pathObject.pathMode == CCCCanvasPathCurveLine) {
            if (pathObject.points.count == 1) {
                _currentCurveIndex = 1;
                [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            }
            else if (pathObject.points.count == 2) {
                _currentCurveIndex = 1;
                [pathObject.points insertObject:[NSValue valueWithCGPoint:point] atIndex:1];
            }
            else if (pathObject.points.count == 3) {
                CGPoint point1 = CGPointZero;
                if (isValidCGPointValue([pathObject.points objectAtIndex:0])) {
                    point1 = [[pathObject.points objectAtIndex:0] CGPointValue];
                }
                CGPoint point2 = CGPointZero;
                if (isValidCGPointValue([pathObject.points objectAtIndex:1])) {
                    point2 = [[pathObject.points objectAtIndex:1] CGPointValue];
                }
                CGPoint point3 = CGPointZero;
                if (isValidCGPointValue([pathObject.points objectAtIndex:2])) {
                    point3 = [[pathObject.points objectAtIndex:2] CGPointValue];
                }
                
                if (([self distanceBetweenPoint1:point1 andPoint2:point2] > [self distanceBetweenPoint1:point3 andPoint2:point2]) &&
                    ([self distanceBetweenPoint1:point1 andPoint2:_currentPoint] < [self distanceBetweenPoint1:point3 andPoint2:_currentPoint])) {
                    _currentCurveIndex = 1;
                    [pathObject.points insertObject:[NSValue valueWithCGPoint:point] atIndex:1];
                }
                else {
                    _currentCurveIndex = 2;
                    [pathObject.points insertObject:[NSValue valueWithCGPoint:point] atIndex:2];
                }
            }
            else if (pathObject.points.count == 4) {
                pathObject.finished = YES;
            }
            
            [pathObject calculateBoundingRect];
        }
        else if (pathObject.pathMode == CCCCanvasPathStrokePolygon || pathObject.pathMode == CCCCanvasPathFillPolygon) {
            
            NSValue *pointValueFirst = [pathObject.points firstObject];
            NSValue *pointValueLast = [pathObject.points lastObject];
            if (isValidCGPointValue(pointValueFirst) && isValidCGPointValue(pointValueLast)) {
                CGPoint firstPoint = [pointValueFirst CGPointValue];
                CGPoint lastPoint = [pointValueLast CGPointValue];
                
                if (CGPointEqualToPoint(firstPoint, lastPoint) && pathObject.points.count > 1) {
                    pathObject.finished = YES;
                }
                else {
                    [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
                }
            }
            else {
                [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            }
            
            [pathObject calculateBoundingRect];
        }
        else {
            pathObject.finished = YES;
        }
    }
    
    if (!pathObject || pathObject.finished) {
        CCCCanvasPathObject *newPathObject = [[CCCCanvasPathObject alloc] init];
        newPathObject.pathMode = _canvasMode;
        newPathObject.strokeColor = _strokeColor;
        newPathObject.fillColor = _fillColor;
        newPathObject.lineWidth = _lineWidth;
        newPathObject.hasShadowEffect = _hasShadowEffect;
        [newPathObject.points addObject:[NSValue valueWithCGPoint:point]];
        [newPathObject calculateBoundingRect];
        [self.paths addObject:newPathObject];
        [newPathObject release];
        
        _currentCurveIndex = 1;
    }
    
}

- (void)updatePointData:(CCCCanvasPathObject *)pathObject withPoint:(CGPoint)point {
    switch (pathObject.pathMode) {
        case CCCCanvasPathPen:
        case CCCCanvasPathEraser: {
            [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            
            break;
        }
        case CCCCanvasPathStraightLine:
        case CCCCanvasPathFillRect:
        case CCCCanvasPathStrokeRect:
        case CCCCanvasPathFillEllipse:
        case CCCCanvasPathStrokeEllipse: {
            if (pathObject.points.count == 1) {
                [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            }
            else {
                [pathObject.points replaceObjectAtIndex:1 withObject:[NSValue valueWithCGPoint:point]];
            }
            
            break;
        }
        case CCCCanvasPathCurveLine: {
            if (pathObject.points.count == 1) {
                [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            }
            else {
                [pathObject.points replaceObjectAtIndex:_currentCurveIndex withObject:[NSValue valueWithCGPoint:point]];
            }
            
            break;
        }
        case CCCCanvasPathFillPolygon:
        case CCCCanvasPathStrokePolygon: {
            if (pathObject.points.count == 1) {
                [pathObject.points addObject:[NSValue valueWithCGPoint:point]];
            }
            else {
                [pathObject.points replaceObjectAtIndex:pathObject.points.count-1 withObject:[NSValue valueWithCGPoint:point]];
            }
            
            break;
        }
        default:
            break;
    }
    
    [pathObject calculateBoundingRect];
}

- (void)checkPathFinished:(CCCCanvasPathObject *)pathObject withPoint:(CGPoint)point  {
    switch (pathObject.pathMode) {
        case CCCCanvasPathPen:
        case CCCCanvasPathStraightLine:
        case CCCCanvasPathFillRect:
        case CCCCanvasPathStrokeRect:
        case CCCCanvasPathFillEllipse:
        case CCCCanvasPathStrokeEllipse:
        case CCCCanvasPathEraser: {
            pathObject.finished = YES;
            
            break;
        }
        case CCCCanvasPathCurveLine: {
            break;
        }
        case CCCCanvasPathFillPolygon:
        case CCCCanvasPathStrokePolygon: {
            NSValue *pointValue = [pathObject.points objectAtIndex:0];
            if (isValidCGPointValue(pointValue)) {
                CGPoint firstPoint = [pointValue CGPointValue];
                if ([self distanceBetweenPoint1:firstPoint andPoint2:point] < 20.0 && pathObject.points.count > 2) {
                    [pathObject.points replaceObjectAtIndex:pathObject.points.count-1 withObject:[NSValue valueWithCGPoint:firstPoint]];
                }
            }
            
            [pathObject calculateBoundingRect];
            break;
        }
        default:
            break;
    }
    
}

- (CGFloat)distanceBetweenPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2 {
    return sqrt(pow((point1.x-point2.x), 2)+pow((point1.y-point2.y), 2));
}

#pragma mark - UITouchEvents

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self];
    
    [self newTouchWithPoint:_currentPoint];
    
    [self setNeedsDisplay];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvasDidBeginPainting:)]) {
        [self.delegate canvasDidBeginPainting:self];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self];
    
    CCCCanvasPathObject *pathObject = [self.paths lastObject];
    [self updatePointData:pathObject withPoint:_currentPoint];
    
    [self setNeedsDisplay];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvasIsPainting:)]) {
        [self.delegate canvasIsPainting:self];
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self];
    
    CCCCanvasPathObject *pathObject = [self.paths lastObject];
    [self checkPathFinished:pathObject withPoint:_currentPoint];
    
    [self setNeedsDisplay];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvasDidEndPainting:)]) {
        [self.delegate canvasDidEndPainting:self];
    }
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self];
    
    CCCCanvasPathObject *pathObject = [self.paths lastObject];
    [self checkPathFinished:pathObject withPoint:_currentPoint];
    
    [self setNeedsDisplay];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvasDidEndPainting:)]) {
        [self.delegate canvasDidEndPainting:self];
    }
    
}

#pragma mark - CCCCanvasPaletteDelegate

- (void)paletteView:(CCCCanvasPaletteView *)view didFinishSelectColorWithStrokeColor:(UIColor *)strokeColor andFillColor:(UIColor *)fillColor {
    
    self.strokeColor = strokeColor;
    self.fillColor = fillColor;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvas:didClosePaletteView:)]) {
        [self.delegate canvas:self didClosePaletteView:self.paletteView];
    }
}

- (void)paletteViewDidClose:(CCCCanvasPaletteView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvas:didClosePaletteView:)]) {
        [self.delegate canvas:self didClosePaletteView:self.paletteView];
    }
}

#pragma mark - CCCCanvasLineWidthSelectionDelegate

- (void)lineWidthSelectionView:(CCCCanvasLineWidthSelectionView *)view didFinishSelectLineWidthWithWidth:(CGFloat)lineWidth {
    
    self.lineWidth = lineWidth;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvas:didCloseLineWidthSelectionView:)]) {
        [self.delegate canvas:self didCloseLineWidthSelectionView:self.lineWidthSelectionView];
    }
}

- (void)lineWidthSelectionViewDidClose:(CCCCanvasLineWidthSelectionView *)view {
    if (self.delegate && [self.delegate respondsToSelector:@selector(canvas:didCloseLineWidthSelectionView:)]) {
        [self.delegate canvas:self didCloseLineWidthSelectionView:self.lineWidthSelectionView];
    }
}

@end
