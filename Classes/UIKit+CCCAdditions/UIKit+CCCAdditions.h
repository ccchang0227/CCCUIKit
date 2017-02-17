//
//  UIKit+CCCAdditions.h
//  
//
//  Created by realtouchapp on 2017/2/16.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * UIKit+CCCAdditions
 *
 * @version 1.0.0
 * @author Chih-chieh Chang
 * @date 2017-02-16
 */

#ifndef SYSTEM_VERSION_EQUAL_TO
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif

#ifndef SYSTEM_VERSION_LESS_THAN
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#endif

#ifndef SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
#endif


@interface UIView (CCC_SubviewHunting)

- (UIView *)huntedSubviewWithClassName:(NSString *)className;
- (void)debugSubviews;

@end


@interface UIView (CCC_UINibLoadingAdditions)

+ (NSString *)nibName;
+ (NSBundle *)nibBundle; // default to main bundle
/// Note: You has responsibility to release instance when object is useless.
+ (instancetype)newInstanceFromNib;

/// Note: You has responsibility to release instance when object is useless.
+ (instancetype)newInstanceWithNibName:(NSString *)nibNameOrNil nibBundle:(NSBundle *)nibBundleOrNil;
/// Note: You has responsibility to release instance when object is useless.
+ (instancetype)newInstanceFromNib:(UINib *)nib;

@end


@interface UIColor (CCC_Additions)

+ (UIColor *)randomColor;

/// Assume input as 0x21F899(RGB)
+ (UIColor *)colorWithHexRGB:(NSUInteger)hexRGBValue;

/// Assume input as 0x21F899(RGB), and alpha with range 0.0~1.0
+ (UIColor *)colorWithHexRGB:(NSUInteger)hexRGBValue alpha:(CGFloat)alpha;

@property (readonly, nonatomic) UIColor *contrastColor;

@end


@interface UIViewController (CCC_TopViewControllerAdditions)

@property (readonly, nonatomic) UIViewController *topViewController;
+ (UIViewController *)topViewController:(UIViewController *)rootViewController;

@end


@interface NSString (CCC_Additions)

/// detect whether string is all digit.
@property (readonly, nonatomic, getter=isAllDigits) BOOL allDigits;
/// detect string is email format or not.
@property (readonly, nonatomic, getter=isEmailFormat) BOOL emailFormat;
/// detect string is phone number format or not.
@property (readonly, nonatomic, getter=isPhoneNumberFormat) BOOL phoneNumberFormat;

@end
