//
//  CCCCameraView.h
//
//  Created by CHIEN-HSU WU on 2015/8/17.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CCCCameraSession.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CCCCameraExposureControlMode) {
    CCCCameraExposureControlModeSystem = 0,
    CCCCameraExposureControlModeSlider,
    CCCCameraExposureControlModeCustom
} NS_ENUM_AVAILABLE_IOS(8_0);

@protocol CCCCameraViewDelegate;

NS_CLASS_AVAILABLE_IOS(6_0)
@interface CCCCameraView : UIView <CCCCameraController, CCCCameraSessionDelegate>

@property (assign, nonatomic, nullable) id<CCCCameraViewDelegate> delegate;

// must not override its delegate.
@property (readonly, retain, nonatomic) CCCCameraSession *cameraSession;

// default is CCCCameraPreviewScaleTypeScaleToFill.
@property (assign, nonatomic) CCCCameraPreviewScaleType scaleType;

- (void)lockPictureOrientationWithOrientation:(UIInterfaceOrientation)orientation;
- (void)unlockPictureOrientation;

@property (assign, nonatomic) CCCCameraExposureControlMode exposureControlMode NS_AVAILABLE_IOS(8_0);

@end

@protocol CCCCameraViewDelegate <NSObject>
@optional

- (void)cccCameraViewCameraDidStart:(CCCCameraView*)view;
- (void)cccCameraViewCameraDidStop:(CCCCameraView*)view;

- (void)cccCameraView:(CCCCameraView*)view orientationDidChanged:(UIInterfaceOrientation)orientation;

- (void)cccCameraViewDidStartVideoRecording:(CCCCameraView*)view;
- (void)cccCameraView:(CCCCameraView *)view didFinishVideoRecordingToFile:(NSURL*)fileURL error:(NSError* _Nullable)error;

- (void)cccCameraView:(CCCCameraView*)view didScanBarcodeWithArray:(NSSet<CCCCameraBarcodeData*>* _Nullable)barcodeSet NS_AVAILABLE_IOS(7_0);

@end

NS_ASSUME_NONNULL_END
