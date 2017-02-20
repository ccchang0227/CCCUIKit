//
//  CCCSlidingViewController.h
//  
//
//  Created by CHIEN-HSU WU on 2015/5/7.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CCCSlidingDisplayMode) {
    CCCSlidingDisplayModePrimaryHidden,
    CCCSlidingDisplayModeAlwaysVisible
};

typedef NS_ENUM(NSInteger, CCCSlidingDirection) {
    CCCSlidingDirectionLeft,
    CCCSlidingDirectionRight
};

@protocol CCCSlidingViewControllerDelegate;

/**
 * Custom sliding/spilt view controller
 *
 * @version 1.0.1
 * @author Chih-chieh Chang
 * @date 2017-02-20
 */
@interface CCCSlidingViewController : UIViewController

@property (assign, nonatomic) id<CCCSlidingViewControllerDelegate> delegate;

@property (assign, nonatomic, getter=isSlidingEnabled) BOOL slidingEnabled;

// default is nil.
@property (retain, nonatomic) UIViewController *rootViewController;

// default is [UIColor blackColor]
@property (copy, nonatomic) UIColor *rootViewShadowColor;
// default is 2.0.
@property (assign, nonatomic) CGFloat rootViewShadowWidth;

- (void)setBackgroundViewController:(UIViewController *)viewController
                forSlidingDirection:(CCCSlidingDirection)direction; // both directions default is nil.
- (void)setBackgroundViewWidth:(CGFloat)backgroundViewWidth
           forSlidingDirection:(CCCSlidingDirection)direction; // both directions default is 0.8.
- (void)setBackgroundViewDisplayMode:(CCCSlidingDisplayMode)displayMode
                 forSlidingDirection:(CCCSlidingDirection)direction; // both directions default is CCCSlidingDisplayModePrimaryHidden.

- (void)showWithSlidingDirection:(CCCSlidingDirection)direction animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated;

@end

@protocol CCCSlidingViewControllerDelegate <NSObject>
@optional

- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;

- (void)slidingViewController:(CCCSlidingViewController *)viewController willShowBackgroundWithDirection:(CCCSlidingDirection)direction;
- (void)slidingViewController:(CCCSlidingViewController *)viewController didShowBackgroundWithDirection:(CCCSlidingDirection)direction;

- (void)slidingViewControllerWillHideBackground:(CCCSlidingViewController *)viewController;
- (void)slidingViewControllerDidHideBackground:(CCCSlidingViewController *)viewController;

/// If appreance is YES, means background is showing.
- (void)slidingViewController:(CCCSlidingViewController *)viewController animationForBackgroundAppreance:(BOOL)appreance;
/// progress: 0.0 to 1.0.
- (void)slidingViewController:(CCCSlidingViewController *)viewController interactionTransitioningWithProgress:(CGFloat)progress;

@end
