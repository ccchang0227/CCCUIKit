//
//  CCCSlidingViewController.m
//  
//
//  Created by CHIEN-HSU WU on 2015/5/7.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCSlidingViewController.h"


#define kCCCDefaultBackgroundWidth 0.8


@interface CCCSlidingViewController () <UIGestureRecognizerDelegate> {
    
    CGPoint _previousPanOffset;
    
    CGRect _bounds;
    
    BOOL _isViewDidLayout;
}

@property (retain, nonatomic) UIView *mainContainerView;
@property (retain, nonatomic) UIView *backgroundContainerView;
@property (retain, nonatomic) UIView *slidingContainerView;

@property (retain, nonatomic) UIViewController *leftBackgroundViewController;
@property (assign, nonatomic) CGFloat leftBackgroundViewWidth;
@property (assign, nonatomic) CCCSlidingDisplayMode leftBackgroundViewDisplayMode;

@property (retain, nonatomic) UIViewController *rightBackgroundViewController;
@property (assign, nonatomic) CGFloat rightBackgroundViewWidth;
@property (assign, nonatomic) CCCSlidingDisplayMode rightBackgroundViewDisplayMode;

@property (retain, nonatomic) NSLayoutConstraint *constraintViewTopSpace;
@property (retain, nonatomic) NSLayoutConstraint *constraintRootViewLeading;
@property (retain, nonatomic) NSLayoutConstraint *constraintBackgroundViewWidth;
@property (retain, nonatomic) NSLayoutConstraint *constraintBackgroundViewLeading;

@end

@implementation CCCSlidingViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _bounds = CGRectZero;
    
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.view addSubview:_mainContainerView];
    [self _setupConstraints];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_rootViewController release];
    [_rootViewShadowColor release];
    [_leftBackgroundViewController release];
    [_rightBackgroundViewController release];
    [_backgroundContainerView release];
    [_slidingContainerView release];
    [_mainContainerView release];
    [_constraintViewTopSpace release];
    [_constraintRootViewLeading release];
    [_constraintBackgroundViewWidth release];
    [_constraintBackgroundViewLeading release];
    [super dealloc];
#endif
    
}

- (void)viewWillLayoutSubviews {
    _isViewDidLayout = YES;
    
    if (!CGRectEqualToRect(self.view.bounds, _bounds)) {
        [self _setupTopSpaceConstraint];
        [self _setupRootViewDisplay];
        
        _bounds = self.view.bounds;
    }
    
    if (self.view.superview) {
        self.view.clipsToBounds = YES;
        [self.view layoutSubviews];
    }
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewWillAppear:)]) {
        [self.delegate viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewDidAppear:)]) {
        [self.delegate viewDidAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewWillDisappear:)]) {
        [self.delegate viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    _isViewDidLayout = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(viewDidDisappear:)]) {
        [self.delegate viewDidDisappear:animated];
    }
}

- (BOOL)prefersStatusBarHidden {
    [UIApplication sharedApplication].statusBarHidden = NO;
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return _rootViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return _rootViewController;
}

#pragma mark - Setter

- (void)setRootViewController:(UIViewController *)rootViewController {
    if (_rootViewController != rootViewController) {
        if (_rootViewController) {
            [_rootViewController.view removeFromSuperview];
            [_rootViewController willMoveToParentViewController:nil];
            [_rootViewController removeFromParentViewController];
#if !__has_feature(objc_arc)
            [_rootViewController release];
#endif
        }
        
        _rootViewController = [rootViewController retain];
        
        if (_rootViewController) {
            [_slidingContainerView addSubview:_rootViewController.view];
            [self addChildViewController:_rootViewController];
            [_rootViewController didMoveToParentViewController:self];
        }
        
        [self _setupRootViewDisplay];
    }
    
}

- (void)setBackgroundViewController:(UIViewController *)viewController
                forSlidingDirection:(CCCSlidingDirection)direction {
    
    if (direction == CCCSlidingDirectionLeft) {
        if (_leftBackgroundViewController) {
            [_leftBackgroundViewController.view removeFromSuperview];
            [_leftBackgroundViewController willMoveToParentViewController:nil];
            [_leftBackgroundViewController removeFromParentViewController];
        }
        
        self.leftBackgroundViewController = viewController;
        if (_leftBackgroundViewController) {
            [self addChildViewController:_leftBackgroundViewController];
            [_leftBackgroundViewController didMoveToParentViewController:self];
            
            if (_leftBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
                [self _setupRootViewDisplay];
            }
        }
    }
    else if (direction == CCCSlidingDirectionRight) {
        if (_rightBackgroundViewController) {
            [_rightBackgroundViewController.view removeFromSuperview];
            [_rightBackgroundViewController willMoveToParentViewController:nil];
            [_rightBackgroundViewController removeFromParentViewController];
        }
        
        self.rightBackgroundViewController = viewController;
        if (_rightBackgroundViewController) {
            [self addChildViewController:_rightBackgroundViewController];
            [_rightBackgroundViewController didMoveToParentViewController:self];
            
            if (_rightBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
                [self _setupRootViewDisplay];
            }
        }
    }
}

- (void)setBackgroundViewWidth:(CGFloat)backgroundViewWidth
           forSlidingDirection:(CCCSlidingDirection)direction {
    
    if (direction == CCCSlidingDirectionLeft) {
        self.leftBackgroundViewWidth = ((backgroundViewWidth<0)? kCCCDefaultBackgroundWidth: backgroundViewWidth);
    }
    else if (direction == CCCSlidingDirectionRight) {
        self.rightBackgroundViewWidth = ((backgroundViewWidth<0)? kCCCDefaultBackgroundWidth: backgroundViewWidth);
    }
    
    [self _setupRootViewDisplay];
}

- (void)setBackgroundViewDisplayMode:(CCCSlidingDisplayMode)displayMode
                 forSlidingDirection:(CCCSlidingDirection)direction {
    
    if (direction == CCCSlidingDirectionLeft) {
        self.leftBackgroundViewDisplayMode = displayMode;
    }
    else if (direction == CCCSlidingDirectionRight) {
        self.rightBackgroundViewDisplayMode = displayMode;
    }
    
    [self _setupRootViewDisplay];
}

#pragma mark - Setup

- (void)_setup {
    _slidingEnabled = YES;
    
    _leftBackgroundViewWidth = kCCCDefaultBackgroundWidth;
    _rightBackgroundViewWidth = kCCCDefaultBackgroundWidth;
    _leftBackgroundViewDisplayMode = CCCSlidingDisplayModePrimaryHidden;
    _rightBackgroundViewDisplayMode = CCCSlidingDisplayModePrimaryHidden;
    
    _rootViewShadowColor = [[UIColor blackColor] copy];
    _rootViewShadowWidth = 2.0f;
    
    _mainContainerView = [[UIView alloc] init];
    _mainContainerView.backgroundColor = [UIColor clearColor];
    
    _backgroundContainerView = [[UIView alloc] init];
    _backgroundContainerView.backgroundColor = [UIColor clearColor];
    [_mainContainerView addSubview:_backgroundContainerView];
    
    _slidingContainerView = [[UIView alloc] init];
    _slidingContainerView.backgroundColor = [UIColor clearColor];
    [_mainContainerView addSubview:_slidingContainerView];
    
    _slidingContainerView.layer.shadowColor = nil;
    _slidingContainerView.layer.shadowOffset = CGSizeMake(0, 0);
    _slidingContainerView.layer.shadowOpacity = 0.0;
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_pan:)];
    panGestureRecognizer.delegate = self;
    [_slidingContainerView addGestureRecognizer:panGestureRecognizer];
    [panGestureRecognizer release];
    
    _isViewDidLayout = NO;
}

- (void)_setupConstraints {
    NSDictionary *dicViews = NSDictionaryOfVariableBindings(_mainContainerView, _slidingContainerView, _backgroundContainerView);
    
    _mainContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    _slidingContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    _backgroundContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mainContainerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
    [self.view addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_mainContainerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
    [self.view addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_slidingContainerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
    [_mainContainerView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundContainerView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
    [_mainContainerView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_slidingContainerView(==_mainContainerView)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
    [_mainContainerView addConstraints:constraints];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_slidingContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_slidingContainerView.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    [_mainContainerView addConstraint:constraint];
    self.constraintRootViewLeading = constraint;
    
    constraint = [NSLayoutConstraint constraintWithItem:_backgroundContainerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_backgroundContainerView.superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
    [_mainContainerView addConstraint:constraint];
    self.constraintBackgroundViewLeading = constraint;
    
    constraint = [NSLayoutConstraint constraintWithItem:_backgroundContainerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
    [_mainContainerView addConstraint:constraint];
    self.constraintBackgroundViewWidth = constraint;
    
}

- (void)_setupTopSpaceConstraint {
    NSMutableDictionary *dicViews = [NSMutableDictionary dictionaryWithDictionary:NSDictionaryOfVariableBindings(_mainContainerView, _slidingContainerView, _backgroundContainerView)];
    
    if (self.constraintViewTopSpace) {
        [self.view removeConstraint:self.constraintViewTopSpace];
    }
    self.constraintViewTopSpace = nil;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && !self.parentViewController && /* DISABLES CODE */ (NO)) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
        id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
        [dicViews setObject:topLayoutGuide forKey:@"topLayoutGuide"];
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][_mainContainerView]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
        [self.view addConstraints:constraints];
        if (constraints.count > 0) {
            self.constraintViewTopSpace = [constraints objectAtIndex:0];
        }
#pragma clang diagnostic pop
    }
    else {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mainContainerView]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
        [self.view addConstraints:constraints];
        if (constraints.count > 0) {
            self.constraintViewTopSpace = [constraints objectAtIndex:0];
        }
    }
}

- (void)_setupRootViewDisplay {
    if (!self.isViewLoaded) {
        return;
    }
    if (!_isViewDidLayout) {
        return;
    }
    
    [_slidingContainerView removeConstraints:_slidingContainerView.constraints];
    
    BOOL shouldDisplayLeftView = (_leftBackgroundViewController &&
                                  _leftBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible);
    BOOL shouldDisplayRightView = (_rightBackgroundViewController &&
                                   _rightBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible);
    
    NSMutableDictionary *dicViews = [NSMutableDictionary dictionaryWithCapacity:0];
    
    CGFloat rootWidth = CGRectGetWidth(self.view.bounds);
    if (shouldDisplayLeftView) {
        CGFloat width = _leftBackgroundViewWidth;
        if (width <= 1.0) {
            width *= CGRectGetWidth(self.view.bounds);
        }
        
        if (_leftBackgroundViewController.view.superview != _slidingContainerView) {
            [self _addContainerViewController:_leftBackgroundViewController
                                  onSuperview:_slidingContainerView];
        }
        _leftBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [dicViews setObject:_leftBackgroundViewController.view forKey:@"leftView"];
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[leftView(==leftWidth)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"leftWidth":@(width)} views:dicViews];
        [_slidingContainerView addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
        [_slidingContainerView addConstraints:constraints];
        
        rootWidth -= width;
    }
    
    if (shouldDisplayRightView) {
        CGFloat width = _rightBackgroundViewWidth;
        if (width <= 1.0) {
            width *= CGRectGetWidth(self.view.bounds);
        }
        
        if (_rightBackgroundViewController.view.superview != _slidingContainerView) {
            [self _addContainerViewController:_rightBackgroundViewController
                                  onSuperview:_slidingContainerView];
        }
        _rightBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [dicViews setObject:_rightBackgroundViewController.view forKey:@"rightView"];
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[rightView(==rightWidth)]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"rightWidth":@(width)} views:dicViews];
        [_slidingContainerView addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
        [_slidingContainerView addConstraints:constraints];
        
        rootWidth -= width;
    }
    
    if (_rootViewController) {
        if (_rootViewController.view.superview != _slidingContainerView) {
            [self _addContainerViewController:_rootViewController
                                  onSuperview:_slidingContainerView];
        }
        _rootViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [dicViews setObject:_rootViewController.view forKey:@"rootView"];
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rootView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
        [_slidingContainerView addConstraints:constraints];
        
        if (rootWidth >= 0) {
            NSString *formatString = [NSString stringWithFormat:@"H:%@[rootView]%@", (shouldDisplayLeftView?@"[leftView]":@"|"), (shouldDisplayRightView?@"[rightView]":@"|")];
            
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:formatString options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
            [_slidingContainerView addConstraints:constraints];
        }
        else {
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[rootView(0)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:dicViews];
            [_slidingContainerView addConstraints:constraints];
        }
    }
    
}

- (void)_addContainerViewController:(UIViewController *)viewController onSuperview:(UIView *)superview {
    if ([superview.subviews containsObject:viewController.view]) {
        return;
    }
    
    [superview addSubview:viewController.view];
}

- (void)_removeContainerViewController:(UIViewController *)viewController {
    if (!viewController.view.superview) {
        return;
    }
    
    [viewController.view removeFromSuperview];
}

#pragma mark - Show

- (void)showWithSlidingDirection:(CCCSlidingDirection)direction animated:(BOOL)animated {
    if (!self.isSlidingEnabled) {
        return;
    }
    if (self.constraintRootViewLeading.constant != 0.0) {
        return;
    }
    
    CGFloat width = kCCCDefaultBackgroundWidth;
    if (direction == CCCSlidingDirectionLeft) {
        if (!_leftBackgroundViewController ||
            _leftBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
            return;
        }
        
        width = _leftBackgroundViewWidth;
    }
    else if (direction == CCCSlidingDirectionRight) {
        if (!_rightBackgroundViewController ||
            _rightBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
            return;
        }
        
        width = _rightBackgroundViewWidth;
    }
    if (width <= 1.0) {
        width *= CGRectGetWidth(_mainContainerView.bounds);
    }
    
    if (direction == CCCSlidingDirectionLeft) {
        self.constraintBackgroundViewLeading.constant = -width/4.0;
        self.constraintBackgroundViewWidth.constant = width;
        
        [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (_leftBackgroundViewController) {
            [self _addContainerViewController:_leftBackgroundViewController
                                  onSuperview:_backgroundContainerView];
            
            _leftBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
            UIView *backgroundView = _leftBackgroundViewController.view;
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willShowBackgroundWithDirection:)]) {
                [self.delegate slidingViewController:self
                     willShowBackgroundWithDirection:CCCSlidingDirectionLeft];
            }
        }
    }
    else if (direction == CCCSlidingDirectionRight) {
        self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)-width*3/4.0;
        self.constraintBackgroundViewWidth.constant = width;
        
        [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (_rightBackgroundViewController) {
            [self _addContainerViewController:_rightBackgroundViewController
                                  onSuperview:_backgroundContainerView];
            
            _rightBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
            UIView *backgroundView = _rightBackgroundViewController.view;
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willShowBackgroundWithDirection:)]) {
                [self.delegate slidingViewController:self
                     willShowBackgroundWithDirection:CCCSlidingDirectionRight];
            }
        }
    }
    
    if (!animated) {
        _slidingContainerView.layer.shadowColor = _rootViewShadowColor.CGColor;
        _slidingContainerView.layer.shadowOpacity = 1.0;
        
        if (direction == CCCSlidingDirectionLeft) {
            self.constraintBackgroundViewLeading.constant = 0.0;
            self.constraintRootViewLeading.constant = self.constraintBackgroundViewWidth.constant;
            
            _slidingContainerView.layer.shadowOffset = CGSizeMake(-_rootViewShadowWidth, 0);
        }
        else if (direction == CCCSlidingDirectionRight) {
            self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)-width;
            self.constraintRootViewLeading.constant = -self.constraintBackgroundViewWidth.constant;
            
            _slidingContainerView.frame = CGRectMake(CGRectGetMinX(_backgroundContainerView.frame)-_slidingContainerView.frame.size.width, _slidingContainerView.frame.origin.y, _slidingContainerView.frame.size.width, _slidingContainerView.frame.size.height);
            
            _slidingContainerView.layer.shadowOffset = CGSizeMake(_rootViewShadowWidth, 0);
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didShowBackgroundWithDirection:)]) {
            [self.delegate slidingViewController:self
                  didShowBackgroundWithDirection:direction];
        }
    }
    else {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.25 animations:^ {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:animationForBackgroundAppreance:)]) {
                [self.delegate slidingViewController:self
                     animationForBackgroundAppreance:YES];
            }
            
            if (direction == CCCSlidingDirectionLeft) {
                self.constraintBackgroundViewLeading.constant = 0.0;
                self.constraintRootViewLeading.constant = self.constraintBackgroundViewWidth.constant;
            }
            else if (direction == CCCSlidingDirectionRight) {
                self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)-width;
                self.constraintRootViewLeading.constant = -self.constraintBackgroundViewWidth.constant;
            }
            [self.view layoutIfNeeded];
            
        }completion:^(BOOL finished) {
            
            if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
            
            if (finished) {
                
                _slidingContainerView.layer.shadowColor = _rootViewShadowColor.CGColor;
                _slidingContainerView.layer.shadowOpacity = 1.0;
                
                if (direction == CCCSlidingDirectionLeft) {
                    _slidingContainerView.layer.shadowOffset = CGSizeMake(-_rootViewShadowWidth, 0);
                }
                else if (direction == CCCSlidingDirectionRight) {
                    _slidingContainerView.layer.shadowOffset = CGSizeMake(_rootViewShadowWidth, 0);
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didShowBackgroundWithDirection:)]) {
                    [self.delegate slidingViewController:self
                          didShowBackgroundWithDirection:direction];
                }
            }
        }];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    if (!self.isSlidingEnabled) {
        return;
    }
    if (self.constraintRootViewLeading.constant == 0.0) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewControllerWillHideBackground:)]) {
        [self.delegate slidingViewControllerWillHideBackground:self];
    }
    
    if (!animated) {
        self.constraintBackgroundViewLeading.constant = 0.0;
        self.constraintRootViewLeading.constant = 0.0;
        
        [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        _slidingContainerView.layer.shadowColor = nil;
        _slidingContainerView.layer.shadowOffset = CGSizeMake(0, 0);
        _slidingContainerView.layer.shadowOpacity = 0.0;
        
        if (_leftBackgroundViewDisplayMode == CCCSlidingDisplayModePrimaryHidden) {
            [self _removeContainerViewController:_leftBackgroundViewController];
        }
        if (_rightBackgroundViewDisplayMode == CCCSlidingDisplayModePrimaryHidden) {
            [self _removeContainerViewController:_rightBackgroundViewController];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewControllerDidHideBackground:)]) {
            [self.delegate slidingViewControllerDidHideBackground:self];
        }
    }
    else {
        CGFloat progress = fabs(self.constraintRootViewLeading.constant)/self.constraintBackgroundViewWidth.constant;
        
        CGFloat bkX = self.constraintBackgroundViewLeading.constant;
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.25*progress animations:^ {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:animationForBackgroundAppreance:)]) {
                [self.delegate slidingViewController:self
                     animationForBackgroundAppreance:NO];
            }
            
            if (bkX <= 0.0) {
                self.constraintBackgroundViewLeading.constant = -self.constraintBackgroundViewWidth.constant/4.0;
            }
            else {
                self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)
                                                                -self.constraintBackgroundViewWidth.constant
                                                                    *3/4.0;
            }
            
            self.constraintRootViewLeading.constant = 0.0;
            [self.view layoutIfNeeded];
            
        }completion:^(BOOL finished) {
            
            if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
            
            if (finished) {
                self.constraintBackgroundViewLeading.constant = 0.0;
                [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                
                _slidingContainerView.layer.shadowColor = nil;
                _slidingContainerView.layer.shadowOffset = CGSizeMake(0, 0);
                _slidingContainerView.layer.shadowOpacity = 0.0;
                
                if (_leftBackgroundViewDisplayMode == CCCSlidingDisplayModePrimaryHidden) {
                    [self _removeContainerViewController:_leftBackgroundViewController];
                }
                if (_rightBackgroundViewDisplayMode == CCCSlidingDisplayModePrimaryHidden) {
                    [self _removeContainerViewController:_rightBackgroundViewController];
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewControllerDidHideBackground:)]) {
                    [self.delegate slidingViewControllerDidHideBackground:self];
                }
            }
        }];
    }
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewCellScrollView")] || [otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewWrapperView")]) {
        return NO;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewCellScrollView")] || [otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewWrapperView")]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewCellScrollView")] || [otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UITableViewWrapperView")]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Gesture

- (void)_pan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!self.isSlidingEnabled) {
        return;
    }
    
    CGPoint offset = gestureRecognizer.view.bounds.origin;
    offset.x -= [gestureRecognizer translationInView:gestureRecognizer.view].x;
    
    CGPoint location = [gestureRecognizer locationInView:self.view];
    if (!CGRectContainsPoint(self.view.bounds, location)) {
    }
    
    _slidingContainerView.layer.shadowColor = nil;
    _slidingContainerView.layer.shadowOffset = CGSizeMake(0, 0);
    _slidingContainerView.layer.shadowOpacity = 1.0;
    
    CGFloat rootX = self.constraintRootViewLeading.constant;
    if (offset.x < 0) {
        CGFloat width = _leftBackgroundViewWidth;
        if (width <= 1.0) {
            width *= CGRectGetWidth(_mainContainerView.bounds);
        }
        if (rootX < width) {
            rootX -= offset.x;
            if (rootX > width) {
                rootX = width;
            }
        }
        
        if (rootX > 0 &&
            (_leftBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible ||
             !_leftBackgroundViewController)) {
            rootX = 0;
        }
    }
    else if (offset.x > 0) {
        CGFloat width = _rightBackgroundViewWidth;
        if (width <= 1.0) {
            width *= CGRectGetWidth(_mainContainerView.bounds);
        }
        if (rootX > -width) {
            rootX -= offset.x;
            if (rootX < -width) {
                rootX = -width;
            }
        }
        
        if (rootX < 0 &&
            (_rightBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible ||
             !_rightBackgroundViewController)) {
            rootX = 0;
        }
    }
    self.constraintRootViewLeading.constant = rootX;
    
    if (rootX > 0) {
        [self _showBackgroundView:CCCSlidingDirectionLeft];
    }
    else if (rootX < 0) {
        [self _showBackgroundView:CCCSlidingDirectionRight];
    }
    
    CGFloat progress = fabs(rootX)/self.constraintBackgroundViewWidth.constant;
    if (rootX > 0 && self.constraintBackgroundViewWidth.constant != 0.0) {
        self.constraintBackgroundViewLeading.constant = (progress-1.0)
                                                        *self.constraintBackgroundViewWidth.constant/4.0;
    }
    else if (rootX < 0 && self.constraintBackgroundViewWidth.constant != 0.0) {
        self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)
                                                        -(3+progress)
                                                            *self.constraintBackgroundViewWidth.constant/4.0;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:interactionTransitioningWithProgress:)]) {
        [self.delegate slidingViewController:self interactionTransitioningWithProgress:progress];
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            
            if (_previousPanOffset.x > 0) {
                if (rootX > 0) {
                    [self dismissAnimated:YES];
                }
                else if (rootX < 0) {
                    [self _animateWithDirection:CCCSlidingDirectionRight];
                }
                else {
                    [self dismissAnimated:NO];
                }
            }
            else if (_previousPanOffset.x < 0) {
                if (rootX > 0) {
                    [self _animateWithDirection:CCCSlidingDirectionLeft];
                }
                else if (rootX < 0) {
                    [self dismissAnimated:YES];
                }
                else {
                    [self dismissAnimated:NO];
                }
            }
            else {
                if (rootX > self.constraintBackgroundViewWidth.constant/2.0) {
                    [self _animateWithDirection:CCCSlidingDirectionLeft];
                }
                else if (rootX > 0 && rootX <= self.constraintBackgroundViewWidth.constant/2.0) {
                    [self dismissAnimated:YES];
                }
                else if (rootX < -self.constraintBackgroundViewWidth.constant/2.0) {
                    [self _animateWithDirection:CCCSlidingDirectionRight];
                }
                else {
                    [self dismissAnimated:YES];
                }
            }
            break;
        }
        default:
            break;
    }
    _previousPanOffset = offset;
    
    [gestureRecognizer setTranslation:CGPointZero inView:gestureRecognizer.view];
}

- (void)_showBackgroundView:(CCCSlidingDirection)direction {
    CGFloat width = kCCCDefaultBackgroundWidth;
    if (direction == CCCSlidingDirectionLeft) {
        if (_leftBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
            return;
        }
        
        width = _leftBackgroundViewWidth;
    }
    else if (direction == CCCSlidingDirectionRight) {
        if (_rightBackgroundViewDisplayMode == CCCSlidingDisplayModeAlwaysVisible) {
            return;
        }
        
        width = _rightBackgroundViewWidth;
    }
    if (width <= 1.0) {
        width *= CGRectGetWidth(_mainContainerView.bounds);
    }
    
    if (direction == CCCSlidingDirectionLeft &&
        _leftBackgroundViewController.view.superview != _backgroundContainerView) {
        
        self.constraintBackgroundViewLeading.constant = -width/4.0;
        self.constraintBackgroundViewWidth.constant = width;
        
        [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (_leftBackgroundViewController) {
            [self _addContainerViewController:_leftBackgroundViewController
                                  onSuperview:_backgroundContainerView];
            
            _leftBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
            UIView *backgroundView = _leftBackgroundViewController.view;
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willShowBackgroundWithDirection:)]) {
                [self.delegate slidingViewController:self
                     willShowBackgroundWithDirection:CCCSlidingDirectionLeft];
            }
        }
    }
    else if (direction == CCCSlidingDirectionRight &&
             _rightBackgroundViewController.view.superview != _backgroundContainerView) {
        
        self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)-width*3/4.0;
        self.constraintBackgroundViewWidth.constant = width;
        
        [_backgroundContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (_rightBackgroundViewController) {
            [self _addContainerViewController:_rightBackgroundViewController
                                  onSuperview:_backgroundContainerView];
            
            _rightBackgroundViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
            UIView *backgroundView = _rightBackgroundViewController.view;
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(backgroundView)];
            [_backgroundContainerView addConstraints:constraints];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:willShowBackgroundWithDirection:)]) {
                [self.delegate slidingViewController:self
                     willShowBackgroundWithDirection:CCCSlidingDirectionRight];
            }
        }
    }
}

- (void)_animateWithDirection:(CCCSlidingDirection)direction {
    CGFloat progress = (1.0 - fabs(self.constraintRootViewLeading.constant)/self.constraintBackgroundViewWidth.constant);
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:0.25*progress animations:^ {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:animationForBackgroundAppreance:)]) {
            [self.delegate slidingViewController:self
                 animationForBackgroundAppreance:YES];
        }
        
        if (direction == CCCSlidingDirectionLeft) {
            self.constraintBackgroundViewLeading.constant = 0.0;
            self.constraintRootViewLeading.constant = self.constraintBackgroundViewWidth.constant;
        }
        else if (direction == CCCSlidingDirectionRight) {
            self.constraintBackgroundViewLeading.constant = CGRectGetWidth(_mainContainerView.bounds)
                                                            -self.constraintBackgroundViewWidth.constant;
            self.constraintRootViewLeading.constant = -self.constraintBackgroundViewWidth.constant;
        }
        [self.view layoutIfNeeded];
        
    }completion:^(BOOL finished) {
        
        if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }
        
        if (finished) {
            _slidingContainerView.layer.shadowColor = _rootViewShadowColor.CGColor;
            _slidingContainerView.layer.shadowOpacity = 1.0;
            
            if (direction == CCCSlidingDirectionLeft) {
                _slidingContainerView.layer.shadowOffset = CGSizeMake(-_rootViewShadowWidth, 0);
            }
            else if (direction == CCCSlidingDirectionRight) {
                _slidingContainerView.layer.shadowOffset = CGSizeMake(_rootViewShadowWidth, 0);
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(slidingViewController:didShowBackgroundWithDirection:)]) {
                [self.delegate slidingViewController:self
                      didShowBackgroundWithDirection:direction];
            }
        }
    }];
}

@end
