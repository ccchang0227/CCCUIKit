//
//  UIKit+CCCAdditions.m
//  
//
//  Created by realtouchapp on 2017/2/16.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "UIKit+CCCAdditions.h"


#define CCC_ARC4RANDOM_MAX          0x100000000


@implementation UIView (CCC_SubviewHunting)

- (UIView *)huntedSubviewWithClassName:(NSString *)className {
    if ([[[self class] description] isEqualToString:className]) {
        return self;
    }
    
    for (UIView *subview in self.subviews) {
        UIView *huntedSubview = [subview huntedSubviewWithClassName:className];
        
        if (huntedSubview) {
            return huntedSubview;
        }
    }
    
    return nil;
}

- (void)debugSubviews {
    [self _debugSubviews:0];
}

- (void)_debugSubviews:(NSUInteger)count {
    if (count == 0) {
        printf("\n\n");
    }
    
    for (int i = 0; i <= count; i ++) {
        printf("--");
    }
    
    printf(" %lu: %s\n", (unsigned long)count, [[self class] description].UTF8String);
    
    for (UIView *x in self.subviews) {
        [x _debugSubviews:(count+1)];
    }
    
    if (count == 0) {
        printf("\n\n");
    }
}

@end


@implementation UIView (CCC_UINibLoadingAdditions)

+ (NSString *)nibName {
    return NSStringFromClass([self class]);
}

+ (NSBundle *)nibBundle {
    return [NSBundle mainBundle];
}

+ (instancetype)newInstanceFromNib {
    return [self newInstanceWithNibName:[self nibName] nibBundle:[self nibBundle]];
}

+ (instancetype)newInstanceWithNibName:(NSString *)nibNameOrNil nibBundle:(NSBundle *)nibBundleOrNil {
    if (!nibNameOrNil) {
        return [[[self class] alloc] init];
    }
    
    UINib *nib = [UINib nibWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return [self newInstanceFromNib:nib];
}

+ (instancetype)newInstanceFromNib:(UINib *)nib {
    if (!nib) {
        return [[[self class] alloc] init];
    }
    
    NSArray *nibObjs = [nib instantiateWithOwner:self options:nil];
    UIView *view = nil;
    for (id obj in nibObjs) {
        if ([obj isMemberOfClass:[self class]]) {
            view = [obj retain];
            break;
        }
    }
    if (!view) {
        view = [[[self class] alloc] init];
    }
    
    return view;
}

@end


@implementation UIColor (CCC_Additions)

+ (UIColor *)randomColor {
    return [UIColor colorWithRed:(arc4random()/(CGFloat)CCC_ARC4RANDOM_MAX)
                           green:(arc4random()/(CGFloat)CCC_ARC4RANDOM_MAX)
                            blue:(arc4random()/(CGFloat)CCC_ARC4RANDOM_MAX)
                           alpha:1.000];
}

+ (UIColor *)colorWithHexRGB:(NSUInteger)hexRGBValue {
    return [UIColor colorWithHexRGB:hexRGBValue alpha:1.0];
}

+ (UIColor *)colorWithHexRGB:(NSUInteger)hexRGBValue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hexRGBValue&0xFF0000) >> 16))/255.0
                           green:((float)((hexRGBValue&0x00FF00) >>  8))/255.0
                            blue:((float)((hexRGBValue&0x0000FF) >>  0))/255.0
                           alpha:alpha];
}

- (UIColor *)contrastColor {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    return [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:a];
}

@end


@implementation UIViewController (CCC_TopViewControllerAdditions)

- (UIViewController *)topViewController {
    return [[self class] topViewController:self.view.window.rootViewController];
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (!rootViewController.presentedViewController) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end


@implementation NSString (CCC_Additions)

- (BOOL)isAllDigits {
    NSCharacterSet *notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([self rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)isEmailFormat {
    if ((0 != [self rangeOfString:@"@"].length) &&
        (0 != [self rangeOfString:@"."].length)) {
        
        NSCharacterSet *tmpInvalidCharSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
        NSMutableCharacterSet *tmpInvalidMutableCharSet = [[tmpInvalidCharSet mutableCopy] autorelease];
        [tmpInvalidMutableCharSet removeCharactersInString:@"_-+"];
        
        //使用compare option 來設定比較規則，如
        //NSCaseInsensitiveSearch是不區分大小寫
        //NSLiteralSearch 進行完全比較,區分大小寫
        //NSNumericSearch 只比較定符串的個數，而不比較字符串的字面值
        NSRange range1 = [self rangeOfString:@"@"
                                     options:NSCaseInsensitiveSearch];
        
        //取得用户名部分
        NSString *userNameString = [self substringToIndex:range1.location];
        NSArray *userNameArray   = [userNameString componentsSeparatedByString:@"."];
        
        for (NSString *string in userNameArray) {
            NSRange rangeOfInavlidChars = [string rangeOfCharacterFromSet: tmpInvalidMutableCharSet];
            if (rangeOfInavlidChars.length != 0 || [string isEqualToString:@""]) {
                return NO;
            }
        }
        
        NSString *domainString = [self substringFromIndex:range1.location+1];
        NSArray *domainArray   = [domainString componentsSeparatedByString:@"."];
        
        for (NSString *string in domainArray) {
            NSRange rangeOfInavlidChars=[string rangeOfCharacterFromSet:tmpInvalidMutableCharSet];
            if (rangeOfInavlidChars.length !=0 || [string isEqualToString:@""]) {
                return NO;
            }
        }
        
        return YES;
    }
    else { // no ''@'' or ''.'' present
        return NO;
    }
}

- (BOOL)isPhoneNumberFormat {
    NSError *error = nil;
    NSDataDetector *matchdetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:&error];
    NSUInteger matchNumber = [matchdetector numberOfMatchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    if (matchNumber == 0 || error) {
        return NO;
    }
    
    return YES;
}

@end
