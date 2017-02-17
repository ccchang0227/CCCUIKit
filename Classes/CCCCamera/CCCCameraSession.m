//
//  CCCCameraSession.m
//
//  Created by CHIEN-HSU WU on 2015/8/17.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCameraSession.h"


#define kCCCCameraDefaultMaximumZoomScale   3.0
#define kCCCCameraDefaultVideoFileName      @"movie.mp4"

@interface CCCCameraSession () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    
    CGFloat _currentZoomScale;
    CGFloat _maximumZoomScale;
    
    dispatch_queue_t _metaOutputQueue;
    
    BOOL _isVideoRecording;
    CMTime _videoStartTime;
    
    NSError *_videoRecordError;
    
    dispatch_queue_t _cameraSessionQueue;
    
    /// 用來記錄是否是由使用者呼叫停止相機的
    BOOL _runCamera;
}

@property (assign, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (retain, nonatomic) AVCaptureDeviceInput *videoInput;
@property (retain, nonatomic) AVCaptureDeviceInput *audioInput;

@property (retain, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (retain, nonatomic) AVCaptureAudioDataOutput *audioDataOutput;
@property (retain, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (retain, nonatomic) AVCaptureMetadataOutput *metadataOutput;

@property (retain, nonatomic) AVAssetWriterInput *videoWriterInput;
@property (retain, nonatomic) AVAssetWriterInput *audioWriterInput;
@property (retain, nonatomic) AVAssetWriter *videoFileWriter;

@end

@interface CCCCameraBarcodeData ()

+ (instancetype)barcodeDataWithReadableCodeObject:(AVMetadataMachineReadableCodeObject*)readableCodeObject;
- (instancetype)initWithReadableCodeObject:(AVMetadataMachineReadableCodeObject*)readableCodeObject;

@end

@implementation CCCCameraSession
@synthesize videoQuality = _videoQuality;
@synthesize cameraCaptureMode = _cameraCaptureMode;
@synthesize cameraDevice = _cameraDevice;
@synthesize cameraFlashMode = _cameraFlashMode;
@synthesize cameraMirrorType = _cameraMirrorType;
@synthesize faceDetectEnabled = _faceDetectEnabled;
@synthesize barcodeScanEnabled = _barcodeScanEnabled;
@synthesize cameraRunning = _cameraRunning;
@synthesize recordedVideoDuration = _recordedVideoDuration;
@synthesize maxVideoDuration = _maxVideoDuration;
@synthesize muteVideo = _muteVideo;
@synthesize videoRecording = _videoRecording;

- (instancetype)initWithVideoPreviewLayer:(AVCaptureVideoPreviewLayer*)previewLayer {
    self = [super init];
    if (self) {
        [self _setup];
        
        self.previewLayer = previewLayer;
        self.previewLayer.session = _session;
    }
    return self;
}

- (instancetype)init {
    self = [self initWithVideoPreviewLayer:nil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    if (_videoFileWriter && _videoFileWriter.status == AVAssetWriterStatusWriting) {
        [_videoWriterInput markAsFinished];
        [_audioWriterInput markAsFinished];
        [_videoFileWriter finishWritingWithCompletionHandler:^ {
            [self _removeVideoRecordingFile];
        }];
    }
    else {
        [self _removeVideoRecordingFile];
    }
    
    if (_session.isRunning)
        [_session stopRunning];
    if (_videoInput) {
        if ([_session.inputs containsObject:_videoInput])
            [_session removeInput:_videoInput];
    }
    if (_audioInput) {
        if ([_session.inputs containsObject:_audioInput])
            [_session removeInput:_audioInput];
    }
    if (_videoDataOutput) {
        if ([_session.outputs containsObject:_videoDataOutput]) {
            [_session removeOutput:_videoDataOutput];
        }
        _videoDataOutput.videoSettings = nil;
        [_videoDataOutput setSampleBufferDelegate:nil queue:NULL];
    }
    if (_audioDataOutput) {
        if ([_session.outputs containsObject:_audioDataOutput]) {
            [_session removeOutput:_audioDataOutput];
        }
        [_audioDataOutput setSampleBufferDelegate:nil queue:NULL];
    }
    if (_stillImageOutput) {
        if ([_session.outputs containsObject:_stillImageOutput]) {
            [_session removeOutput:_stillImageOutput];
        }
        _stillImageOutput.outputSettings = nil;
    }
    if (_metadataOutput) {
        if ([_session.outputs containsObject:_metadataOutput]) {
            [_session removeOutput:_metadataOutput];
        }
        [_metadataOutput setMetadataObjectsDelegate:nil queue:NULL];
    }
    
#if !__has_feature(objc_arc)
    if (_videoRecordError) {
        [_videoRecordError release];
    }
    [_session release];
    [_videoInput release];
    [_audioInput release];
    [_videoDataOutput release];
    [_audioDataOutput release];
    [_stillImageOutput release];
    [_metadataOutput release];
    [_videoWriterInput release];
    [_audioWriterInput release];
    [_videoFileWriter release];
    dispatch_release(_metaOutputQueue);
    dispatch_release(_cameraSessionQueue);
    [super dealloc];
#endif
    
}

#pragma mark - Getter

- (AVCaptureDeviceInput*)audioInput {
    if (_audioInput == nil) {
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (error) {
            NSLog(@"get input failed:%@", error);
        }
        else {
            _audioInput = [input retain];
        }
    }
    
    return _audioInput;
}


- (AVCaptureVideoDataOutput*)videoDataOutput {
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        if (!_metaOutputQueue) {
            _metaOutputQueue = dispatch_queue_create("CCCCameraMetadataOutputQueue", DISPATCH_QUEUE_SERIAL);
        }
        [_videoDataOutput setSampleBufferDelegate:self queue:_metaOutputQueue];
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    }
    
    return _videoDataOutput;
}

- (AVCaptureAudioDataOutput*)audioDataOutput {
    if (_audioDataOutput == nil) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        if (!_metaOutputQueue) {
            _metaOutputQueue = dispatch_queue_create("CCCCameraMetadataOutputQueue", DISPATCH_QUEUE_SERIAL);
        }
        [_audioDataOutput setSampleBufferDelegate:self queue:_metaOutputQueue];
    }
    
    return _audioDataOutput;
}

- (AVCaptureStillImageOutput*)stillImageOutput {
    if (_stillImageOutput == nil) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        
        // -- set output settings begin
        NSMutableDictionary *outputSettings = [NSMutableDictionary dictionaryWithCapacity:0];
        if ([_stillImageOutput.availableImageDataCodecTypes containsObject:AVVideoCodecJPEG]) {
            [outputSettings setObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
            [outputSettings setObject:@1.0 forKey:AVVideoQualityKey];
        }
        /*
        if ([_stillImageOutput.availableImageDataCVPixelFormatTypes containsObject:@(kCVPixelFormatType_32BGRA)]) {
            [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        }
        else if ([_stillImageOutput.availableImageDataCVPixelFormatTypes containsObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]) {
            [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        }
        //*/
        if (outputSettings.count > 0) {
            _stillImageOutput.outputSettings = outputSettings;
        }
        // -- set output settings end
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            if (_stillImageOutput.isStillImageStabilizationSupported) {
                _stillImageOutput.automaticallyEnablesStillImageStabilizationWhenAvailable = YES;
            }
        }
    }
    
    return _stillImageOutput;
}

- (AVCaptureMetadataOutput*)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        if (!_metaOutputQueue) {
            _metaOutputQueue = dispatch_queue_create("CCCCameraMetadataOutputQueue", DISPATCH_QUEUE_SERIAL);
        }
        [_metadataOutput setMetadataObjectsDelegate:self queue:_metaOutputQueue];
    }
    
    return _metadataOutput;
}

- (CCCCameraVideoQuality)videoQuality {
    NSString *sessionPreset = _session.sessionPreset;
    NSDictionary *videoQualityMap = @{@(CCCCameraVideoQualityPhoto):AVCaptureSessionPresetPhoto,
                                      @(CCCCameraVideoQualityHigh):AVCaptureSessionPresetHigh,
                                      @(CCCCameraVideoQualityMedium):AVCaptureSessionPresetMedium,
                                      @(CCCCameraVideoQualityLow):AVCaptureSessionPresetLow,
                                      @(CCCCameraVideoQuality352x288):AVCaptureSessionPreset352x288,
                                      @(CCCCameraVideoQuality640x480):AVCaptureSessionPreset640x480,
                                      @(CCCCameraVideoQuality960x540):AVCaptureSessionPresetiFrame960x540,
                                      @(CCCCameraVideoQuality1280x720):AVCaptureSessionPresetiFrame1280x720,
                                      @(CCCCameraVideoQuality1920x1080):AVCaptureSessionPreset1920x1080};
    
    NSArray *allKeys = [videoQualityMap allKeysForObject:sessionPreset];
    if (allKeys.count > 0) {
        return [[allKeys objectAtIndex:0] integerValue];
    }
    
    return _videoQuality;
}

#pragma mark - Setter

- (void)setVideoQuality:(CCCCameraVideoQuality)videoQuality {
    if (_isVideoRecording || _stillImageOutput.isCapturingStillImage) return;
    
    __block CCCCameraVideoQuality correctQuality = videoQuality;
    NSDictionary *videoQualityMap = @{@(CCCCameraVideoQualityPhoto):AVCaptureSessionPresetPhoto,
                                      @(CCCCameraVideoQualityHigh):AVCaptureSessionPresetHigh,
                                      @(CCCCameraVideoQualityMedium):AVCaptureSessionPresetMedium,
                                      @(CCCCameraVideoQualityLow):AVCaptureSessionPresetLow,
                                      @(CCCCameraVideoQuality352x288):AVCaptureSessionPreset352x288,
                                      @(CCCCameraVideoQuality640x480):AVCaptureSessionPreset640x480,
                                      @(CCCCameraVideoQuality960x540):AVCaptureSessionPresetiFrame960x540,
                                      @(CCCCameraVideoQuality1280x720):AVCaptureSessionPresetiFrame1280x720,
                                      @(CCCCameraVideoQuality1920x1080):AVCaptureSessionPreset1920x1080};
    
    __block NSString *sessionPreset = [videoQualityMap objectForKey:@(correctQuality)];
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto] && _cameraCaptureMode == CCCCameraCaptureModeVideo) {
            sessionPreset = [videoQualityMap objectForKey:@(CCCCameraVideoQualityMedium)];
        }
        
        if (_videoInput) {
            if ([_session canSetSessionPreset:sessionPreset] && [_videoInput.device supportsAVCaptureSessionPreset:sessionPreset]) {
                _session.sessionPreset = sessionPreset;
            }
            else {
                correctQuality = CCCCameraVideoQualityMedium;
                sessionPreset = [videoQualityMap objectForKey:@(correctQuality)];
                if ([_session canSetSessionPreset:sessionPreset] && [_videoInput.device supportsAVCaptureSessionPreset:sessionPreset]) {
                    _session.sessionPreset = sessionPreset;
                }
                else {
                    correctQuality = CCCCameraVideoQualityHigh;
                    sessionPreset = [videoQualityMap objectForKey:@(correctQuality)];
                    if ([_session canSetSessionPreset:sessionPreset] && [_videoInput.device supportsAVCaptureSessionPreset:sessionPreset]) {
                        _session.sessionPreset = sessionPreset;
                    }
                }
            }
        }
        else {
            if ([_session canSetSessionPreset:sessionPreset]) {
                _session.sessionPreset = sessionPreset;
            }
            else {
                correctQuality = CCCCameraVideoQualityMedium;
                sessionPreset = [videoQualityMap objectForKey:@(correctQuality)];
                if ([_session canSetSessionPreset:sessionPreset]) {
                    _session.sessionPreset = sessionPreset;
                }
                else {
                    correctQuality = CCCCameraVideoQualityHigh;
                    sessionPreset = [videoQualityMap objectForKey:@(correctQuality)];
                    if ([_session canSetSessionPreset:sessionPreset]) {
                        _session.sessionPreset = sessionPreset;
                    }
                }
            }
        }
    }];
    
    _videoQuality = correctQuality;
}

- (void)setCameraCaptureMode:(CCCCameraCaptureMode)cameraCaptureMode {
    if (_cameraCaptureMode != cameraCaptureMode && (!_isVideoRecording && !_stillImageOutput.isCapturingStillImage)) {
        _cameraCaptureMode = cameraCaptureMode;
        
        if (self.isCameraRunning) {
            [self _setupCameraCaptureMode];
        }
    }
}

- (void)setCameraDevice:(CCCCameraDevice)cameraDevice {
    if (_cameraDevice != cameraDevice && (!_isVideoRecording && !_stillImageOutput.isCapturingStillImage)) {
        _cameraDevice = cameraDevice;
        
        if (self.isCameraRunning) {
            [self _setupCameraDevice];
        }
    }
}

- (void)setCameraFlashMode:(CCCCameraFlashMode)cameraFlashMode {
    if (_cameraFlashMode != cameraFlashMode) {
        _cameraFlashMode = cameraFlashMode;
        
        if (self.isCameraRunning) {
            [self _setupCameraFlashMode];
        }
    }
}

- (void)setCameraMirrorType:(CCCCameraVideoMirrorType)cameraMirrorType {
    if (_cameraMirrorType != cameraMirrorType && (!_isVideoRecording && !_stillImageOutput.isCapturingStillImage)) {
        _cameraMirrorType = cameraMirrorType;
        
        if (self.isCameraRunning) {
            [self _setupCameraMirrorType];
        }
    }
}

- (void)setMaxVideoDuration:(NSTimeInterval)maxVideoDuration {
    if (_isVideoRecording || _stillImageOutput.isCapturingStillImage) return;
    
    _maxVideoDuration = maxVideoDuration;
    
    [self _setupMaxVideoRecordingDuration];
}

#pragma mark -

//  in order to change session's configuration
- (void)_onSessionConfigurationChanged:(void(^)(void))block {
    if (_session.isRunning) {
        [_session beginConfiguration];
        if (block)
            block();
        [_session commitConfiguration];
    }
    else {
        if (block)
            block();
    }
}

// in order to change device's configuration
- (void)_captureDevice:(AVCaptureDevice*)captureDevice onConfigurationChanged:(void(^)(void))block {
    if (!captureDevice) return;
    
    NSError *error  = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        if (block)
            block();
        [captureDevice unlockForConfiguration];
    }
    else {
        NSLog(@"lock device failed: %@", error);
    }
}

- (void)_setup {
    _session = [[AVCaptureSession alloc] init];
    
    _cameraSessionQueue = dispatch_queue_create("CCCCameraSessionQueue", DISPATCH_QUEUE_SERIAL);
    
    _videoQuality = CCCCameraVideoQualityMedium;
    _cameraCaptureMode = CCCCameraCaptureModePhoto;
    _cameraDevice = CCCCameraDeviceRear;
    _cameraFlashMode = CCCCameraFlashModeAuto;
    _cameraMirrorType = CCCCameraVideoMirrorTypeNo;
    
    _faceDetectEnabled = YES;
    _barcodeScanEnabled = YES;
    
    _currentPreviewSize = CGSizeZero;
    
    _videoInput = nil;
    
    _maxVideoDuration = 10*60; // 10 minutes.
    _muteVideo = NO;
    
    _runCamera = NO;
    
    [self _removeVideoRecordingFile];
}

- (BOOL)_setupCameraDevice {
    NSDictionary *cameraDeviceMap = @{@(CCCCameraDeviceFront):@(AVCaptureDevicePositionFront),
                                      @(CCCCameraDeviceRear):@(AVCaptureDevicePositionBack)};
    
    AVCaptureDevicePosition position = [[cameraDeviceMap objectForKey:@(_cameraDevice)] integerValue];
    if (_videoInput && [_session.inputs containsObject:_videoInput]) {
        AVCaptureDevice *currentCaptureDevice = _videoInput.device;
        if (currentCaptureDevice.position == position) {
            return NO;
        }
    }
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"get input failed:%@", error);
        return NO;
    }
    
    [self _setupVideoQuality:_videoQuality forCaptureDevice:captureDevice];
    
    _currentZoomScale = 1.0f;
    
    __block BOOL addInputSuccess = NO;
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        
        if (_videoInput) {
            if ([_session.inputs containsObject:_videoInput])
                [_session removeInput:_videoInput];
            [_videoInput release];
            _videoInput = nil;
        }
        if (![_session canAddInput:input]) {
            NSLog(@"failed to add input:%@", captureDevice.localizedName);
            return;
        }
        [_session addInput:input];
        _videoInput = [input retain];
        
        addInputSuccess = YES;
        
        [tempSelf _captureDevice:captureDevice onConfigurationChanged:^ {
            if (captureDevice.isLowLightBoostSupported) {
                captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            }
            captureDevice.subjectAreaChangeMonitoringEnabled = YES;
            
            [tempSelf _captureDevice:captureDevice focusAtPoint:CGPointMake(0.5, 0.5)];
        }];
    }];
    
    [self _setupCameraFlashMode];
    [self _estimateMaximumZoomScale];
    [self _setupCameraMirrorType];
    
    return addInputSuccess;
}

- (void)_setupVideoQuality:(CCCCameraVideoQuality)videoQuality forCaptureDevice:(AVCaptureDevice*)captureDevice {
    if (!captureDevice) return;
    
    NSDictionary *videoQualityMap = @{@(CCCCameraVideoQualityPhoto):AVCaptureSessionPresetPhoto,
                                      @(CCCCameraVideoQualityHigh):AVCaptureSessionPresetHigh,
                                      @(CCCCameraVideoQualityMedium):AVCaptureSessionPresetMedium,
                                      @(CCCCameraVideoQualityLow):AVCaptureSessionPresetLow,
                                      @(CCCCameraVideoQuality352x288):AVCaptureSessionPreset352x288,
                                      @(CCCCameraVideoQuality640x480):AVCaptureSessionPreset640x480,
                                      @(CCCCameraVideoQuality960x540):AVCaptureSessionPresetiFrame960x540,
                                      @(CCCCameraVideoQuality1280x720):AVCaptureSessionPresetiFrame1280x720,
                                      @(CCCCameraVideoQuality1920x1080):AVCaptureSessionPreset1920x1080};
    
    __block NSString *sessionPreset = [videoQualityMap objectForKey:@(videoQuality)];
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        if ([sessionPreset isEqualToString:AVCaptureSessionPresetPhoto] && _cameraCaptureMode == CCCCameraCaptureModeVideo) {
            sessionPreset = [videoQualityMap objectForKey:@(CCCCameraVideoQualityMedium)];
        }
        
        if ([_session canSetSessionPreset:sessionPreset] && [captureDevice supportsAVCaptureSessionPreset:sessionPreset]) {
            _session.sessionPreset = sessionPreset;
            _videoQuality = videoQuality;
        }
        else {
            sessionPreset = [videoQualityMap objectForKey:@(CCCCameraVideoQualityMedium)];
            if ([_session canSetSessionPreset:sessionPreset] && [captureDevice supportsAVCaptureSessionPreset:sessionPreset]) {
                _session.sessionPreset = sessionPreset;
                _videoQuality = CCCCameraVideoQualityMedium;
            }
            else {
                sessionPreset = [videoQualityMap objectForKey:@(CCCCameraVideoQualityHigh)];
                if ([_session canSetSessionPreset:sessionPreset] && [captureDevice supportsAVCaptureSessionPreset:sessionPreset]) {
                    _session.sessionPreset = sessionPreset;
                    _videoQuality = CCCCameraVideoQualityHigh;
                }
            }
        }
    }];
    
    [self _resetPreviewSize];
}

- (void)_setupCameraFlashMode {
    if (_videoInput == nil) {
        [self _setupCameraDevice];
        return;
    }
    
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        AVCaptureDevice *captureDevice = _videoInput.device;
        if (captureDevice.hasFlash || captureDevice.hasTorch) {
            [tempSelf _captureDevice:captureDevice onConfigurationChanged:^ {
                
                switch (_cameraFlashMode) {
                    case CCCCameraFlashModeOff: {
                        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                            captureDevice.flashMode = AVCaptureFlashModeOff;
                        }
                        if ([captureDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
                            captureDevice.torchMode = AVCaptureTorchModeOff;
                        }
                        break;
                    }
                    case CCCCameraFlashModeAuto: {
                        if (_cameraCaptureMode == CCCCameraCaptureModePhoto) {
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
                                captureDevice.flashMode = AVCaptureFlashModeAuto;
                            }
                            if ([captureDevice isTorchModeSupported:AVCaptureTorchModeAuto]) {
                                captureDevice.torchMode = AVCaptureTorchModeAuto;
                            }
                        }
                        else if (_cameraCaptureMode == CCCCameraCaptureModeVideo) {
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
                                captureDevice.flashMode = AVCaptureFlashModeAuto;
                            }
                            if ([captureDevice isTorchModeSupported:AVCaptureTorchModeAuto]) {
                                captureDevice.torchMode = AVCaptureTorchModeAuto;
                            }
                        }
                        break;
                    }
                    case CCCCameraFlashModeOn: {
                        if (_cameraCaptureMode == CCCCameraCaptureModePhoto) {
                            if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOn]) {
                                captureDevice.flashMode = AVCaptureFlashModeOn;
                            }
                            if ([captureDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
                                captureDevice.torchMode = AVCaptureTorchModeOff;
                            }
                        }
                        else if (_cameraCaptureMode == CCCCameraCaptureModeVideo) {
                            if ([captureDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
                                captureDevice.torchMode = AVCaptureTorchModeOff;
                            }
                            if ([captureDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
                                captureDevice.torchMode = AVCaptureTorchModeOn;
                                [captureDevice setTorchModeOnWithLevel:1.0f error:nil];
                            }
                        }
                        break;
                    }
                    case CCCCameraFlashModeTorch: {
                        if ([captureDevice isFlashModeSupported:AVCaptureFlashModeOff]) {
                            captureDevice.flashMode = AVCaptureFlashModeOff;
                        }
                        if ([captureDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
                            captureDevice.torchMode = AVCaptureTorchModeOn;
                            [captureDevice setTorchModeOnWithLevel:1.0f error:nil];
                        }
                        break;
                    }
                    default:
                        break;
                }
                
            }];
        }
    }];
    
}

- (void)_setupCameraCaptureMode {
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        if (tempSelf.audioInput) {
            if ([_session.inputs containsObject:tempSelf.audioInput] && _cameraCaptureMode == CCCCameraCaptureModePhoto) {
                [_session removeInput:tempSelf.audioInput];
            }
            else if (![_session.inputs containsObject:tempSelf.audioInput] && _cameraCaptureMode == CCCCameraCaptureModeVideo && [_session canAddInput:tempSelf.audioInput]) {
                [_session addInput:tempSelf.audioInput];
            }
        }
    }];
    
    [self _setupVideoQuality:_videoQuality forCaptureDevice:_videoInput.device];
    [self _setupCameraFlashMode];
    [self _estimateMaximumZoomScale];
    
    if (_cameraCaptureMode == CCCCameraCaptureModeVideo) {
        [self _setupMaxVideoRecordingDuration];
    }
}

- (void)_setupCameraMirrorType {
    if (/* DISABLES CODE */ (YES)) {
        return;
    }
    // 直接設定之後出來的照片顏色不正常
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        AVCaptureConnection *imageConnection = [tempSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureConnection *movieConnection = [tempSelf.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        switch (_cameraMirrorType) {
            case CCCCameraVideoMirrorTypeNo: {
                if (imageConnection.isVideoMirroringSupported) {
                    imageConnection.automaticallyAdjustsVideoMirroring = NO;
                    imageConnection.videoMirrored = NO;
                }
                if (movieConnection.isVideoMirroringSupported) {
                    movieConnection.automaticallyAdjustsVideoMirroring = NO;
                    movieConnection.videoMirrored = NO;
                }
                break;
            }
            case CCCCameraVideoMirrorTypeYes: {
                if (imageConnection.isVideoMirroringSupported) {
                    imageConnection.automaticallyAdjustsVideoMirroring = NO;
                    imageConnection.videoMirrored = YES;
                }
                if (movieConnection.isVideoMirroringSupported) {
                    movieConnection.automaticallyAdjustsVideoMirroring = NO;
                    movieConnection.videoMirrored = YES;
                }
                break;
            }
            default:
                break;
        }
    }];
}

- (UIImageOrientation)_convertedImageOrientationWithMirroredTypeAndOriginal:(UIImageOrientation)originalOrientation {
    
    if (_cameraMirrorType == CCCCameraVideoMirrorTypeNo) {
        return originalOrientation;
    }
    
    switch (originalOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored: {
            return UIImageOrientationUpMirrored;
        }
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored: {
            return UIImageOrientationDownMirrored;
        }
        case UIImageOrientationLeft:
        case UIImageOrientationRightMirrored: {
            return UIImageOrientationRightMirrored;
        }
        case UIImageOrientationRight:
        case UIImageOrientationLeftMirrored: {
            return UIImageOrientationLeftMirrored;
        }
        default:
            break;
    }
    
    return originalOrientation;
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

- (void)_setupMaxVideoRecordingDuration {
}

- (void)_resetPreviewSize {
    _currentPreviewSize = CGSizeZero;
}

- (BOOL)_initVideoWriter {
    __block typeof(self) tempSelf = self;
    __block AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    [tempSelf _onSessionConfigurationChanged:^ {
        AVCaptureConnection *connection = [tempSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            videoOrientation = connection.videoOrientation;
        }
        
        connection = [tempSelf.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = videoOrientation;
        }
        
    }];
    
    usleep(10000);
    
    CGSize size = _currentPreviewSize;
    if (_videoSizeRatio > 0.0f && !isnan(_videoSizeRatio)) {
        CGFloat width = size.height*_videoSizeRatio;
        CGFloat height = size.width/_videoSizeRatio;
        if (width > size.width) {
            size.height = height;
        }
        else {
            size.width = width;
        }
    }
    if (_videoQuality <= CCCCameraVideoQualityLow) {
//        size = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(2.0, 2.0));
    }
    if ((int)size.width%2 != 0) size.width += 1;
    if ((int)size.height%2 != 0) size.height += 1;
    
    NSString *betaCompressionDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:kCCCCameraDefaultVideoFileName];
    NSError *error = nil;
    
    unlink([betaCompressionDirectory UTF8String]);
    [self _removeVideoRecordingFile];
    
    // ----initialize compression engine----
    
    [self _deinitVideoWriter];
    
    _videoFileWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory] fileType:AVFileTypeMPEG4 error:&error];
    if (error && !_videoFileWriter) {
        return NO;
    }
    
    // Add the video input
    NSMutableDictionary *videoCleanApertureProps = [NSMutableDictionary dictionaryWithDictionary:@{AVVideoCleanApertureWidthKey:@(size.width), AVVideoCleanApertureHeightKey:@(size.height), AVVideoCleanApertureHorizontalOffsetKey:@0, AVVideoCleanApertureVerticalOffsetKey:@0}];
//    NSDictionary *videoRatioProps = @{AVVideoPixelAspectRatioHorizontalSpacingKey : @3,
//                                      AVVideoPixelAspectRatioVerticalSpacingKey : @3};
    
    NSString *scalingMode = AVVideoScalingModeResizeAspectFill;
    if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect])
        scalingMode = AVVideoScalingModeResizeAspect;
    else if ([_previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        scalingMode = AVVideoScalingModeResize;
    }
    
    NSDictionary *videoCompressionProps = @{AVVideoAverageBitRateKey : @(960.0*1024.0)};
    NSDictionary *videoOutputSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                          AVVideoWidthKey : @(size.width),
                                          AVVideoHeightKey : @(size.height),
                                          AVVideoScalingModeKey : scalingMode,
                                          AVVideoCompressionPropertiesKey : videoCompressionProps,
                                          AVVideoCleanApertureKey : videoCleanApertureProps};
//    if (_videoQuality <= CCCCameraVideoQualityLow) {
//        videoOutputSettings = @{AVVideoCodecKey : AVVideoCodecH264,
//                                AVVideoWidthKey : @(size.width),
//                                AVVideoHeightKey : @(size.height),
//                                AVVideoScalingModeKey : scalingMode,
//                                AVVideoCompressionPropertiesKey : videoCompressionProps,
//                                AVVideoCleanApertureKey : videoCleanApertureProps,
//                                AVVideoPixelAspectRatioKey : videoRatioProps};
//    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        NSMutableDictionary *recommendedVideoSetting = [NSMutableDictionary dictionaryWithDictionary:[_videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4]];
        if (recommendedVideoSetting.count > 0) {
            [recommendedVideoSetting setObject:@(size.width) forKey:AVVideoWidthKey];
            [recommendedVideoSetting setObject:@(size.height) forKey:AVVideoHeightKey];
            [recommendedVideoSetting setObject:scalingMode forKey:AVVideoScalingModeKey];
            [recommendedVideoSetting setObject:videoCleanApertureProps forKey:AVVideoCleanApertureKey];
//            if (_videoQuality <= CCCCameraVideoQualityLow) {
//                [recommendedVideoSetting setObject:videoRatioProps forKey:AVVideoPixelAspectRatioKey];
//            }
            videoOutputSettings = recommendedVideoSetting;
        }
        
    }
    
    NSLog(@"videoSettings = %@", videoOutputSettings);
    
    _videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
    if (!_videoWriterInput) {
        [self _deinitVideoWriter];
        return NO;
    }
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    
//    switch (videoOrientation) {
//        case AVCaptureVideoOrientationPortrait:
//            _videoWriterInput.transform = CGAffineTransformMakeRotation(M_PI_2);
//            break;
//        case AVCaptureVideoOrientationPortraitUpsideDown:
//            _videoWriterInput.transform = CGAffineTransformMakeRotation(-M_PI_2);
//            break;
//        case AVCaptureVideoOrientationLandscapeLeft:
//            _videoWriterInput.transform = CGAffineTransformIdentity;
//            break;
//        case AVCaptureVideoOrientationLandscapeRight:
//            _videoWriterInput.transform = CGAffineTransformMakeRotation(M_PI);
//            break;
//        default:
//            break;
//    }
    
//    NSDictionary *sourcePixelBufferAttributesDictionary = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB)};
//    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    if ([_videoFileWriter canAddInput:_videoWriterInput]) {
        [_videoFileWriter addInput:_videoWriterInput];
    }
    else {
        [self _deinitVideoWriter];
        return NO;
    }
    
    // Add the audio input
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    NSDictionary* audioOutputSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey : @64000,
                                          AVSampleRateKey : @44100.0,
                                          AVNumberOfChannelsKey : @1,
                                          AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(acl)]};
//    audioOutputSettings = @{AVFormatIDKey : @(kAudioFormatMPEG4AAC),
//                            AVEncoderBitRateKey : @64000,
//                            AVSampleRateKey : @44100.0,
//                            AVNumberOfChannelsKey : @1};
//    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
//                            [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
//                            [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
//                            [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
//                            [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
//                            [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
//                            nil ];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        NSMutableDictionary *recommendedAudioSetting = [NSMutableDictionary dictionaryWithDictionary:[_audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4]];
        if (recommendedAudioSetting.count > 0) {
            [recommendedAudioSetting setObject:[NSData dataWithBytes:&acl length:sizeof(acl)] forKey:AVChannelLayoutKey];
            audioOutputSettings = recommendedAudioSetting;
        }
    }
    
    NSLog(@"audioOutputSettings = %@", audioOutputSettings);
    
    _audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings: audioOutputSettings];
    if (!_audioWriterInput) {
        [self _deinitVideoWriter];
        return NO;
    }
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
    if ([_videoFileWriter canAddInput:_audioWriterInput]) {
        [_videoFileWriter addInput:_audioWriterInput];
    }
    else {
        [self _deinitVideoWriter];
        return NO;
    }
    
    return YES;
}

- (void)_appendSampleBuffer:(CMSampleBufferRef)sampleBuffer fromCaptureOutout:(AVCaptureOutput*)captureOutput {
    
    if (captureOutput == _videoDataOutput) {
        if (_videoFileWriter.status > AVAssetWriterStatusWriting) return;
        
        if ([_videoWriterInput isReadyForMoreMediaData]) {
            [_videoWriterInput appendSampleBuffer:sampleBuffer];
        }
    }
    else if (captureOutput == _audioDataOutput && !_muteVideo) {
        if (_videoFileWriter.status > AVAssetWriterStatusWriting) return;
        
        if ([_audioWriterInput isReadyForMoreMediaData]) {
            [_audioWriterInput appendSampleBuffer:sampleBuffer];
        }
    }
    
    usleep(1000);
}

- (void)_deinitVideoWriter {
    if (_videoFileWriter) {
        [_videoFileWriter release];
    }
    _videoFileWriter = nil;
    if (_videoWriterInput) {
        [_videoWriterInput release];
    }
    _videoWriterInput = nil;
    if (_audioWriterInput) {
        [_audioWriterInput release];
    }
    _audioWriterInput = nil;
    
    if (_videoRecordError) {
        [_videoRecordError release];
    }
    _videoRecordError = nil;
    _recordedVideoDuration = 0.0;
}

- (void)_removeVideoRecordingFile {
    [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kCCCCameraDefaultVideoFileName] error:nil];
}

#pragma mark - Focus

- (void)setCameraFocusPoint:(CGPoint)point {
    if (!_videoInput) return;
    
    AVCaptureDevice *captureDevice = _videoInput.device;
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        [tempSelf _captureDevice:captureDevice onConfigurationChanged:^ {
            [tempSelf _captureDevice:captureDevice focusAtPoint:point];
        }];
    }];
    
}

- (void)_captureDevice:(AVCaptureDevice*)captureDevice focusAtPoint:(CGPoint)point {
    if ([captureDevice respondsToSelector:@selector(isSmoothAutoFocusSupported)]) {
        if (captureDevice.isSmoothAutoFocusSupported) {
            captureDevice.smoothAutoFocusEnabled = YES;
        }
    }
    
    if (captureDevice.isFocusPointOfInterestSupported) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }
    else if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
    }
    
    if ([captureDevice respondsToSelector:@selector(isAutoFocusRangeRestrictionSupported)]) {
        if (captureDevice.isAutoFocusRangeRestrictionSupported) {
            captureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNone;
        }
    }
    
    if (captureDevice.isExposurePointOfInterestSupported) {
        captureDevice.exposurePointOfInterest = point;
    }
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }
    else if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
    }
}

#pragma mark - Zoom

- (CGFloat)zoomWithPinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (self.cameraCaptureMode == CCCCameraCaptureModeVideo) {
            connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        }
        
        gestureRecognizer.scale = connection.videoScaleAndCropFactor;
    }
    
    CGFloat scale = gestureRecognizer.scale;
    [self _setCameraZoomScale:scale];
    
    return _currentZoomScale;
}

- (void)_setCameraZoomScale:(CGFloat)scale {
    scale = (scale >= _maximumZoomScale? _maximumZoomScale: (scale <= 1.0? 1.0: scale));
    
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        AVCaptureConnection *connection = [tempSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (scale <= connection.videoMaxScaleAndCropFactor) {
            connection.videoScaleAndCropFactor = scale;
        }
        
        connection = [tempSelf.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if (scale <= connection.videoMaxScaleAndCropFactor) {
            connection.videoScaleAndCropFactor = scale;
        }
        
    }];
    
    _currentZoomScale = scale;
}

- (void)_estimateMaximumZoomScale {
    CGFloat maxZoomScale = kCCCCameraDefaultMaximumZoomScale;
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.videoMaxScaleAndCropFactor < maxZoomScale && _cameraCaptureMode == CCCCameraCaptureModePhoto) {
        maxZoomScale = connection.videoMaxScaleAndCropFactor;
    }
    connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.videoMaxScaleAndCropFactor < maxZoomScale && _cameraCaptureMode == CCCCameraCaptureModeVideo) {
        maxZoomScale = connection.videoMaxScaleAndCropFactor;
    }
    
    [self _setCameraMaximumZoomScale:maxZoomScale];
}

- (void)_setCameraMaximumZoomScale:(CGFloat)maxScale {
    _maximumZoomScale = (maxScale >= kCCCCameraDefaultMaximumZoomScale? kCCCCameraDefaultMaximumZoomScale: (maxScale <= 1.0? 1.0: maxScale));
    
    [self _setCameraZoomScale:_currentZoomScale];
}

#pragma mark - Process

+ (BOOL)_checkCameraAccess {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined) {
            
            __block BOOL access = NO;
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    access = YES;
                }
                
                dispatch_group_leave(group);
            }];
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
#if !__has_feature(objc_arc)
            dispatch_release(group);
#endif
            
            return access;
        }
        else if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] != AVAuthorizationStatusAuthorized) {
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        return YES;
    }
}

+ (BOOL)isCameraAccess {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined)  {
            return YES;
        }
        else if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] != AVAuthorizationStatusAuthorized) {
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        return YES;
    }
}

- (BOOL)isCameraRunning {
    return _session.isRunning;
}

- (void)startCameraRunning {
    if (TARGET_IPHONE_SIMULATOR) return;
    
    if (self.isCameraRunning) return;
    if (![CCCCameraSession isCameraAccess]) return;
    
    _runCamera = YES;
    
    [self _startCameraRunningNotification];
    [self _startSubjectChangedObserver];
    
    [self _resetPreviewSize];
    _currentZoomScale = 1.0f;
    
    if (![CCCCameraSession _checkCameraAccess]) return;
    
    dispatch_async(_cameraSessionQueue, ^ {
        
        __block typeof(self) tempSelf = self;
        [tempSelf _onSessionConfigurationChanged:^ {
            if (tempSelf.stillImageOutput && ![tempSelf.session.outputs containsObject:tempSelf.stillImageOutput] && [tempSelf.session canAddOutput:tempSelf.stillImageOutput]) {
                [tempSelf.session addOutput:tempSelf.stillImageOutput];
            }
            if (tempSelf.metadataOutput && ![tempSelf.session.outputs containsObject:tempSelf.metadataOutput] && [tempSelf.session canAddOutput:tempSelf.metadataOutput]) {
                [tempSelf.session addOutput:tempSelf.metadataOutput];
            }
            if (tempSelf.videoDataOutput && ![tempSelf.session.outputs containsObject:tempSelf.videoDataOutput] && [tempSelf.session canAddOutput:tempSelf.videoDataOutput]) {
                [tempSelf.session addOutput:tempSelf.videoDataOutput];
            }
            if (tempSelf.audioDataOutput && ![tempSelf.session.outputs containsObject:tempSelf.audioDataOutput] && [tempSelf.session canAddOutput:tempSelf.audioDataOutput]) {
                [tempSelf.session addOutput:tempSelf.audioDataOutput];
            }
        }];
        
        [self _setupCameraDevice];
        [self _setupCameraCaptureMode];
        
        [tempSelf _onSessionConfigurationChanged:^ {
            if ([tempSelf.session.outputs containsObject:tempSelf.metadataOutput]) {
                tempSelf.metadataOutput.metadataObjectTypes = tempSelf.metadataOutput.availableMetadataObjectTypes;
            }
        }];
        
        [self.session startRunning];
    });
}

- (void)stopCameraRunning {
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    
    if (!self.isCameraRunning) {
        return;
    }
    if (![CCCCameraSession isCameraAccess]) {
        return;
    }
    
    _runCamera = NO;
    
    dispatch_async(_cameraSessionQueue, ^ {
        [self.session stopRunning];
    });
    
}

- (void)takePictureWithCompletionHandler:(void(^)(UIImage *picture, NSDictionary *pictureMetadata))handler {
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    
    if (!self.isCameraRunning) {
        return;
    }
    if (_cameraCaptureMode == CCCCameraCaptureModeVideo) {
        return;
    }
    if (_stillImageOutput.isCapturingStillImage) {
        return;
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    dispatch_async(_cameraSessionQueue, ^ {
        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection) {
            [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                
                if (imageSampleBuffer) {
                    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                    
                    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
                    CFDictionaryRef metadata =  CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
                    
                    UIImage *image = [UIImage imageWithData:imageData];
                    //UIImage *image = [CCCCameraSession _imageFromSampleBuffer:imageSampleBuffer];
                    UIImageOrientation convertedOrientation = [self _convertedImageOrientationWithMirroredTypeAndOriginal:image.imageOrientation];
                    image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:convertedOrientation];
                    
                    NSDictionary *pictureMetadata = [NSDictionary dictionaryWithDictionary:(NSDictionary*)metadata];
                    CFRelease(metadata);
                    CFRelease(source);
                    
                    pictureMetadata = [self _editedMetadataDictionary:pictureMetadata ofImage:image];
                    
                    [CCCCameraSession _executeOnMainThread:^ {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                        
                        if (handler)
                            handler(image, pictureMetadata);
                    }];
                }
                
            }];
        }
        
    });
}

- (BOOL)isVideoRecording {
    if (TARGET_IPHONE_SIMULATOR) {
        return NO;
    }
    
    if (!self.isCameraRunning) {
        return NO;
    }
    if (_cameraCaptureMode == CCCCameraCaptureModePhoto) {
        return NO;
    }
    
    return _isVideoRecording;
}

- (void)startVideoRecording {
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    
    if (!self.isCameraRunning) {
        return;
    }
    if (_cameraCaptureMode == CCCCameraCaptureModePhoto) {
        return;
    }
    
    dispatch_async(_cameraSessionQueue, ^ {
        
        [self _removeVideoRecordingFile];
        if (_videoRecordError) {
            [_videoRecordError release];
        }
        _videoRecordError = nil;
        
        if (!_isVideoRecording) {
            BOOL initVideoWriter = [self _initVideoWriter];
            if (!initVideoWriter) {
                return;
            }
            
            _isVideoRecording = YES;
        }
        
    });
}

- (void)stopVideoRecording {
    if (TARGET_IPHONE_SIMULATOR) {
        return;
    }
    
    if (!self.isCameraRunning) {
        return;
    }
    if (_cameraCaptureMode == CCCCameraCaptureModePhoto) {
        return;
    }
    
    dispatch_async(_cameraSessionQueue, ^ {
        
        if (_isVideoRecording && _videoFileWriter) {
            if (_videoFileWriter.status == AVAssetWriterStatusWriting) {
                _isVideoRecording = NO;
                
            }
        }
        
    });
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
    [self setCameraFocusPoint:CGPointMake(0.5, 0.5)];
}

#pragma mark - Camera Notifications

- (void)_startCameraRunningNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_cameraStarted:)
                                                 name:AVCaptureSessionDidStartRunningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_cameraStopped:)
                                                 name:AVCaptureSessionDidStopRunningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_sessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_cameraInterrupted:)
                                                 name:AVCaptureSessionWasInterruptedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_cameraInterruptEnded:)
                                                 name:AVCaptureSessionInterruptionEndedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)_stopCameraRunningNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionDidStartRunningNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionDidStopRunningNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionRuntimeErrorNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionWasInterruptedNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionInterruptionEndedNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
    
}

- (void)_cameraStarted:(NSNotification*)notification {
    [CCCCameraSession _executeOnMainThread:^ {
        if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSessionDidStart:)]) {
            [_delegate cccCameraSessionDidStart:self];
        }
    }];
}

- (void)_cameraStopped:(NSNotification*)notification {
    if (_videoFileWriter.status == AVAssetWriterStatusWriting) {
        _isVideoRecording = NO;
        
        _videoRecordError = [[NSError alloc] initWithDomain:@"CCCCameraSessionErrorDomain" code:-8688 userInfo:@{NSLocalizedDescriptionKey:@"Recording interrupted due to camera has been stopped.",NSLocalizedFailureReasonErrorKey:@"Recording interrupted due to camera has been stopped."}];
        
        [_videoWriterInput markAsFinished];
        [_audioWriterInput markAsFinished];
        
        [_videoFileWriter finishWritingWithCompletionHandler:^ {
            _recordedVideoDuration = 0.0;
            
            [CCCCameraSession _executeOnMainThread:^ {
                if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:didFinishVideoRecordingToFile:error:)]) {
                    [_delegate cccCameraSession:self didFinishVideoRecordingToFile:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kCCCCameraDefaultVideoFileName]] error:_videoRecordError];
                }
            }];
        }];
        [self _deinitVideoWriter];
    }
    
    if (!self.session.isInterrupted && !self.session.isRunning && !_runCamera) {
        __block typeof(self) tempSelf = self;
        [tempSelf _onSessionConfigurationChanged:^ {
            if ([tempSelf.session.outputs containsObject:tempSelf.stillImageOutput]) {
                [tempSelf.session removeOutput:_stillImageOutput];
            }
            if ([tempSelf.session.outputs containsObject:tempSelf.metadataOutput]) {
                [tempSelf.session removeOutput:tempSelf.metadataOutput];
            }
            if ([tempSelf.session.outputs containsObject:tempSelf.videoDataOutput]) {
                [tempSelf.session removeOutput:tempSelf.videoDataOutput];
            }
            if ([tempSelf.session.outputs containsObject:tempSelf.audioDataOutput]) {
                [tempSelf.session removeOutput:tempSelf.audioDataOutput];
            }
        }];
        
        [self _stopSubjectChangedObserver];
        [self _stopCameraRunningNotification];
        
        [self _resetPreviewSize];
        
        [CCCCameraSession _executeOnMainThread:^ {
            if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSessionDidStop:)]) {
                [_delegate cccCameraSessionDidStop:self];
            }
        }];
    }
    else {
        dispatch_async(_cameraSessionQueue, ^ {
            [self.session startRunning];
        });
    }
    
}

- (void)_cameraInterrupted:(NSNotification*)notification {
    if (_videoFileWriter.status == AVAssetWriterStatusWriting) {
        _isVideoRecording = NO;
        
        _videoRecordError = [[NSError alloc] initWithDomain:@"CCCCameraSessionErrorDomain" code:-8688 userInfo:@{NSLocalizedDescriptionKey:@"Recording interrupted due to camera has been stopped.",NSLocalizedFailureReasonErrorKey:@"Recording interrupted due to camera has been stopped."}];
        
        [_videoWriterInput markAsFinished];
        [_audioWriterInput markAsFinished];
        
        [_videoFileWriter finishWritingWithCompletionHandler:^ {
            _recordedVideoDuration = 0.0;
            
            [CCCCameraSession _executeOnMainThread:^ {
                if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:didFinishVideoRecordingToFile:error:)]) {
                    [_delegate cccCameraSession:self didFinishVideoRecordingToFile:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kCCCCameraDefaultVideoFileName]] error:_videoRecordError];
                }
            }];
        }];
        [self _deinitVideoWriter];
    }
}

- (void)_cameraInterruptEnded:(NSNotification*)notification {
    if (!self.session.isRunning && _runCamera) {
        dispatch_async(_cameraSessionQueue, ^ {
            [self.session startRunning];
        });
    }
}

- (void)_sessionRuntimeError:(NSNotification*)notification {
    [CCCCameraSession _executeOnMainThread:^ {
        NSError *error = [notification.userInfo objectForKey:AVCaptureSessionErrorKey];
        if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:didReceiveRuntimeError:)]) {
            [_delegate cccCameraSession:self didReceiveRuntimeError:error];
        }
    }];
}

- (void)_appDidEnterBackground:(NSNotification*)notification {
    [self stopCameraRunning];
}

- (void)_appWillTerminate:(NSNotification*)notification {
    [self stopCameraRunning];
}

#pragma mark - Orientation

- (void)setCameraVideoOrientation:(AVCaptureVideoOrientation)orientation {
    __block typeof(self) tempSelf = self;
    [tempSelf _onSessionConfigurationChanged:^ {
        AVCaptureConnection *connection = [tempSelf.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoOrientationSupported) {
            [connection setVideoOrientation:orientation];
        }
        
    }];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (captureOutput == _videoDataOutput) {
        size_t width = 0;
        size_t height = 0;
        [CCCCameraSession _getImageWidth:&width imageHeight:&height fromSampleBuffer:sampleBuffer];
        CGSize previewSize = CGSizeMake(width, height);
        if (!CGSizeEqualToSize(previewSize, CGSizeZero)) {
            if (!CGSizeEqualToSize(previewSize, _currentPreviewSize)) {
                _currentPreviewSize = previewSize;
            }
        }
    }
    
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection {
    
    if (captureOutput == _videoDataOutput) {
        size_t width = 0;
        size_t height = 0;
        [CCCCameraSession _getImageWidth:&width imageHeight:&height fromSampleBuffer:sampleBuffer];
        CGSize previewSize = CGSizeMake(width, height);
        if (!CGSizeEqualToSize(previewSize, CGSizeZero)) {
            if (!CGSizeEqualToSize(previewSize, _currentPreviewSize)) {
                _currentPreviewSize = previewSize;
            }
        }
    }
    
    if (_cameraCaptureMode == CCCCameraCaptureModePhoto) return;
    
    CMTime sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (_isVideoRecording && _videoFileWriter) {
        if (_videoFileWriter.status != AVAssetWriterStatusWriting) {
            [_videoFileWriter startWriting];
            [_videoFileWriter startSessionAtSourceTime:sampleTime];
            
            [self _appendSampleBuffer:sampleBuffer fromCaptureOutout:captureOutput];
            
            _videoStartTime = sampleTime;
            
            NSTimeInterval startTime = _videoStartTime.value/_videoStartTime.timescale;
            NSTimeInterval currentTime = sampleTime.value/sampleTime.timescale;
            _recordedVideoDuration = currentTime-startTime;
            
            [CCCCameraSession _executeOnMainThread:^ {
                if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSessionDidStartVideoRecording:)]) {
                    [_delegate cccCameraSessionDidStartVideoRecording:self];
                }
            }];
        }
        else {
            [self _appendSampleBuffer:sampleBuffer fromCaptureOutout:captureOutput];
            
            NSTimeInterval startTime = _videoStartTime.value/_videoStartTime.timescale;
            NSTimeInterval currentTime = sampleTime.value/sampleTime.timescale;
            _recordedVideoDuration = currentTime-startTime;
            
            if ((currentTime-startTime) > _maxVideoDuration && _maxVideoDuration > 0) {
                _videoRecordError = [[NSError alloc] initWithDomain:@"CCCCameraSessionErrorDomain" code:-8689 userInfo:@{NSLocalizedDescriptionKey:@"Recording time limit reached!",NSLocalizedFailureReasonErrorKey:@"Recording time limit reached!"}];
                [self stopVideoRecording];
            }
        }
    }
    else if (!_isVideoRecording && _videoFileWriter) {
        if (_videoFileWriter.status == AVAssetWriterStatusWriting) {
            [_videoWriterInput markAsFinished];
            [_audioWriterInput markAsFinished];
            
            NSError *error = [_videoRecordError copy];
            [_videoFileWriter finishWritingWithCompletionHandler:^ {
                _recordedVideoDuration = 0.0;
                
                [CCCCameraSession _executeOnMainThread:^ {
                    if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:didFinishVideoRecordingToFile:error:)]) {
                        [_delegate cccCameraSession:self didFinishVideoRecordingToFile:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kCCCCameraDefaultVideoFileName]] error:error];
                    }
                }];
                if (error) {
                    [error release];
                }
                
            }];
            [self _deinitVideoWriter];
            
        }
    }
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if (!_faceDetectEnabled && !_barcodeScanEnabled) return;
    
    NSMutableArray *barcodeObjects = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *faceObjects = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *cornersArray = [NSMutableArray arrayWithCapacity:0];
    for (id metadataObject in metadataObjects) {
        AVMetadataObject *transformedMetadataObject = [_previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        if ([transformedMetadataObject isKindOfClass:[AVMetadataFaceObject class]] && _faceDetectEnabled) {
            AVMetadataFaceObject *faceObject = (AVMetadataFaceObject*)transformedMetadataObject;
            [faceObjects addObject:faceObject];
            [cornersArray addObject:NSStringFromCGRect(faceObject.bounds)];
        }
        else if (NSClassFromString(@"AVMetadataMachineReadableCodeObject") && _barcodeScanEnabled) {
            if ([transformedMetadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                AVMetadataMachineReadableCodeObject *barcodeObject = (AVMetadataMachineReadableCodeObject*)transformedMetadataObject;
                [barcodeObjects addObject:[CCCCameraBarcodeData barcodeDataWithReadableCodeObject:barcodeObject]];
                [cornersArray addObject:barcodeObject.corners];
            }
        }
    }
    
    NSArray *corners = nil;
    if (cornersArray.count > 0) {
        corners = [NSArray arrayWithArray:cornersArray];
    }
    
    [CCCCameraSession _executeOnMainThread:^ {
        if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:shouldUpdateCorners:)]) {
            [_delegate cccCameraSession:self shouldUpdateCorners:corners];
        }
    }];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        NSSet *barcodeSet = nil;
        if (barcodeObjects.count > 0) {
            barcodeSet = [NSSet setWithArray:barcodeObjects];
        }
        
        [CCCCameraSession _executeOnMainThread:^ {
            if (_delegate && [_delegate respondsToSelector:@selector(cccCameraSession:didDetectBarcodes:)]) {
                [_delegate cccCameraSession:self didDetectBarcodes:barcodeSet];
            }
        }];
    }
    
}

#pragma mark - Static

+ (void)_executeOnMainThread:(void(^)(void))block {
    if ([NSThread isMainThread]) {
        if (block)
            block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (block)
                block();
        });
    }
}


+ (UIImage*)_imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    //製作 CVImageBufferRef
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    //從 CVImageBufferRef 取得影像的細部資訊
    uint8_t *base = CVPixelBufferGetBaseAddress(buffer);
    size_t width = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    //利用取得影像細部資訊格式化 CGContextRef
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(base,
                                                   width,
                                                   height,
                                                   8,
                                                   bytesPerRow,
                                                   colorSpace,
                                                   kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    
    if (cgContext == NULL) {
        CVPixelBufferUnlockBaseAddress(buffer, 0);
        return nil;
    }
    
    //透過 CGImageRef 將 CGContextRef 轉換成 UIImage
    CGImageRef cgImage = CGBitmapContextCreateImage(cgContext);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    cgImage = NULL;
    CGContextRelease(cgContext);
    cgContext = NULL;
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    return image;
}

+ (void)_getImageWidth:(size_t*)width imageHeight:(size_t*)height fromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    if (width) *width = CVPixelBufferGetWidth(buffer);
    if (height) *height = CVPixelBufferGetHeight(buffer);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
}

+ (NSUInteger)numberOfCameraDevice {
    return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count;
}

+ (BOOL)isCameraDeviceAvailable:(CCCCameraDevice)cameraDevice {
    UIImagePickerControllerCameraDevice imgPickerCameraDevice = UIImagePickerControllerCameraDeviceRear;
    switch (cameraDevice) {
        case CCCCameraDeviceRear:
            imgPickerCameraDevice = UIImagePickerControllerCameraDeviceRear;
            break;
        case CCCCameraDeviceFront:
            imgPickerCameraDevice = UIImagePickerControllerCameraDeviceFront;
            break;
        default:
            break;
    }
    
    return [UIImagePickerController isCameraDeviceAvailable:imgPickerCameraDevice];
}

+ (BOOL)isFlashAvailableForCameraDevice:(CCCCameraDevice)cameraDevice {
    UIImagePickerControllerCameraDevice imgPickerCameraDevice = UIImagePickerControllerCameraDeviceRear;
    switch (cameraDevice) {
        case CCCCameraDeviceRear:
            imgPickerCameraDevice = UIImagePickerControllerCameraDeviceRear;
            break;
        case CCCCameraDeviceFront:
            imgPickerCameraDevice = UIImagePickerControllerCameraDeviceFront;
            break;
        default:
            break;
    }
    
    return [UIImagePickerController isFlashAvailableForCameraDevice:imgPickerCameraDevice];
}

+ (UIImage*)previewImageForVideo:(NSURL*)videoURL atTime:(NSTimeInterval)time {
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    if (!asset) return nil;
    
    AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeCleanAperture;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    CMTime actualTime;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 1) actualTime:&actualTime error:&thumbnailImageGenerationError];
    
    UIImage *thumbnailImage = thumbnailImageRef? [UIImage imageWithCGImage:thumbnailImageRef]: nil;
    CGImageRelease(thumbnailImageRef);
    thumbnailImageRef = NULL;
    
    return thumbnailImage;
}

+ (void)convertVideoToMPEG4Format:(NSURL*)srcUrl destinationPath:(NSString*)path completionHandler:(void(^)(BOOL successful, NSError *error))handler {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:srcUrl options:nil];
    if (!avAsset.isExportable) {
        if (handler)
            handler(NO, [NSError errorWithDomain:@"CCCCameraSessionErrorDomain" code:-8690 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Source video [%@] is not exportable.", srcUrl], NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Source video [%@] is not exportable.", srcUrl]}]);
        
        return;
    }
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    /*
    NSDictionary *settings = @{AVVideoCodecKey:AVVideoCodecH264,
                               AVVideoWidthKey:@(320),
                               AVVideoHeightKey:@(480),
                               AVVideoCompressionPropertiesKey:
                                   @{AVVideoAverageBitRateKey:@(16),
                                     AVVideoProfileLevelKey:AVVideoProfileLevelH264Main31,
                                     AVVideoMaxKeyFrameIntervalKey:@(60)}};
    //*/
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:avAsset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputURL = [NSURL fileURLWithPath:path];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
//    CMTime start = CMTimeMakeWithSeconds(1.0, 600);
//    CMTime duration = CMTimeMakeWithSeconds(3.0, 600);
//    CMTimeRange range = CMTimeRangeMake(start, duration);
//    exportSession.timeRange = range;
//    UNCOMMENT ABOVE LINES FOR CROP VIDEO
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^ {
        BOOL result = NO;
        NSError *error = nil;
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusCompleted:
                result = YES;
                break;
            case AVAssetExportSessionStatusFailed:
                error = exportSession.error;
                result = NO;
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                error = exportSession.error;
                if (!error) {
                    error = [NSError errorWithDomain:@"CCCCameraSessionErrorDomain" code:-8691 userInfo:@{NSLocalizedDescriptionKey:@"Export cancelled.", NSLocalizedFailureReasonErrorKey:@"Export cancelled."}];
                }
                result = NO;
                break;
            default:
                break;
        }
        
        if (handler)
            handler(result, error);
        
    }];
    
}

@end


@implementation CCCCameraBarcodeData

+ (instancetype)barcodeDataWithReadableCodeObject:(AVMetadataMachineReadableCodeObject*)readableCodeObject {
    return [[[[self class] alloc] initWithReadableCodeObject:readableCodeObject] autorelease];
}

- (instancetype)initWithReadableCodeObject:(AVMetadataMachineReadableCodeObject*)readableCodeObject {
    self = [super init];
    if (self) {
        _value = [readableCodeObject.stringValue copy];
        _type = [readableCodeObject.type retain];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _value = nil;
        _type = nil;
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_value release];
    [_type release];
    [super dealloc];
#endif
    
}

@end
