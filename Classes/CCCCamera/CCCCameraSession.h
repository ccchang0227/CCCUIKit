//
//  CCCCameraSession.h
//
//  Created by CHIEN-HSU WU on 2015/8/17.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "CCCCameraConstants.h"


NS_ASSUME_NONNULL_BEGIN

@class CCCCameraBarcodeData;
@protocol CCCCameraSessionDelegate;

NS_CLASS_AVAILABLE_IOS(6_0)
@interface CCCCameraSession : NSObject <CCCCameraController>

@property (assign, nonatomic, nullable) id<CCCCameraSessionDelegate> delegate;

@property (readonly, retain, nonatomic) AVCaptureSession *session;

@property (readonly, nonatomic) CGSize currentPreviewSize;

- (instancetype)initWithVideoPreviewLayer:(AVCaptureVideoPreviewLayer* _Nullable)previewLayer NS_DESIGNATED_INITIALIZER;

- (void)setCameraFocusPoint:(CGPoint)point;

@property (readonly, nonatomic) float maxExposureBias NS_AVAILABLE_IOS(8_0);
@property (readonly, nonatomic) float minExposureBias NS_AVAILABLE_IOS(8_0);
@property (readonly, nonatomic) float currentExposureBias NS_AVAILABLE_IOS(8_0);
- (void)setCameraExposureBias:(float)bias NS_AVAILABLE_IOS(8_0);

- (CGFloat)zoomWithPinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer;

- (void)setCameraVideoOrientation:(AVCaptureVideoOrientation)orientation;

@property (assign, nonatomic) CGFloat videoSizeRatio; // w / h

@end

@protocol CCCCameraSessionDelegate <NSObject>
@optional

- (void)cccCameraSessionDidStart:(CCCCameraSession*)cameraSession;
- (void)cccCameraSessionDidStop:(CCCCameraSession*)cameraSession;
- (void)cccCameraSession:(CCCCameraSession*)cameraSession didReceiveRuntimeError:(NSError*)error;

- (void)cccCameraSessionDidStartVideoRecording:(CCCCameraSession*)cameraSession;
- (void)cccCameraSession:(CCCCameraSession *)cameraSession didFinishVideoRecordingToFile:(NSURL*)fileURL error:(NSError* _Nullable)error;

- (void)cccCameraSession:(CCCCameraSession*)cameraSession shouldUpdateCorners:(NSArray* _Nullable)cornersArray;
// barcodesArray will be nil or an array contains CCCCameraBarcodeData.
- (void)cccCameraSession:(CCCCameraSession*)cameraSession didDetectBarcodes:(NSSet<CCCCameraBarcodeData*>* _Nullable)barcodeSet NS_AVAILABLE_IOS(7_0);

@end


NS_CLASS_AVAILABLE_IOS(7_0)
@interface CCCCameraBarcodeData : NSObject

@property (readonly, copy, nonatomic, nullable) NSString *value;
@property (readonly, retain, nonatomic, nullable) NSString *type;

@end

NS_ASSUME_NONNULL_END
