//
//  SwitchViewController.m
//  CCCUIKit
//
//  Created by CHIEN-HSU WU on 2015/4/3.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "SwitchViewController.h"
#import <CCCUIKit/CCCSwitch.h>

@interface SwitchViewController ()

@property (weak, nonatomic) IBOutlet CCCSwitch *switchDefault;
@property (weak, nonatomic) IBOutlet UILabel *labelSwitchDefault;

@property (weak, nonatomic) IBOutlet CCCSwitch *switchValue1;
@property (weak, nonatomic) IBOutlet UILabel *labelSwitchValue1;

@property (weak, nonatomic) IBOutlet CCCSwitch *switchValue2;
@property (weak, nonatomic) IBOutlet UILabel *labelSwitchValue2;

@property (weak, nonatomic) IBOutlet CCCSwitch *switchValue3;
@property (weak, nonatomic) IBOutlet UILabel *labelSwitchValue3;

@property (weak, nonatomic) IBOutlet CCCSwitch *switchPowerKey;
@property (weak, nonatomic) IBOutlet UILabel *labelSwitchPowerKey;

@end

@implementation SwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Switch";
    
    self.switchDefault.style = CCCSwitchStyleDefault;
    [self.switchDefault addTarget:self action:@selector(swDefaultAction:) forControlEvents:UIControlEventValueChanged];
    
    self.switchValue1.style = CCCSwitchStyleValue1;
    [self.switchValue1 addTarget:self action:@selector(swValue1Action:) forControlEvents:UIControlEventValueChanged];
    
    self.switchValue2.style = CCCSwitchStyleValue2;
    [self.switchValue2 addTarget:self action:@selector(swValue2Action:) forControlEvents:UIControlEventValueChanged];
    
    self.switchValue3.style = CCCSwitchStyleValue3;
    [self.switchValue3 addTarget:self action:@selector(swValue3Action:) forControlEvents:UIControlEventValueChanged];
    
    self.switchPowerKey.style = CCCSwitchStylePowerKey;
    [self.switchPowerKey addTarget:self action:@selector(swPowerKeyAction:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.switchDefault.on = NO;
    self.labelSwitchDefault.text = @"State: OFF";
    
    self.switchValue1.on = NO;
    self.labelSwitchValue1.text = @"State: OFF";
    
    self.switchValue2.on = NO;
    self.labelSwitchValue2.text = @"State: OFF";
    
    self.switchValue3.on = NO;
    self.labelSwitchValue3.text = @"State: OFF";
    
    self.switchPowerKey.on = NO;
    self.labelSwitchPowerKey.text = @"State: OFF";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - ControlEvents

- (void)swDefaultAction:(CCCSwitch*)sender {
    if (self.switchDefault.isOn) {
        self.labelSwitchDefault.text = @"State: ON";
    }
    else {
        self.labelSwitchDefault.text = @"State: OFF";
    }
}

- (void)swValue1Action:(CCCSwitch*)sender {
    if (self.switchValue1.isOn) {
        self.labelSwitchValue1.text = @"State: ON";
    }
    else {
        self.labelSwitchValue1.text = @"State: OFF";
    }
}

- (void)swValue2Action:(CCCSwitch*)sender {
    if (self.switchValue2.isOn) {
        self.labelSwitchValue2.text = @"State: ON";
    }
    else {
        self.labelSwitchValue2.text = @"State: OFF";
    }
}

- (void)swValue3Action:(CCCSwitch*)sender {
    if (self.switchValue3.isOn) {
        self.labelSwitchValue3.text = @"State: ON";
    }
    else {
        self.labelSwitchValue3.text = @"State: OFF";
    }
}

- (void)swPowerKeyAction:(CCCSwitch*)sender {
    if (self.switchPowerKey.isOn) {
        self.labelSwitchPowerKey.text = @"State: ON";
    }
    else {
        self.labelSwitchPowerKey.text = @"State: OFF";
    }
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
