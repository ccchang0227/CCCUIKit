//
//  RatingControlViewController.m
//  CustomUIKit
//
//  Created by CHIEN-HSU WU on 2015/3/25.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "RatingControlViewController.h"
#import "CCCRatingControl.h"

@interface RatingControlViewController ()

@property (weak, nonatomic) IBOutlet CCCRatingControl *ratingCtrl1;
@property (weak, nonatomic) IBOutlet CCCRatingControl *ratingCtrl1_2;
@property (weak, nonatomic) IBOutlet CCCRatingControl *ratingCtrl1_3;
@property (weak, nonatomic) IBOutlet CCCRatingControl *ratingCtrl1_4;

@end

@implementation RatingControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"RatingControl";
    
    UIImage *ratingImage = starImage(CGSizeMake(80, 80), [UIColor redColor], [UIColor whiteColor], YES);
    UIImage *highlightedRatingImage = starImage(CGSizeMake(80, 80), [UIColor redColor], [UIColor redColor], YES);
    
    self.ratingCtrl1.ratingImage = ratingImage;
    self.ratingCtrl1.highlightedRatingImage = highlightedRatingImage;
    self.ratingCtrl1.maximumValue = 5;
    self.ratingCtrl1.fractionNumber = 1;
    self.ratingCtrl1.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    self.ratingCtrl1_2.ratingImage = ratingImage;
    self.ratingCtrl1_2.highlightedRatingImage = highlightedRatingImage;
    self.ratingCtrl1_2.maximumValue = 5;
    self.ratingCtrl1_2.fractionNumber = 2;
    self.ratingCtrl1_2.edgeBetweenUnits = 5.0;
    
    self.ratingCtrl1_3.ratingImage = ratingImage;
    self.ratingCtrl1_3.highlightedRatingImage = highlightedRatingImage;
    self.ratingCtrl1_3.maximumValue = 5;
    self.ratingCtrl1_3.fractionNumber = 3;
    self.ratingCtrl1_3.edgeBetweenUnits = 10.0;
    self.ratingCtrl1_3.enabled = NO;
    
    self.ratingCtrl1_4.ratingImage = ratingImage;
    self.ratingCtrl1_4.highlightedRatingImage = highlightedRatingImage;
    self.ratingCtrl1_4.maximumValue = 5;
    self.ratingCtrl1_4.fractionNumber = 4;
    self.ratingCtrl1_4.edgeBetweenUnits = 15.0;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.ratingCtrl1.value = self.ratingCtrl1.maximumValue/2.0;
    self.ratingCtrl1_2.value = self.ratingCtrl1_2.maximumValue/2.0;
    self.ratingCtrl1_3.value = self.ratingCtrl1_3.maximumValue/2.0;
    self.ratingCtrl1_4.value = self.ratingCtrl1_4.maximumValue/2.0;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
