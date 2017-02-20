//
//  CCCSwitch.h
//
//  Created by CHIEN-HSU WU on 2015/4/3.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CCCSwitchStyle) {
    CCCSwitchStyleDefault = 0,
    CCCSwitchStyleValue1,
    CCCSwitchStyleValue2,
    CCCSwitchStyleValue3,
    CCCSwitchStylePowerKey
};

/**
 * Custom UISwitch
 *
 * @version 0.0.6
 * @author Chih-chieh Chang
 * @date 2017-02-20
 */
@interface CCCSwitch : UIControl

@property (nonatomic) CCCSwitchStyle style;

@property (nonatomic, copy) UIColor *onTintColor;

@property (nonatomic, getter=isOn) BOOL on;

// This class enforces a size appropriate for the control. The frame size is ignored.
- (instancetype)initWithStyle:(CCCSwitchStyle)style;
- (instancetype)initWithFrame:(CGRect)frame style:(CCCSwitchStyle)style;

@end
