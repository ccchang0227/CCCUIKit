//
//  DeviceInfoViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/26.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "DeviceInfoViewController.h"
#import <CCCUIKit/CCCDevice.h>


@interface DeviceInfoViewController ()

@property (weak, nonatomic) IBOutlet UITextView *infoTextView;

@end

@implementation DeviceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Device";
    
    self.infoTextView.textContainerInset = UIEdgeInsetsZero;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableString *infoString = [NSMutableString string];
    [infoString appendFormat:@"裝置名稱: %@\n", [UIDevice currentDevice].name];
    [infoString appendFormat:@"裝置識別: %@\n", [CCCDevice machine]];
    [infoString appendFormat:@"裝置型號: %@\n", [CCCDevice model]];
    [infoString appendFormat:@"iOS版本: %@\n", [CCCDevice version]];
    [infoString appendString:@"\n"];
    [infoString appendFormat:@"螢幕像素點: %@\n", [CCCDevice screenPixels]];
    [infoString appendFormat:@"螢幕解析度: %@\n", [CCCDevice screenResolution]];
    [infoString appendFormat:@"螢幕解析度縮放: %@\n", [CCCDevice screenScale]];
    [infoString appendFormat:@"是否為Retina: %@\n", [CCCDevice isRetina]?@"YES":@"NO"];
    [infoString appendString:@"\n"];
    [infoString appendFormat:@"App名稱: %@\n", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
    [infoString appendFormat:@"App版本: %@\n", [CCCDevice appVersion]];
    [infoString appendFormat:@"App版本號(建置版本): %@\n", [CCCDevice appBuildVersion]];
    
    self.infoTextView.text = infoString;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
