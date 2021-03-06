//
//  BaseViewController.h
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/27.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   actions:(UIAlertAction *)actions, ... NS_REQUIRES_NIL_TERMINATION;

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
              actionsArray:(NSArray<UIAlertAction *> *)actionsArray;

@end
