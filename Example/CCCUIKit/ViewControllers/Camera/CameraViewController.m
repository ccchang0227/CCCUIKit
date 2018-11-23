//
//  CameraViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/26.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "CameraViewController.h"
#import <CCCUIKit/CCCCamera.h>
#import <ActionSheetPicker-3.0/ActionSheetPicker.h>
#import "DisplayImageViewController.h"

@interface CameraViewController () <CCCCameraViewDelegate>

@property (weak, nonatomic) IBOutlet CCCCameraView *cameraView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flashButton;

@property (weak, nonatomic) IBOutlet UIToolbar *myToolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *qrCodeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scaleTypeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *qualityButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Camera";
    
    self.cameraView.delegate = self;
    self.cameraView.videoQuality = CCCCameraVideoQualityPhoto;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self initView];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.cameraView startCameraRunning];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.cameraView stopCameraRunning];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -

- (void)initView {
    if ([CCCCameraView numberOfCameraDevice] <= 1) {
        self.switchButton.enabled = NO;
    }
    else {
        self.switchButton.enabled = YES;
    }
    
    [self configureFlash];
    [self configureQuality];
    [self configureQRCodeScan];
    [self configureScaleType];
    
}

- (void)configureFlash {
    switch (self.cameraView.cameraFlashMode) {
        case CCCCameraFlashModeOff: {
            self.flashButton.image = [UIImage imageNamed:@"flash_off"];
            break;
        }
        case CCCCameraFlashModeAuto: {
            self.flashButton.image = [UIImage imageNamed:@"flash_auto"];
            break;
        }
        default: {
            self.flashButton.image = [UIImage imageNamed:@"flash_on"];
            break;
        }
    }
    
    if ([CCCCameraView isFlashAvailableForCameraDevice:self.cameraView.cameraDevice]) {
        self.flashButton.enabled = YES;
    }
    else {
        self.flashButton.enabled = NO;
    }
    
}

- (void)configureQuality {
    switch (self.cameraView.videoQuality) {
        case CCCCameraVideoQualityLow: {
            self.qualityButton.title = @"Low";
            break;
        }
        case CCCCameraVideoQualityMedium: {
            self.qualityButton.title = @"Medium";
            break;
        }
        case CCCCameraVideoQualityHigh: {
            self.qualityButton.title = @"High";
            break;
        }
        case CCCCameraVideoQuality352x288: {
            self.qualityButton.title = @"352x288";
            break;
        }
        case CCCCameraVideoQuality640x480: {
            self.qualityButton.title = @"640x480";
            break;
        }
        case CCCCameraVideoQuality960x540: {
            self.qualityButton.title = @"960x540";
            break;
        }
        case CCCCameraVideoQuality1280x720: {
            self.qualityButton.title = @"1280x720";
            break;
        }
        case CCCCameraVideoQuality1920x1080: {
            self.qualityButton.title = @"1920x1080";
            break;
        }
        default: {
            self.qualityButton.title = @"Photo";
            break;
        }
    }
    
}

- (void)configureQRCodeScan {
    if (self.cameraView.isBarcodeScanEnabled) {
        self.qrCodeButton.tintColor = nil;
    }
    else {
        self.qrCodeButton.tintColor = [UIColor darkGrayColor];
    }
    
}

- (void)configureScaleType {
    switch (self.cameraView.scaleType) {
        case CCCCameraPreviewScaleTypeScaleAspectFit: {
            self.scaleTypeButton.image = [UIImage imageNamed:@"aspect_fit"];
            break;
        }
        default: {
            self.scaleTypeButton.image = [UIImage imageNamed:@"aspect_fill"];
            break;
        }
    }
    
}

#pragma mark -

- (IBAction)switchCamera:(id)sender {
    if ([CCCCameraView numberOfCameraDevice] <= 1) {
        return;
    }
    
    switch (self.cameraView.cameraDevice) {
        case CCCCameraDeviceRear: {
            self.cameraView.cameraDevice = CCCCameraDeviceFront;
            break;
        }
        default: {
            self.cameraView.cameraDevice = CCCCameraDeviceRear;
            break;
        }
    }
    [self configureFlash];
    [self configureQuality];
    
}

- (IBAction)changeFlash:(id)sender {
    if (![CCCCameraView isFlashAvailableForCameraDevice:self.cameraView.cameraDevice]) {
        return;
    }
    
    switch (self.cameraView.cameraFlashMode) {
        case CCCCameraFlashModeOff: {
            self.cameraView.cameraFlashMode = CCCCameraFlashModeAuto;
            break;
        }
        case CCCCameraFlashModeAuto: {
            self.cameraView.cameraFlashMode = CCCCameraFlashModeOn;
            break;
        }
        default: {
            self.cameraView.cameraFlashMode = CCCCameraFlashModeOff;
            break;
        }
    }
    [self configureFlash];
    
}

- (IBAction)qrCodeAction:(id)sender {
    self.cameraView.barcodeScanEnabled = !self.cameraView.isBarcodeScanEnabled;
    
    [self configureQRCodeScan];
    
}

- (IBAction)starAction:(id)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        return;
    }
    
    switch (self.cameraView.exposureControlMode) {
        case CCCCameraExposureControlModeSystem: {
            self.cameraView.exposureControlMode = CCCCameraExposureControlModeSlider;
            break;
        }
        default: {
            self.cameraView.exposureControlMode = CCCCameraExposureControlModeSystem;
            break;
        }
    }
    
}

- (IBAction)changeScaleTypeAction:(id)sender {
    switch (self.cameraView.scaleType) {
        case CCCCameraPreviewScaleTypeScaleAspectFit: {
            self.cameraView.scaleType = CCCCameraPreviewScaleTypeScaleAspectFill;
            break;
        }
        default: {
            self.cameraView.scaleType = CCCCameraPreviewScaleTypeScaleAspectFit;
            break;
        }
    }
    [self configureScaleType];
    
}

- (IBAction)takePicture:(id)sender {
    __weak typeof(self) tempSelf = self;
    if (tempSelf.cameraView.cameraCaptureMode == CCCCameraCaptureModePhoto) {
        
        NSDate *timeStarted = [NSDate date];
        
        void(^completion)(UIImage *, NSDictionary *) = ^(UIImage *picture, NSDictionary *pictureMetadata) {
            
            NSLog(@"%@", pictureMetadata);
            NSLog(@"picture size=%@", NSStringFromCGSize(picture.size));
            
            NSDate *timeEnded = [NSDate date];
            NSTimeInterval executionTime = [timeEnded timeIntervalSinceDate:timeStarted];
            
            __strong typeof(tempSelf) strongSelf = tempSelf;
            
            DisplayImageViewController *imageViewController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"DisplayImageViewController"];
            imageViewController.executionTime = executionTime;
            imageViewController.image = picture;
            [strongSelf.navigationController pushViewController:imageViewController animated:YES];
            
        };
        
#if 0
        [tempSelf.cameraView.cameraSession takePictureWithCompletionHandler:completion];
#else
        [tempSelf.cameraView takePictureWithCompletionHandler:completion];
#endif
        
    }
    
}

- (IBAction)selectQuality:(id)sender {
    NSArray *qualityKeys = @[@(CCCCameraVideoQualityLow),
                             @(CCCCameraVideoQualityMedium),
                             @(CCCCameraVideoQualityHigh),
                             @(CCCCameraVideoQuality352x288),
                             @(CCCCameraVideoQuality640x480),
                             @(CCCCameraVideoQuality960x540),
                             @(CCCCameraVideoQuality1280x720),
                             @(CCCCameraVideoQuality1920x1080),
                             @(CCCCameraVideoQualityPhoto)];
    NSArray *qualityStrings = @[@"Low",
                                @"Medium",
                                @"High",
                                @"352x288",
                                @"640x480",
                                @"960x540",
                                @"1280x720",
                                @"1920x1080",
                                @"Photo"];
    NSInteger index = [qualityKeys indexOfObject:@(self.cameraView.videoQuality)];
    
    [ActionSheetStringPicker showPickerWithTitle:@"Select video quality" rows:qualityStrings initialSelection:index doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
        
        self.cameraView.videoQuality = [qualityKeys[selectedIndex] integerValue];
        [self configureQuality];
        
    }cancelBlock:^(ActionSheetStringPicker *picker) {
        
    }origin:sender];
    
}

#pragma mark - CCCCameraViewDelegate

- (void)cccCameraViewCameraDidStart:(CCCCameraView *)view {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self configureFlash];
    [self configureQuality];
    
}

- (void)cccCameraViewCameraDidStop:(CCCCameraView *)view {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)cccCameraViewDidStartVideoRecording:(CCCCameraView*)view {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)cccCameraView:(CCCCameraView *)view didFinishVideoRecordingToFile:(NSURL*)fileURL error:(NSError*)error {
    NSLog(@"%s:%@", __PRETTY_FUNCTION__, fileURL);
    NSLog(@"error:%@", error);
    
}

- (void)cccCameraView:(CCCCameraView*)view orientationDidChanged:(UIInterfaceOrientation)orientation {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)cccCameraView:(CCCCameraView *)view didScanBarcodeWithArray:(NSSet<CCCCameraBarcodeData *> *)barcodeSet {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

#pragma mark - View controller rotation methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

@end
