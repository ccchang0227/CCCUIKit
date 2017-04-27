//
//  MaskedLabelViewController.m
//  CCCUIKit
//
//  Created by CHIEN-HSU WU on 2015/3/24.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "MaskedLabelViewController.h"
#import <CCCUIKit/CCCMaskedLabel.h>

@interface MaskedLabelViewController () {
    BOOL _touchesOnLabel;
    CGPoint _currentPoint, _previousPoint;
}

@property (strong, nonatomic) CAGradientLayer *gradientLayer;
@property (weak, nonatomic) IBOutlet CCCMaskedLabel *maskedLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *labelCenterYConstraint;
@property (weak, nonatomic) IBOutlet UIButton *btnInsert;

@end

@implementation MaskedLabelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.clipsToBounds = YES;
    
    self.title = @"MaskedLabel";
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.view.bounds;
    gradientLayer.colors = @[(id)[UIColor orangeColor].CGColor, (id)[UIColor yellowColor].CGColor, (id)[UIColor greenColor].CGColor, (id)[UIColor cyanColor].CGColor, (id)[UIColor blueColor].CGColor, (id)[UIColor purpleColor].CGColor];
    gradientLayer.startPoint = CGPointMake(0, 0.5);
    gradientLayer.endPoint = CGPointMake(1, 0.5);
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    self.gradientLayer = gradientLayer;
    
    self.maskedLabel.userInteractionEnabled = YES;
    self.maskedLabel.textStroked = YES;
    self.maskedLabel.layer.borderWidth = 1.0f;
    self.maskedLabel.font = [UIFont boldSystemFontOfSize:60.0];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"Label"];
    [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(1, 3)];
    [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 1)];
    [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(4, 1)];
    [attrString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(1, 3)];
    [attrString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:NSMakeRange(0, 1)];
    [attrString addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:NSMakeRange(4, 1)];
    self.maskedLabel.attributedText = attrString;
    
    [self.maskedLabel.superview bringSubviewToFront:self.maskedLabel];
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [self.maskedLabel addGestureRecognizer:pinchGestureRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self resetAction:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    static BOOL firstInViewController = YES;
    
    if (firstInViewController) {
        UIAlertView *alertTip = [[UIAlertView alloc] initWithTitle:@"Tip" message:@"Drag label to see the effect." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertTip show];
    }
    
    firstInViewController = NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -
- (IBAction)resetAction:(id)sender {
    self.maskedLabel.transform = CGAffineTransformIdentity;
    self.maskedLabel.frame = CGRectMake(0, 0, 160, 80);
    self.maskedLabel.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2.0, CGRectGetHeight(self.view.bounds)/2.0);
    
    self.gradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.gradientLayer atIndex:0];
    self.maskedLabel.backgroundLayer = nil;
    
    [self.btnInsert setTitle:@"Insert" forState:UIControlStateNormal];
}

- (IBAction)changeDisplay:(id)sender {
    if (self.gradientLayer.superlayer == self.view.layer) {
        
        [self.gradientLayer removeFromSuperlayer];
        self.maskedLabel.backgroundLayer = self.gradientLayer;
        
        [self.btnInsert setTitle:@"Take Out" forState:UIControlStateNormal];
    }
    else {
        
        self.gradientLayer.frame = self.view.bounds;
        [self.view.layer insertSublayer:self.gradientLayer atIndex:0];
        self.maskedLabel.backgroundLayer = nil;
        
        [self.btnInsert setTitle:@"Insert" forState:UIControlStateNormal];
    }
}

- (void)pinchGesture:(UIPinchGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformScale([[gestureRecognizer view] transform], [gestureRecognizer scale], [gestureRecognizer scale]);
        [gestureRecognizer setScale:1];
    }
}

#pragma mark - UITouchEvents

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self.maskedLabel];
    
    _touchesOnLabel = NO;
    if (CGRectContainsPoint(self.maskedLabel.bounds, _currentPoint)) {
        _touchesOnLabel = YES;
    }
    
    _previousPoint = _currentPoint;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_touchesOnLabel) return;
    
    UITouch *touch = [touches anyObject];
    _currentPoint = [touch locationInView:self.maskedLabel];
    
    CGRect rect = self.maskedLabel.frame;
    rect.origin.x += (_currentPoint.x-_previousPoint.x);
    rect.origin.y += (_currentPoint.y-_previousPoint.y);
    
    self.maskedLabel.frame = rect;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark - orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    self.gradientLayer.frame = CGRectMake(0, 0, size.width, size.height);
    
}

@end
