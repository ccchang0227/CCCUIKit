//
//  CCCCameraConstants.h
//
//  Created by CHIEN-HSU WU on 2015/10/1.
//  Copyright © 2015年 CHIEN-HSU WU. All rights reserved.
//

#ifndef CCCCameraConstants_h
#define CCCCameraConstants_h

#ifndef CCC2String
#define CCC2String(c) (@"" # c)
#endif

typedef NS_ENUM(NSInteger, CCCCameraVideoQuality) {
    CCCCameraVideoQualityPhoto,
    CCCCameraVideoQualityHigh,
    CCCCameraVideoQualityMedium,
    CCCCameraVideoQualityLow,
    CCCCameraVideoQuality352x288,
    CCCCameraVideoQuality640x480,
    CCCCameraVideoQuality960x540,
    CCCCameraVideoQuality1280x720,
    CCCCameraVideoQuality1920x1080
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, CCCCameraCaptureMode) {
    CCCCameraCaptureModePhoto,
    CCCCameraCaptureModeVideo
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, CCCCameraDevice) {
    CCCCameraDeviceRear,
    CCCCameraDeviceFront
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, CCCCameraFlashMode) {
    CCCCameraFlashModeOff = -1,
    CCCCameraFlashModeAuto = 0,
    CCCCameraFlashModeOn = 1, // If cameraCaptureMode is CCCCameraCaptureModeVideo, this value will be the same as CCCCameraFlashModeTorch.
    CCCCameraFlashModeTorch = 2
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, CCCCameraVideoMirrorType) {
    CCCCameraVideoMirrorTypeNo = 0,
    CCCCameraVideoMirrorTypeYes = 1
} NS_ENUM_AVAILABLE_IOS(6_0);

typedef NS_ENUM(NSInteger, CCCCameraPreviewScaleType) {
    CCCCameraPreviewScaleTypeScaleAspectFit,
    CCCCameraPreviewScaleTypeScaleAspectFill
} NS_ENUM_AVAILABLE_IOS(6_0);


NS_ASSUME_NONNULL_BEGIN

/**
 *  @author Chih-chieh Chang, 16-04-26
 *
 *  Standard Camera Parameters Protocol
 */
NS_AVAILABLE_IOS(6_0)
@protocol CCCCameraController <NSObject>
@required

@property (assign, nonatomic) CCCCameraVideoQuality videoQuality;

// default is CCCCameraCaptureModePhoto.
@property (assign, nonatomic) CCCCameraCaptureMode cameraCaptureMode;
// default is CCCCameraDeviceRear.
@property (assign, nonatomic) CCCCameraDevice cameraDevice;
// default is CCCCameraFlashModeAuto.
@property (assign, nonatomic) CCCCameraFlashMode cameraFlashMode;
// default is CCCCameraVideoMirrorTypeNo.
@property (assign, nonatomic) CCCCameraVideoMirrorType cameraMirrorType;

@property (assign, nonatomic, getter=isFaceDetectEnabled) BOOL faceDetectEnabled;
@property (assign, nonatomic, getter=isBarcodeScanEnabled) BOOL barcodeScanEnabled NS_AVAILABLE_IOS(7_0);

@property (readonly, nonatomic, getter=isCameraRunning) BOOL cameraRunning;

+ (BOOL)isCameraAccess;

- (void)startCameraRunning;
- (void)stopCameraRunning;

// Controllers for taking still image

- (void)takePictureWithCompletionHandler:(void(^)(UIImage *_Nullable picture, NSDictionary *_Nullable pictureMetadata))handler;

// Controllers for video recording

@property (readonly, nonatomic) NSTimeInterval recordedVideoDuration;
@property (assign, nonatomic) NSTimeInterval maxVideoDuration;
@property (assign, nonatomic) BOOL muteVideo;

@property (readonly, nonatomic, getter=isVideoRecording) BOOL videoRecording;

- (void)startVideoRecording;
- (void)stopVideoRecording;

// Static Methods

+ (NSUInteger)numberOfCameraDevice;
+ (BOOL)isCameraDeviceAvailable:(CCCCameraDevice)cameraDevice;
+ (BOOL)isFlashAvailableForCameraDevice:(CCCCameraDevice)cameraDevice;
+ (UIImage*)previewImageForVideo:(NSURL*)videoURL atTime:(NSTimeInterval)time;
+ (void)convertVideoToMPEG4Format:(NSURL*)srcUrl destinationPath:(NSString*)path completionHandler:(void(^)(BOOL successful, NSError *_Nullable error))handler;

@end

NS_ASSUME_NONNULL_END

#endif /* CCCCameraConstants_h */
