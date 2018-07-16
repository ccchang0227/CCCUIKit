//
//  CCCMaskedLabel.h
//
//  Created by CHIEN-HSU WU on 2015/3/20.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * UILabel with transparent text.
 * 
 * @version 0.0.7
 * @author Chih-chieh Chang
 * @date 2018-07-16
 */
@interface CCCMaskedLabel : UILabel

@property (nonatomic, retain) UIColor *shadowColor NS_UNAVAILABLE; // useless.
@property (nonatomic) CGSize shadowOffset NS_UNAVAILABLE; // useless.

@property (nonatomic, getter=isTextStroked) BOOL textStroked; // default is NO.
@property (nonatomic) CGFloat textStrokeWidth; // default is 1.0. Only works while textStroked=YES.
// Warning: set textStrokeWidth too large may be unable to see the original text.

@property (nonatomic, retain) CALayer *backgroundLayer; // default is nil. Will be drawn behind transparent text.

@end
