//
//  BaseViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/27.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   actions:(UIAlertAction *)actions, ... {
    
    NSMutableArray *actionsArray = [NSMutableArray array];
    if (actions) {
        UIAlertAction *action = actions;
        [actionsArray addObject:action];
        
        va_list args;
        va_start(args, actions);
        while ((action = va_arg(args, UIAlertAction *))) {
            if (action && [action isKindOfClass:[UIAlertAction class]]) {
                [actionsArray addObject:action];
            }
        }
        va_end(args);
    }
    
    if (actionsArray.count > 0) {
        [self showAlertWithTitle:title message:message actionsArray:actionsArray];
    }
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              actionsArray:(NSArray<UIAlertAction *> *)actionsArray {
    if (![UIAlertController class]) {
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    for (UIAlertAction *action in actionsArray) {
        [alertController addAction:action];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
