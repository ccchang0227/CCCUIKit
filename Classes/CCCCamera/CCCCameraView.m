//
//  CCCCameraView.m
//
//  Created by CHIEN-HSU WU on 2015/8/17.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCameraView.h"
#import "UIImage+CCCProcessor.h"

#import <CoreMotion/CoreMotion.h>




#pragma mark ****** CCCCameraFocusAreaLayer ******

@interface CCCCameraFocusAreaLayer : CALayer {
@package
    CGSize _size;
    CGFloat _sight;
    CFTimeInterval _delay;
    BOOL _canDraw;
    
    BOOL _fadeOut;
    
    BOOL _subjectAreaChanged;
    
    float _bias, _min, _max;
    BOOL _shouldDrawBiasText;
}

@property (nonatomic) BOOL shouldDrawExposure;

@property (nonatomic) CGPoint focusPoint;

@property (readonly, getter=isExposureBiasAdjustable) BOOL exposureBiasAdjustable;

- (void)clearFocusPoint;

- (void)fadeInFocusArea;
- (void)setExposureBias:(float)bias min:(float)min max:(float)max;
- (void)fadeOutFocusArea;

- (void)focusAtSubjectChanged;

@end

@implementation CCCCameraFocusAreaLayer

+ (instancetype)layer {
    return [[[[self class] alloc] init] autorelease];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _size = CGSizeMake(76, 76);
        _sight = 6.0f;
        _delay = 5;
        _canDraw = NO;
        _fadeOut = NO;
        _subjectAreaChanged = NO;
        
        _shouldDrawExposure = YES;
        
        _focusPoint = CGPointZero;
        
        _bias = 0;
        _min = -1;
        _max = 1;
        _shouldDrawBiasText = NO;
    }
    return self;
}

- (void)setFocusPoint:(CGPoint)focusPoint {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearFocusPoint) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutFocusArea) object:nil];
    
    _focusPoint = focusPoint;
    _bias = 0;
    _min = -1;
    _max = 1;
    _shouldDrawBiasText = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _canDraw = YES;
        _fadeOut = NO;
        _subjectAreaChanged = NO;
        [self setNeedsDisplay];
    });
    
    [self performSelector:@selector(clearFocusPoint) withObject:nil afterDelay:_delay];
    
}

- (void)clearFocusPoint {
    dispatch_async(dispatch_get_main_queue(), ^{
        _canDraw = NO;
        _fadeOut = NO;
        _subjectAreaChanged = NO;
        [self setNeedsDisplay];
    });
}

- (void)fadeInFocusArea {
    dispatch_async(dispatch_get_main_queue(), ^{
        _fadeOut = NO;
        _subjectAreaChanged = NO;
        [self setNeedsDisplay];
    });
}

- (void)setExposureBias:(float)bias min:(float)min max:(float)max {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearFocusPoint) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutFocusArea) object:nil];
    
    _bias = bias;
    _min = min;
    _max = max;
    _shouldDrawBiasText = YES;
    
    [self fadeInFocusArea];
    
}

- (void)fadeOutFocusArea {
    dispatch_async(dispatch_get_main_queue(), ^{
        _fadeOut = YES;
        _subjectAreaChanged = NO;
        [self setNeedsDisplay];
    });
}

- (BOOL)isExposureBiasAdjustable {
    return _canDraw;
}

- (void)focusAtSubjectChanged {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearFocusPoint) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutFocusArea) object:nil];
    
    _focusPoint = CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0);
    _bias = 0;
    _min = -1;
    _max = 1;
    _shouldDrawBiasText = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _canDraw = NO;
        _fadeOut = NO;
        _subjectAreaChanged = YES;
        [self setNeedsDisplay];
    });
    
    [self performSelector:@selector(clearFocusPoint) withObject:nil afterDelay:2];
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    UIColor *color = [UIColor colorWithRed:1.000 green:0.800 blue:0.000 alpha:1.000];
    
    if (_subjectAreaChanged) {
        @synchronized (self) {
            CGContextSaveGState(ctx);
            
            CGSize size = {100, 100};
            
            CGContextSetShouldAntialias(ctx, true);
            CGContextSetAllowsAntialiasing(ctx, true);
            CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
            CGContextSetStrokeColorWithColor(ctx, color.CGColor);
            CGContextSetLineWidth(ctx, 1.0);
            CGContextSetAlpha(ctx, 1);
            
            // Rect
            CGContextStrokeRect(ctx, CGRectMake(_focusPoint.x-size.width/2.0, _focusPoint.y-size.height/2.0, size.width, size.height));
            
            CGContextRestoreGState(ctx);
        }
        
        return;
    }
    
    if (!_canDraw) {
        return;
    }
    
    @synchronized(self) {
        CGContextSaveGState(ctx);
        
        CGContextSetShouldAntialias(ctx, true);
        CGContextSetAllowsAntialiasing(ctx, true);
        CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        if (_fadeOut) {
            CGContextSetAlpha(ctx, 0.3);
        }
        else {
            CGContextSetAlpha(ctx, 1);
        }
        
        // Rect
        CGContextStrokeRect(ctx, CGRectMake(_focusPoint.x-_size.width/2.0, _focusPoint.y-_size.height/2.0, _size.width, _size.height));
        
        // Focus
        for (int i = 0; i < 4; i ++) {
            CGPoint endPoint = CGPointZero;
            switch (i) {
                case 0:
                    CGContextMoveToPoint(ctx, _focusPoint.x, _focusPoint.y-_size.height/2.0);
                    endPoint = CGPointMake(_focusPoint.x, _focusPoint.y-_size.height/2.0+_sight);
                    break;
                case 1:
                    CGContextMoveToPoint(ctx, _focusPoint.x, _focusPoint.y+_size.height/2.0);
                    endPoint = CGPointMake(_focusPoint.x, _focusPoint.y+_size.height/2.0-_sight);
                    break;
                case 2:
                    CGContextMoveToPoint(ctx, _focusPoint.x-_size.width/2.0, _focusPoint.y);
                    endPoint = CGPointMake(_focusPoint.x-_size.width/2.0+_sight, _focusPoint.y);
                    break;
                case 3:
                    CGContextMoveToPoint(ctx, _focusPoint.x+_size.width/2.0, _focusPoint.y);
                    endPoint = CGPointMake(_focusPoint.x+_size.width/2.0-_sight, _focusPoint.y);
                    break;
                default:
                    break;
            }
            CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
        }
        CGContextDrawPath(ctx, kCGPathStroke);
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && _shouldDrawExposure) {
            // draw slider bar
            CGFloat scaleValue = (_bias-_min) / (_max-_min); // convert to 0~1
            
            CGFloat convertScale = (scaleValue-0.5) * 2; // convert to -1~1
            CGFloat yPosition = _focusPoint.y - convertScale*(_size.height/2.0+5);
            
//            CGRect imageRect = CGRectMake(_focusPoint.x+_size.width/2.0+2, _focusPoint.y-15, 30, 30);
            CGRect imageRect = CGRectMake(_focusPoint.x+_size.width/2.0+2, yPosition-15, 30, 30);
            UIImage *lightImage = [UIImage imageNamed:@"CCCCamera_Light.png"];
            CGContextSetShouldAntialias(ctx, true);
            CGContextSetAllowsAntialiasing(ctx, true);
            CGContextSetInterpolationQuality(ctx, kCGInterpolationDefault);
            CGContextSetRenderingIntent(ctx, CGImageGetRenderingIntent(lightImage.CGImage));
            CGContextDrawImage(ctx, imageRect, lightImage.CGImage);
            
//            CGContextMoveToPoint(ctx, _focusPoint.x+_size.width/2.0+17, _focusPoint.y-16);
            CGContextMoveToPoint(ctx, _focusPoint.x+_size.width/2.0+17, yPosition-15);
            CGContextAddLineToPoint(ctx, _focusPoint.x+_size.width/2.0+17, _focusPoint.y-_size.height/2.0-20);
            
//            CGContextMoveToPoint(ctx, _focusPoint.x+_size.width/2.0+17, _focusPoint.y+16);
            CGContextMoveToPoint(ctx, _focusPoint.x+_size.width/2.0+17, yPosition+15);
            CGContextAddLineToPoint(ctx, _focusPoint.x+_size.width/2.0+17, _focusPoint.y+_size.height/2.0+20);
            
            CGContextDrawPath(ctx, kCGPathStroke);
            
            if (_shouldDrawBiasText) {
                // Draw exposure value text
                NSString *sign = (_bias<0? @"-": @"+");
                NSString *biasString = [NSString stringWithFormat:@"%.2f", fabsf(_bias)];
                if ([biasString isEqualToString:@"0.00"]) {
                    sign = @"";
                }
                biasString = [NSString stringWithFormat:@"%@%@", sign, biasString];
                
                UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
                NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
                NSDictionary *attribute = @{NSForegroundColorAttributeName:color, NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
                CGSize sizeOfText = [biasString sizeWithAttributes:attribute];
                CGPoint textPosition = CGPointMake(_focusPoint.x-sizeOfText.width/2.0, _focusPoint.y-_size.height/2.0-font.lineHeight);
                
                UIGraphicsPushContext(ctx);
                [biasString drawAtPoint:textPosition withAttributes:attribute];
                UIGraphicsPopContext();
            }
            
        }
        
        CGContextRestoreGState(ctx);
        
    }
    
}

@end


#pragma mark ****** CCCCameraCornersLayer ******

@interface CCCCameraCornersLayer : CALayer

@property (retain, nonatomic) NSArray *cornersArray;

@end

@implementation CCCCameraCornersLayer

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_cornersArray release];
    [super dealloc];
#endif
    
}

- (void)setCornersArray:(NSArray*)cornersArray {
    if (_cornersArray != cornersArray) {
#if !__has_feature(objc_arc)
        [_cornersArray release];
#endif
        _cornersArray = [cornersArray retain];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self setNeedsDisplay];
        });
    }
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    @synchronized(self) {
        CGContextSaveGState(ctx);
        
        CGContextSetShouldAntialias(ctx, YES);
        CGContextSetAllowsAntialiasing(ctx, YES);
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.000 green:0.000 blue:1.000 alpha:0.400].CGColor);
        CGContextSetStrokeColorWithColor(ctx, [UIColor greenColor].CGColor);
        CGContextSetLineWidth(ctx, 2.0);
        
        NSArray *filteredArray = [self.cornersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF isKindOfClass:%@", [NSArray class]]];
        for (NSArray *corners in filteredArray) {
            for (int i = 0; i < corners.count; i ++) {
                NSDictionary *dic = [corners objectAtIndex:i];
                CGPoint point = CGPointZero;
                CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)dic, &point);
                
                if (i == 0) {
                    CGContextMoveToPoint(ctx, point.x, point.y);
                }
                else {
                    CGContextAddLineToPoint(ctx, point.x, point.y);
                }
            }
            CGContextClosePath(ctx);
        }
        CGContextDrawPath(ctx, kCGPathFillStroke);
        
        filteredArray = [self.cornersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF isKindOfClass:%@", [NSString class]]];
        for (NSString *rectString in filteredArray) {
            CGRect rect = CGRectFromString(rectString);
            CGContextAddRect(ctx, rect);
        }
        CGContextDrawPath(ctx, kCGPathStroke);
        
        CGContextRestoreGState(ctx);
    }
}

@end


#pragma mark ****** CCCCameraPreviewView ******

@interface CCCCameraPreviewView : UIView

@property (retain, nonatomic) CCCCameraCornersLayer *cornersLayer;

@end

@implementation CCCCameraPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
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
    [_cornersLayer release];
    [super dealloc];
#endif
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    _cornersLayer.frame = self.bounds;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _cornersLayer.frame = self.bounds;
}

- (void)layoutSubviews {
    _cornersLayer.frame = self.bounds;
    
    [super layoutSubviews];
}

#pragma mark -

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    
    _cornersLayer = [[CCCCameraCornersLayer alloc] init];
    _cornersLayer.backgroundColor = [UIColor clearColor].CGColor;
    _cornersLayer.frame = self.bounds;
    [self.layer addSublayer:_cornersLayer];
}

@end


#pragma mark ****** CCCCameraView ******

@interface CCCCameraView () {
    UIInterfaceOrientation _oldOrientation;
    
    BOOL _lockPictureOrientation;
    UIInterfaceOrientation _pictureOrientation;
    
}

@property (retain, nonatomic) CCCCameraPreviewView *preview;
@property (readonly) AVCaptureVideoPreviewLayer *previewLayer;

@property (retain, nonatomic) CCCCameraFocusAreaLayer *focusAreaLayer;

@property (retain, nonatomic) UISlider *exposureBiasSlider;
@property (retain, nonatomic) UILabel *exposureBiasLabel;

@property (retain, nonatomic) CMMotionManager *motionManager;
@property (retain, nonatomic) NSOperationQueue *motionQueue;

@end

@implementation CCCCameraView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
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
    if (_cameraSession.isCameraRunning) {
        [self stopCameraRunning];
    }
    
    [_motionManager stopAccelerometerUpdates];
    [_motionQueue cancelAllOperations];
    [_motionQueue setSuspended:YES];
    
#if !__has_feature(objc_arc)
    [_cameraSession release];
    [_preview release];
    [_focusAreaLayer release];
    [_exposureBiasLabel release];
    [_exposureBiasSlider release];
    [_motionManager release];
    [_motionQueue release];
    [super dealloc];
#endif
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    _focusAreaLayer.frame = self.bounds;
    _exposureBiasSlider.frame = CGRectMake(CGRectGetWidth(self.bounds)-50, CGRectGetHeight(self.bounds)*0.1, 50, CGRectGetHeight(self.bounds)*0.8);
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _focusAreaLayer.frame = self.bounds;
    _exposureBiasSlider.frame = CGRectMake(CGRectGetWidth(self.bounds)-50, CGRectGetHeight(self.bounds)*0.1, 50, CGRectGetHeight(self.bounds)*0.8);
}

- (void)layoutSubviews {
    _focusAreaLayer.frame = self.bounds;
    _exposureBiasSlider.frame = CGRectMake(CGRectGetWidth(self.bounds)-50, CGRectGetHeight(self.bounds)*0.1, 50, CGRectGetHeight(self.bounds)*0.8);
    
    [super layoutSubviews];
}

- (CCCCameraPreviewView *)preview {
    if (_preview == nil) {
        _preview = [[CCCCameraPreviewView alloc] init];
        _preview.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_preview];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_preview]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_preview)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_preview]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_preview)]];
    }
    
    return _preview;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.preview.layer;
}

- (UILabel *)exposureBiasLabel {
    if (_exposureBiasLabel == nil) {
        _exposureBiasLabel = [[UILabel alloc] init];
        _exposureBiasLabel.backgroundColor = [UIColor clearColor];
        _exposureBiasLabel.textColor = [UIColor whiteColor];
        _exposureBiasLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        [self addSubview:_exposureBiasLabel];
        
    }
    
    return _exposureBiasLabel;
}

- (UISlider *)exposureBiasSlider {
    if (_exposureBiasSlider == nil) {
        _exposureBiasSlider = [[UISlider alloc] init];
        _exposureBiasSlider.backgroundColor = [UIColor clearColor];
        _exposureBiasSlider.maximumTrackTintColor = [UIColor whiteColor];
        _exposureBiasSlider.minimumTrackTintColor = [UIColor whiteColor];
        _exposureBiasSlider.minimumValue = -1;
        _exposureBiasSlider.maximumValue = 1;
        _exposureBiasSlider.value = 0;
        [_exposureBiasSlider addTarget:self action:@selector(_exposureSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_exposureBiasSlider];
        
        _exposureBiasSlider.transform = CGAffineTransformMakeRotation(-M_PI_2);
        _exposureBiasSlider.frame = CGRectMake(CGRectGetWidth(self.bounds)-50, CGRectGetHeight(self.bounds)*0.1, 50, CGRectGetHeight(self.bounds)*0.8);
    }
    
    return _exposureBiasSlider;
}

- (CMMotionManager*)motionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = 0.2;
    }
    
    return _motionManager;
}

- (NSOperationQueue*)motionQueue {
    if (_motionQueue == nil) {
        _motionQueue = [[NSOperationQueue alloc] init];
    }
    
    return _motionQueue;
}

- (void)setScaleType:(CCCCameraPreviewScaleType)scaleType {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
    
    _scaleType = scaleType;
    
    NSDictionary *scaleTypeMap = @{@(CCCCameraPreviewScaleTypeScaleAspectFit):AVLayerVideoGravityResizeAspect,
                                   @(CCCCameraPreviewScaleTypeScaleAspectFill):AVLayerVideoGravityResizeAspectFill
                                   };
    self.previewLayer.videoGravity = [scaleTypeMap objectForKey:@(scaleType)];
    
}

- (void)setExposureControlMode:(CCCCameraExposureControlMode)exposureControlMode {
    _exposureControlMode = exposureControlMode;
    
    [self _clearFocus];
    
    switch (_exposureControlMode) {
        case CCCCameraExposureControlModeSlider: {
            self.exposureBiasSlider.minimumValue = _cameraSession.minExposureBias;
            self.exposureBiasSlider.maximumValue = _cameraSession.maxExposureBias;
            self.exposureBiasSlider.value = _cameraSession.currentExposureBias;
            [self _configureExposureLabel:self.exposureBiasSlider.value];
            
            self.cameraSession.lockExposure = YES;
            self.exposureBiasSlider.hidden = NO;
            self.exposureBiasLabel.hidden = NO;
            [self _fadeOutExposureComponents];
            self.focusAreaLayer.shouldDrawExposure = NO;
            
            break;
        }
        default: {
            self.cameraSession.lockExposure = NO;
            self.exposureBiasSlider.hidden = YES;
            self.exposureBiasLabel.hidden = YES;
            self.focusAreaLayer.shouldDrawExposure = YES;
            
            break;
        }
    }
    
}

- (void)setVideoQuality:(CCCCameraVideoQuality)videoQuality {
    _cameraSession.videoQuality = videoQuality;
}

- (CCCCameraVideoQuality)videoQuality {
    return _cameraSession.videoQuality;
}

- (void)setCameraCaptureMode:(CCCCameraCaptureMode)cameraCaptureMode {
    _cameraSession.cameraCaptureMode = cameraCaptureMode;
}

- (CCCCameraCaptureMode)cameraCaptureMode {
    return _cameraSession.cameraCaptureMode;
}

- (void)setCameraDevice:(CCCCameraDevice)cameraDevice {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
    
    _cameraSession.cameraDevice = cameraDevice;
}

- (CCCCameraDevice)cameraDevice {
    return _cameraSession.cameraDevice;
}

- (void)setCameraFlashMode:(CCCCameraFlashMode)cameraFlashMode {
    _cameraSession.cameraFlashMode = cameraFlashMode;
}

- (CCCCameraFlashMode)cameraFlashMode {
    return _cameraSession.cameraFlashMode;
}

- (void)setCameraMirrorType:(CCCCameraVideoMirrorType)cameraMirrorType {
    _cameraSession.cameraMirrorType = cameraMirrorType;
}

- (CCCCameraVideoMirrorType)cameraMirrorType {
    return _cameraSession.cameraMirrorType;
}

- (void)setFaceDetectEnabled:(BOOL)faceDetectEnabled {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
    
    _cameraSession.faceDetectEnabled = faceDetectEnabled;
}

- (BOOL)isFaceDetectEnabled {
    return _cameraSession.isFaceDetectEnabled;
}

- (void)setBarcodeScanEnabled:(BOOL)barcodeScanEnabled {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
    
    _cameraSession.barcodeScanEnabled = barcodeScanEnabled;
}

- (BOOL)isBarcodeScanEnabled {
    return _cameraSession.isBarcodeScanEnabled;
}

- (NSTimeInterval)recordedVideoDuration {
    return _cameraSession.recordedVideoDuration;
}

- (void)setMaxVideoDuration:(NSTimeInterval)maxVideoDuration {
    _cameraSession.maxVideoDuration = maxVideoDuration;
}

- (NSTimeInterval)maxVideoDuration {
    return _cameraSession.maxVideoDuration;
}

- (void)setMuteVideo:(BOOL)muteVideo {
    _cameraSession.muteVideo = muteVideo;
}

- (BOOL)muteVideo {
    return _cameraSession.muteVideo;
}

#pragma mark -

- (void)_setup {
    self.clipsToBounds = YES;
    
    _cameraSession = [[CCCCameraSession alloc] initWithVideoPreviewLayer:self.previewLayer];
    _cameraSession.delegate = self;
    
    self.scaleType = CCCCameraPreviewScaleTypeScaleAspectFit;
    
    _focusAreaLayer = [[CCCCameraFocusAreaLayer alloc] init];
    _focusAreaLayer.backgroundColor = [UIColor clearColor].CGColor;
    _focusAreaLayer.frame = self.bounds;
    [self.layer addSublayer:_focusAreaLayer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapGesture:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(_pinchGesture:)];
    [self addGestureRecognizer:pinchGestureRecognizer];
    [pinchGestureRecognizer release];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        self.exposureControlMode = CCCCameraExposureControlModeSystem;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panGesture:)];
        [self addGestureRecognizer:panGestureRecognizer];
        [panGestureRecognizer release];
    }
    
    _oldOrientation = UIInterfaceOrientationUnknown;
    
}

- (NSDictionary*)_editedMetadataDictionary:(NSDictionary*)sourceMetadata ofImage:(UIImage*)image {
    CFMutableDictionaryRef mutableMetadata = CFDictionaryCreateMutableCopy(NULL, 0, (CFDictionaryRef)sourceMetadata);
    
    if (CFDictionaryContainsKey(mutableMetadata, kCGImagePropertyExifDictionary)) {
        CFDictionaryRef exif = CFDictionaryGetValue(mutableMetadata, kCGImagePropertyExifDictionary);
        CFMutableDictionaryRef mutableExif = CFDictionaryCreateMutableCopy(NULL, 0, exif);
        CFDictionarySetValue(mutableExif, kCGImagePropertyExifPixelXDimension, (CFNumberRef)@(CGImageGetWidth(image.CGImage)));
        CFDictionarySetValue(mutableExif, kCGImagePropertyExifPixelYDimension, (CFNumberRef)@(CGImageGetHeight(image.CGImage)));
        CFDictionarySetValue(mutableMetadata, kCGImagePropertyExifDictionary, mutableExif);
        CFRelease(mutableExif);
    }
    
    CFDictionarySetValue(mutableMetadata, kCGImagePropertyPixelWidth, (CFNumberRef)@(CGImageGetWidth(image.CGImage)));
    CFDictionarySetValue(mutableMetadata, kCGImagePropertyPixelHeight, (CFNumberRef)@(CGImageGetHeight(image.CGImage)));
    
    CGImagePropertyOrientation realOrientation = [self _imagePropertyOrientationFromUIImageOrientation:image.imageOrientation];
    CFDictionarySetValue(mutableMetadata, kCGImagePropertyOrientation, (CFNumberRef)@(realOrientation));
    
    if (CFDictionaryContainsKey(mutableMetadata, kCGImagePropertyTIFFDictionary)) {
        CFDictionaryRef tiff = CFDictionaryGetValue(mutableMetadata, kCGImagePropertyTIFFDictionary);
        CFMutableDictionaryRef mutableTiff = CFDictionaryCreateMutableCopy(NULL, 0, tiff);
        CFDictionarySetValue(mutableTiff, kCGImagePropertyTIFFOrientation, (CFNumberRef)@(realOrientation));
        CFDictionarySetValue(mutableMetadata, kCGImagePropertyTIFFDictionary, mutableTiff);
        CFRelease(mutableTiff);
    }
    
    if (CFDictionaryContainsKey(mutableMetadata, kCGImagePropertyIPTCDictionary)) {
        CFDictionaryRef iptc = CFDictionaryGetValue(mutableMetadata, kCGImagePropertyIPTCDictionary);
        CFMutableDictionaryRef mutableIptc = CFDictionaryCreateMutableCopy(NULL, 0, iptc);
        size_t imageWidth = CGImageGetWidth(image.CGImage);
        size_t imageHeight = CGImageGetHeight(image.CGImage);
        if (imageWidth > imageHeight) {
            CFDictionarySetValue(mutableIptc, kCGImagePropertyIPTCImageOrientation, (CFStringRef)@"L");
        }
        else if (imageWidth < imageHeight) {
            CFDictionarySetValue(mutableIptc, kCGImagePropertyIPTCImageOrientation, (CFStringRef)@"P");
        }
        else {
            CFDictionarySetValue(mutableIptc, kCGImagePropertyIPTCImageOrientation, (CFStringRef)@"S");
        }
        CFDictionarySetValue(mutableMetadata, kCGImagePropertyIPTCDictionary, mutableIptc);
        CFRelease(mutableIptc);
    }
    
    NSDictionary *destMetadata = [NSDictionary dictionaryWithDictionary:(NSDictionary*)mutableMetadata];
    
    CFRelease(mutableMetadata);
    
    return destMetadata;
}

- (CGImagePropertyOrientation)_imagePropertyOrientationFromUIImageOrientation:(UIImageOrientation)imageOrientation {
    switch (imageOrientation) {
        case UIImageOrientationUp:
            return kCGImagePropertyOrientationUp;
            break;
        case UIImageOrientationUpMirrored:
            return kCGImagePropertyOrientationUpMirrored;
            break;
        case UIImageOrientationDown:
            return kCGImagePropertyOrientationDown;
            break;
        case UIImageOrientationDownMirrored:
            return kCGImagePropertyOrientationDownMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            return kCGImagePropertyOrientationLeftMirrored;
            break;
        case UIImageOrientationRight:
            return kCGImagePropertyOrientationRight;
            break;
        case UIImageOrientationRightMirrored:
            return kCGImagePropertyOrientationRightMirrored;
            break;
        case UIImageOrientationLeft:
            return kCGImagePropertyOrientationLeft;
            break;
        default:
            return kCGImagePropertyOrientationUp;
            break;
    }
}

- (UIImage*)_writeExifToPostProcessedImage:(UIImage*)image metadata:(NSDictionary*)metadata {
    if (!image) return image;
    if (!metadata || metadata.count == 0) return image;
    
    metadata = [self _editedMetadataDictionary:metadata ofImage:image];
    
    CFDictionaryRef exif = CFDictionaryGetValue((CFDictionaryRef)metadata, kCGImagePropertyExifDictionary);
    
    CFMutableDictionaryRef mutableExif = CFDictionaryCreateMutableCopy(NULL, 0, exif);
    CFDictionarySetValue(mutableExif, kCGImagePropertyExifPixelXDimension, (CFNumberRef)@(CGImageGetWidth(image.CGImage)));
    CFDictionarySetValue(mutableExif, kCGImagePropertyExifPixelYDimension, (CFNumberRef)@(CGImageGetHeight(image.CGImage)));
    
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    NSLog(@"1:%lu", (unsigned long)data.length);
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    CFDictionaryRef cfMetadata =  CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    
    CFMutableDictionaryRef mutableMetadata = CFDictionaryCreateMutableCopy(NULL, 0, cfMetadata);
    CFRelease(cfMetadata);
    
    CFDictionarySetValue(mutableMetadata, kCGImagePropertyExifDictionary, mutableExif);
    
    CFStringRef UTI = CGImageSourceGetType(source);
    NSMutableData *dataDest = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)dataDest, UTI, 1, NULL);
    
    CGImageDestinationAddImageFromSource(destination, source, 0, mutableMetadata);
    
    BOOL success = CGImageDestinationFinalize(destination);
    
    UIImage *imageDest = nil;
    if (success) {
        imageDest = [UIImage imageWithData:dataDest];
        NSLog(@"2:%lu", (unsigned long)dataDest.length);
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docDir = [paths objectAtIndex:0];
        [dataDest writeToFile:[NSString stringWithFormat:@"%@/ccccamera1.jpg", docDir] atomically:YES];
    }
    else {
        imageDest = image;
    }
    
    CFRelease(mutableExif);
    CFRelease(mutableMetadata);
    CFRelease(source);
    CFRelease(destination);
    
    return imageDest;
}

- (UIImageOrientation)_imageOrientationFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            if (_cameraSession.cameraMirrorType == CCCCameraVideoMirrorTypeYes) {
                return UIImageOrientationLeftMirrored;
            }
            else {
                return UIImageOrientationRight;
            }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            if (_cameraSession.cameraMirrorType == CCCCameraVideoMirrorTypeYes) {
                return UIImageOrientationRightMirrored;
            }
            else {
                return UIImageOrientationLeft;
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            if (_cameraSession.cameraMirrorType == CCCCameraVideoMirrorTypeYes) {
                if (_cameraSession.cameraDevice == CCCCameraDeviceFront) {
                    return UIImageOrientationUpMirrored;
                }
                else {
                    return UIImageOrientationDownMirrored;
                }
            }
            else {
                if (_cameraSession.cameraDevice == CCCCameraDeviceFront) {
                    return UIImageOrientationUp;
                }
                else {
                    return UIImageOrientationDown;
                }
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (_cameraSession.cameraMirrorType == CCCCameraVideoMirrorTypeYes) {
                if (_cameraSession.cameraDevice == CCCCameraDeviceFront) {
                    return UIImageOrientationDownMirrored;
                }
                else {
                    return UIImageOrientationUpMirrored;
                }
            }
            else {
                if (_cameraSession.cameraDevice == CCCCameraDeviceFront) {
                    return UIImageOrientationDown;
                }
                else {
                    return UIImageOrientationUp;
                }
            }
            break;
        default:
            return -1;
            break;
    }
}

#pragma mark -

+ (BOOL)isCameraAccess {
    return [CCCCameraSession isCameraAccess];
}

- (BOOL)isCameraRunning {
    return _cameraSession.isCameraRunning;
}

- (void)startCameraRunning {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
    
    [self.cameraSession startCameraRunning];
}

- (void)stopCameraRunning {
    [self.cameraSession stopCameraRunning];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.preview.cornersLayer.cornersArray = nil;
        [self _clearFocus];
    });
}

#pragma mark -

- (void)lockPictureOrientationWithOrientation:(UIInterfaceOrientation)orientation {
    _lockPictureOrientation = YES;
    _pictureOrientation = orientation;
}

- (void)unlockPictureOrientation {
    _lockPictureOrientation = NO;
    _pictureOrientation = UIInterfaceOrientationUnknown;
}

- (void)takePictureWithCompletionHandler:(void(^)(UIImage *picture, NSDictionary *pictureMetadata))handler {
    if (!self.isCameraRunning) {
        return;
    }
    
    UIInterfaceOrientation currentDeviceOrientation = _oldOrientation;
    
    [_cameraSession takePictureWithCompletionHandler:^(UIImage *picture, NSDictionary *pictureMetadata) {
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            
            UIImage *image = picture;
            
            if (_lockPictureOrientation) {
                UIImageOrientation imageOrientation = [self _imageOrientationFromInterfaceOrientation:_pictureOrientation];
                if (imageOrientation >= 0) {
                    image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:imageOrientation];
                }
            }
            
            switch (picture.imageOrientation) {
                case UIImageOrientationUp:
                    NSLog(@"%@", CCC2String(UIImageOrientationUp));
                    break;
                case UIImageOrientationDown:
                    NSLog(@"%@", CCC2String(UIImageOrientationDown));
                    break;
                case UIImageOrientationLeft:
                    NSLog(@"%@", CCC2String(UIImageOrientationLeft));
                    break;
                case UIImageOrientationRight:
                    NSLog(@"%@", CCC2String(UIImageOrientationRight));
                    break;
                case UIImageOrientationUpMirrored:
                    NSLog(@"%@", CCC2String(UIImageOrientationUpMirrored));
                    break;
                case UIImageOrientationDownMirrored:
                    NSLog(@"%@", CCC2String(UIImageOrientationDownMirrored));
                    break;
                case UIImageOrientationLeftMirrored:
                    NSLog(@"%@", CCC2String(UIImageOrientationLeftMirrored));
                    break;
                case UIImageOrientationRightMirrored:
                    NSLog(@"%@", CCC2String(UIImageOrientationRightMirrored));
                    break;
                default:
                    break;
            }
            
            image = [image ci_rotatedImageWithCorrectOrientation];
            
            if (_scaleType == CCCCameraPreviewScaleTypeScaleAspectFill) {
                CGRect cropLocation = CGRectMake(0, 0, image.size.width, image.size.height);
                CGSize sizeImage = image.size;
                CGSize sizeView = self.bounds.size;
                if (UIInterfaceOrientationIsLandscape(currentDeviceOrientation) && !_lockPictureOrientation) {
                    sizeView = CGSizeMake(sizeView.height, sizeView.width);
                }
                else if (UIInterfaceOrientationIsLandscape(_pictureOrientation) && _lockPictureOrientation) {
                    sizeView = CGSizeMake(sizeView.height, sizeView.width);
                }
                if (!CGSizeEqualToSize(sizeImage, CGSizeZero) && !CGSizeEqualToSize(sizeView, CGSizeZero)) {
                    CGFloat scale = sizeImage.width/sizeView.width;
                    if (scale*sizeView.height > sizeImage.height) {
                        scale = sizeImage.height/sizeView.height;
                    }
                    cropLocation.size.width = sizeView.width*scale;
                    cropLocation.size.height = sizeView.height*scale;
                    cropLocation.origin.x = (sizeImage.width-cropLocation.size.width)/2.0;
                    cropLocation.origin.y = (sizeImage.height-cropLocation.size.height)/2.0;
                }
                
                if (!CGSizeEqualToSize(cropLocation.size, sizeImage)) {
                    image = [image ci_croppedImageInRect:cropLocation];
                }
            }
            
            NSDictionary *dicMetadata = [self _editedMetadataDictionary:pictureMetadata ofImage:image];
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                
                if (handler)
                    handler(image, dicMetadata);
            });
        });
        
    }];
}

- (BOOL)isVideoRecording {
    return _cameraSession.isVideoRecording;
}

- (void)startVideoRecording {
    switch (_scaleType) {
        case CCCCameraPreviewScaleTypeScaleAspectFill:
            _cameraSession.videoSizeRatio = CGRectGetWidth(self.bounds)/CGRectGetHeight(self.bounds);
            break;
        case CCCCameraPreviewScaleTypeScaleAspectFit:
            _cameraSession.videoSizeRatio = 0.0f;
            break;
        default:
            break;
    }
    
    [_cameraSession startVideoRecording];
}

- (void)stopVideoRecording {
    [_cameraSession stopVideoRecording];
}

#pragma mark - Orientation

- (void)startOrientationObserver {
    [self orientationChanged:nil];
    
    _oldOrientation = UIInterfaceOrientationUnknown;
    if (self.motionManager.isAccelerometerAvailable) {
        [self.motionManager startAccelerometerUpdatesToQueue:self.motionQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            
            if (accelerometerData) {
                UIInterfaceOrientation newOrientation;
                if (accelerometerData.acceleration.x >= 0.5) {
                    newOrientation = UIInterfaceOrientationLandscapeLeft;
                }
                else if (accelerometerData.acceleration.x <= -0.5) {
                    newOrientation = UIInterfaceOrientationLandscapeRight;
                }
                else if (accelerometerData.acceleration.y <= -0.5) {
                    newOrientation = UIInterfaceOrientationPortrait;
                }
                else if (accelerometerData.acceleration.y >= 0.5) {
                    newOrientation = UIInterfaceOrientationPortraitUpsideDown;
                }
                else {
                    return;
                }
                
                if (newOrientation == _oldOrientation) {
                    return;
                }
                
                _oldOrientation = newOrientation;
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraView:orientationDidChanged:)]) {
                        [_delegate cccCameraView:self orientationDidChanged:newOrientation];
                    }
                });
                
                if (_cameraSession.session.isRunning) {
                    AVCaptureVideoOrientation videoOrientation = [self videoOrientationFromDeviceOrientation:(UIDeviceOrientation)newOrientation];
                    [self _changeVideoOrientationWithOrientation:videoOrientation];
                }
            }
            
        }];
        if (self.motionManager.isAccelerometerActive && self.motionManager.accelerometerData) {
        }
    }
}

- (void)stopOrientationObserver {
    if (self.motionManager.isAccelerometerAvailable && self.motionManager.isAccelerometerActive) {
        [self.motionManager stopAccelerometerUpdates];
        [self.motionQueue cancelAllOperations];
        self.motionQueue = nil;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _oldOrientation = UIInterfaceOrientationUnknown;
    });
}

- (void)orientationChanged:(NSNotification *)notification {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation videoOrientation = [self videoOrientationFromDeviceOrientation:orientation];
    
    [self _changeVideoOrientationWithOrientation:videoOrientation];
}

- (AVCaptureVideoOrientation)videoOrientationFromDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    
    return orientation;
}

- (void)_changeVideoOrientationWithOrientation:(AVCaptureVideoOrientation)videoOrientation {
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    
    [_cameraSession setCameraVideoOrientation:videoOrientation];
}

#pragma mark - Subject Changed

- (void)_startSubjectChangedObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_subjectMonitorChanged:)
                                                 name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                               object:nil];
}

- (void)_stopSubjectChangedObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                  object:nil];
}

- (void)_subjectMonitorChanged:(NSNotification *)notification {
    [self _cancelClearFocus];
    
    [self.focusAreaLayer focusAtSubjectChanged];
    
}

#pragma mark - Focus & Exposure Control

- (void)_clearFocus {
    [self _cancelClearFocus];
    
    [self.focusAreaLayer clearFocusPoint];
}

- (void)_cancelClearFocus {
    [NSObject cancelPreviousPerformRequestsWithTarget:self.focusAreaLayer selector:@selector(clearFocusPoint) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self.focusAreaLayer selector:@selector(fadeOutFocusArea) object:nil];
    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_fadeOutExposureComponents) object:nil];
}

- (void)_fadeOutExposure {
    [self.focusAreaLayer performSelector:@selector(fadeOutFocusArea) withObject:nil afterDelay:self.focusAreaLayer->_delay];
    
    [self performSelector:@selector(_fadeOutExposureComponents) withObject:nil afterDelay:self.focusAreaLayer->_delay];
}

- (void)_fadeOutExposureComponents {
    self.exposureBiasSlider.alpha = 0.3;
    
    float value = self.exposureBiasSlider.value;
    if (fabsf(value) < 0.1) {
        value =  0.0;
        self.exposureBiasSlider.value = value;
        [_cameraSession setCameraExposureBias:value];
        
        self.exposureBiasLabel.alpha = 0.0;
    }
    else {
        self.exposureBiasLabel.alpha = 0.3;
    }
    [self _configureExposureLabel:value];
    
}

- (void)_exposureSliderValueChanged:(UISlider *)sender {
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    if (!self.isCameraRunning) {
        return;
    }
    if (self.exposureControlMode != CCCCameraExposureControlModeSlider) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_fadeOutExposureComponents) object:nil];
    
    sender.alpha = 1.0;
    self.exposureBiasLabel.alpha = 1.0;
    
    float value = sender.value;
    if (fabsf(value) < 0.1) {
        value =  0.0;
        sender.value = value;
    }
    [_cameraSession setCameraExposureBias:value];
    
    [self _configureExposureLabel:value];
    
    [self performSelector:@selector(_fadeOutExposureComponents) withObject:nil afterDelay:self.focusAreaLayer->_delay];
}

- (void)_configureExposureLabel:(float)value {
    NSString *sign = (value<0? @"-": @"+");
    NSString *biasString = [NSString stringWithFormat:@"%.2f", fabsf(value)];
    if ([biasString isEqualToString:@"0.00"]) {
        sign = @"";
        
        UIColor *color = [UIColor whiteColor];
        self.exposureBiasLabel.textColor = color;
        self.exposureBiasSlider.minimumTrackTintColor = color;
        self.exposureBiasSlider.maximumTrackTintColor = color;
    }
    else {
        UIColor *color = [UIColor colorWithRed:1.000 green:0.800 blue:0.000 alpha:1.000];
        self.exposureBiasLabel.textColor = color;
        self.exposureBiasSlider.minimumTrackTintColor = color;
        self.exposureBiasSlider.maximumTrackTintColor = color;
    }
    biasString = [NSString stringWithFormat:@"%@%@", sign, biasString];
    self.exposureBiasLabel.text = biasString;
    
    NSString *text = self.exposureBiasLabel.text;
    UIFont *font = self.exposureBiasLabel.font;
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle];
    NSDictionary *attribute = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paragraphStyle};
    CGSize sizeOfText = [text sizeWithAttributes:attribute];
    
    CGRect labelFrame = self.exposureBiasLabel.frame;
    labelFrame.size = sizeOfText;
    labelFrame.origin.x = CGRectGetMinX(self.exposureBiasSlider.frame)-sizeOfText.width;
    
    float scale = self.exposureBiasSlider.value*2/(self.exposureBiasSlider.maximumValue-self.exposureBiasSlider.minimumValue);
    labelFrame.origin.y = CGRectGetHeight(self.bounds)/2.0
                            - scale*(CGRectGetHeight(self.bounds)*0.4 - 15)
                            - sizeOfText.height/2.0;
    self.exposureBiasLabel.frame = labelFrame;
    
}

#pragma mark - Tap Gesture

- (void)_tapGesture:(UITapGestureRecognizer*)gestureRecognizer {
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    
    // real location in self
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    // location in preview
    CGPoint pointInPreview = [gestureRecognizer locationInView:self.preview];
    // convert to unit location in previewlayer {{0, 0}, {1, 1}}
    CGPoint transformedPoint = [self.previewLayer captureDevicePointOfInterestForPoint:pointInPreview];
    
    // did touch in preview
    if (CGRectContainsPoint(CGRectMake(0, 0, 1, 1), transformedPoint)) {
        [self _cancelClearFocus];
        
        [_cameraSession setCameraFocusPoint:transformedPoint];
        
        self.focusAreaLayer.focusPoint = touchPoint;
    }
    
}

#pragma mark - Pinch Gesture

- (void)_pinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer {
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    
    CGFloat scale = [_cameraSession zoomWithPinchGesture:gestureRecognizer];
    
    self.preview.layer.affineTransform = CGAffineTransformMakeScale(scale, scale);
}

#pragma mark - Pan Gesture

- (void)_panGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    if (!self.focusAreaLayer.isExposureBiasAdjustable) {
        return;
    }
    if (self.exposureControlMode != CCCCameraExposureControlModeSystem) {
        return;
    }
    
    [self _cancelClearFocus];
    
    CGPoint offset = gestureRecognizer.view.bounds.origin;
    offset.x -= [gestureRecognizer translationInView:gestureRecognizer.view].x;
    offset.y -= [gestureRecognizer translationInView:gestureRecognizer.view].y;
    
    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    if (!CGRectContainsPoint(self.bounds, location)) {
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float min = _cameraSession.minExposureBias;
            float max = _cameraSession.maxExposureBias;
            float scale = (max-min)/0.03;
            
            float bias = _cameraSession.currentExposureBias + offset.y/scale;
            [_cameraSession setCameraExposureBias:bias];
            
            bias = _cameraSession.currentExposureBias;
            
            [self.focusAreaLayer setExposureBias:bias min:min max:max];
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            
            [self _fadeOutExposure];
            
            break;
        }
        default:
            break;
    }
    [gestureRecognizer setTranslation:CGPointZero inView:gestureRecognizer.view];
    
}

#pragma mark - CCCCameraSessionDelegate

- (void)cccCameraSessionDidStart:(CCCCameraSession*)cameraSession {
    [self startOrientationObserver];
    if (_oldOrientation != UIInterfaceOrientationUnknown) {
        AVCaptureVideoOrientation videoOrientation = [self videoOrientationFromDeviceOrientation:(UIDeviceOrientation)_oldOrientation];
        [self _changeVideoOrientationWithOrientation:videoOrientation];
    }
    [self _startSubjectChangedObserver];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        self.exposureBiasSlider.minimumValue = cameraSession.minExposureBias;
        self.exposureBiasSlider.maximumValue = cameraSession.maxExposureBias;
        self.exposureBiasSlider.value = cameraSession.currentExposureBias;
        
        [self _configureExposureLabel:self.exposureBiasSlider.value];
    }
    [self _subjectMonitorChanged:nil];
    
    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraViewCameraDidStart:)]) {
        [_delegate cccCameraViewCameraDidStart:self];
    }
}

- (void)cccCameraSessionDidStop:(CCCCameraSession *)cameraSession {
    [self stopOrientationObserver];
    [self _stopSubjectChangedObserver];
    
    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraViewCameraDidStop:)]) {
        [_delegate cccCameraViewCameraDidStop:self];
    }
}

- (void)cccCameraSession:(CCCCameraSession*)cameraSession didReceiveRuntimeError:(NSError*)error {
    
}

- (void)cccCameraSessionDidStartVideoRecording:(CCCCameraSession*)cameraSession {
    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraViewDidStartVideoRecording:)]) {
        [_delegate cccCameraViewDidStartVideoRecording:self];
    }
}

- (void)cccCameraSession:(CCCCameraSession *)cameraSession didFinishVideoRecordingToFile:(NSURL*)fileURL error:(NSError*)error {
    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraView:didFinishVideoRecordingToFile:error:)]) {
        [_delegate cccCameraView:self didFinishVideoRecordingToFile:fileURL error:error];
    }
}

- (void)cccCameraSession:(CCCCameraSession*)cameraSession shouldUpdateCorners:(NSArray*)cornersArray {
    self.preview.cornersLayer.cornersArray = cornersArray;
}

- (void)cccCameraSession:(CCCCameraSession*)cameraSession didDetectBarcodes:(NSSet<CCCCameraBarcodeData*>*)barcodeSet {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        if (_delegate && [_delegate respondsToSelector:@selector(cccCameraView:didScanBarcodeWithArray:)]) {
            [_delegate cccCameraView:self didScanBarcodeWithArray:barcodeSet];
        }
    }
}

#pragma mark - Static

+ (NSUInteger)numberOfCameraDevice {
    return [CCCCameraSession numberOfCameraDevice];
}

+ (BOOL)isCameraDeviceAvailable:(CCCCameraDevice)cameraDevice {
    return [CCCCameraSession isCameraDeviceAvailable:cameraDevice];
}

+ (BOOL)isFlashAvailableForCameraDevice:(CCCCameraDevice)cameraDevice {
    return [CCCCameraSession isFlashAvailableForCameraDevice:cameraDevice];
}

+ (UIImage*)previewImageForVideo:(NSURL*)videoURL atTime:(NSTimeInterval)time {
    return [CCCCameraSession previewImageForVideo:videoURL atTime:time];
}

+ (void)convertVideoToMPEG4Format:(NSURL*)srcUrl destinationPath:(NSString*)path completionHandler:(void(^)(BOOL successful, NSError *error))handler {
    [CCCCameraSession convertVideoToMPEG4Format:srcUrl destinationPath:path completionHandler:handler];
}

@end
