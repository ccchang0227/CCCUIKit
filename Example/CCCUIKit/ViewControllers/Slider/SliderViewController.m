//
//  SliderViewController.m
//  CCCUIKit
//
//  Created by CHIEN-HSU WU on 2015/3/23.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "SliderViewController.h"
#import <CCCUIKit/CCCSlider.h>

@interface SliderViewController ()

@property (weak, nonatomic) IBOutlet UIView *viewTopColor;
@property (weak, nonatomic) IBOutlet UILabel *labelRed;
@property (weak, nonatomic) IBOutlet CCCSlider *sliderRed;
@property (weak, nonatomic) IBOutlet UILabel *labelGreen;
@property (weak, nonatomic) IBOutlet CCCSlider *sliderGreen;
@property (weak, nonatomic) IBOutlet UILabel *labelBlue;
@property (weak, nonatomic) IBOutlet CCCSlider *sliderBlue;

@property (weak, nonatomic) IBOutlet UILabel *labelCustom;
@property (weak, nonatomic) IBOutlet CCCSlider *sliderCustom;

@end

@implementation SliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Slider";
    
    self.viewTopColor.layer.borderWidth = 1.0f;
    self.viewTopColor.layer.shadowOffset = CGSizeMake(5, 5);
    self.viewTopColor.layer.shadowOpacity = 0.5;
    
    self.sliderRed.maximumValue = 1.0f;
    [self.sliderRed addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.sliderGreen.maximumValue = 1.0f;
    [self.sliderGreen addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.sliderBlue.maximumValue = 1.0f;
    [self.sliderBlue addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.sliderCustom.maximumValue = 10;
    [self.sliderCustom addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.sliderCustom.edged = YES;
    self.sliderCustom.sliderTrackingColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor yellowColor], [UIColor greenColor], [UIColor cyanColor], [UIColor blueColor], [UIColor purpleColor]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.sliderRed.value = 1.0f;
    self.sliderGreen.value = 1.0f;
    self.sliderBlue.value = 1.0f;
    
    [self setupRed];
    [self setupGreen];
    [self setupBlue];
    [self setupColor];
    
    self.sliderCustom.value = 5;
    self.labelCustom.text = [NSString stringWithFormat:@"%d", (int)self.sliderCustom.value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - setup

- (void)setupRed {
    self.labelRed.text = [NSString stringWithFormat:@"Red:%d", (int)(255*self.sliderRed.value)];
    self.sliderRed.sliderTrackingColors = @[[UIColor colorWithRed:self.sliderRed.value green:0.0 blue:0.0 alpha:1.0]];
}

- (void)setupGreen {
    self.labelGreen.text = [NSString stringWithFormat:@"Green:%d", (int)(255*self.sliderGreen.value)];
    self.sliderGreen.sliderTrackingColors = @[[UIColor colorWithRed:0.0 green:self.sliderGreen.value blue:0.0 alpha:1.0]];
}

- (void)setupBlue {
    self.labelBlue.text = [NSString stringWithFormat:@"Blue:%d", (int)(255*self.sliderBlue.value)];
    self.sliderBlue.sliderTrackingColors = @[[UIColor colorWithRed:0.0 green:0.0 blue:self.sliderBlue.value alpha:1.0]];
}

- (void)setupColor {
    self.viewTopColor.backgroundColor = [UIColor colorWithRed:self.sliderRed.value green:self.sliderGreen.value blue:self.sliderBlue.value alpha:1.0];
}

#pragma mark - Slider Action

- (void)sliderValueChanged:(CCCSlider*)slider {
    if (slider == self.sliderRed) {
        [self setupRed];
    }
    else if (slider == self.sliderGreen) {
        [self setupGreen];
    }
    else if (slider == self.sliderBlue) {
        [self setupBlue];
    }
    else if (slider == self.sliderCustom) {
        self.labelCustom.text = [NSString stringWithFormat:@"%d", (int)self.sliderCustom.value];
    }
    [self setupColor];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

@end
