//
//  RecycleScrollViewController.m
//  CCCUIKit
//
//  Created by CHIEN-HSU WU on 2015/3/25.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "RecycleScrollViewController.h"
#import <CCCUIKit/CCCRecycleScrollView.h>
#import <CCCUIKit/UIKit+CCCAdditions.h>

@interface RecycleScrollViewController () <CCCRecycleScrollViewDelegate, CCCRecycleScrollViewDataSource>

@property (weak, nonatomic) IBOutlet CCCRecycleScrollView *scrollViewHor;
@property (weak, nonatomic) IBOutlet CCCRecycleScrollView *scrollViewVer;

@property (weak, nonatomic) IBOutlet UIButton *btnPagingEnabled;
@property (weak, nonatomic) IBOutlet UIButton *btnHorScroll;
@property (weak, nonatomic) IBOutlet UIButton *btnVerScroll;

@property (strong, nonatomic) NSMutableArray *arrayItems;

@end

@implementation RecycleScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"RecycleScrollView";
    
    self.scrollViewHor.scrollDirection = CCCRecycleScrollDirectionHorizontal;
    self.scrollViewHor.clipsToBounds = YES;
    self.scrollViewHor.delegate = self;
    self.scrollViewHor.dataSource = self;
    
    self.scrollViewVer.scrollDirection = CCCRecycleScrollDirectionVertical;
    self.scrollViewVer.delegate = self;
    self.scrollViewVer.dataSource = self;
    
    self.arrayItems = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < 10; i ++) {
        [self.arrayItems addObject:@1];
    }
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
    
    self.scrollViewHor.pagingEnabled = YES;
    self.scrollViewVer.pagingEnabled = YES;
    [self.btnPagingEnabled setTitle:@"paging:On" forState:UIControlStateNormal];
    [self.btnHorScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    [self.btnVerScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    
    [self.scrollViewHor reloadData];
    [self.scrollViewVer reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.scrollViewHor.isScrolling)
        [self.scrollViewHor stopScroll];
    
    if (self.scrollViewVer.isScrolling)
        [self.scrollViewVer stopScroll];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - IBAction

- (IBAction)pagingEnableAction:(id)sender {
    self.scrollViewHor.pagingEnabled = !self.scrollViewHor.pagingEnabled;
    self.scrollViewVer.pagingEnabled = !self.scrollViewVer.pagingEnabled;
    
    if (self.scrollViewHor.pagingEnabled) {
        [self.btnPagingEnabled setTitle:@"paging:On" forState:UIControlStateNormal];
    }
    else {
        [self.btnPagingEnabled setTitle:@"paging:Off" forState:UIControlStateNormal];
    }
}

- (IBAction)horScrollAction:(id)sender {
    if (self.scrollViewHor.isDecelerating) return;
    
    if (!self.scrollViewHor.isScrolling) {
        self.scrollViewHor.scrollEnabled = NO;
        [self.scrollViewHor scrollToIndex:-1 direction:CCCRecycleScrollAnimateDirectionAuto animated:YES];
        
        [self.btnHorScroll setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else {
        [self.scrollViewHor stopScroll];
        self.scrollViewHor.scrollEnabled = YES;
        
        [self.btnHorScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    }
}

- (IBAction)horDecelerateAction:(id)sender {
    if (!self.scrollViewHor.isScrolling) return;
    if (self.scrollViewHor.isDecelerating) return;
    
    [self.scrollViewHor decelerate];
}

- (IBAction)verScrollAction:(id)sender {
    if (self.scrollViewVer.isDecelerating) return;
    
    if (!self.scrollViewVer.isScrolling) {
        self.scrollViewVer.scrollEnabled = NO;
        [self.scrollViewVer scrollToIndex:-1 direction:CCCRecycleScrollAnimateDirectionAuto animated:YES];
        
        [self.btnVerScroll setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else {
        [self.scrollViewVer stopScroll];
        self.scrollViewVer.scrollEnabled = YES;
        
        [self.btnVerScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    }
}

- (IBAction)verDecelerateAction:(id)sender {
    if (!self.scrollViewVer.isScrolling) return;
    if (self.scrollViewVer.isDecelerating) return;
    
    [self.scrollViewVer decelerate];
}

- (void)subViewSelected:(UIButton*)sender {
    NSInteger index = [sender.currentTitle integerValue];
    if ([sender.layer.name isEqualToString:@"Hor"]) {
        if (self.scrollViewHor.isScrolling) return;
        
        [self.scrollViewHor scrollToIndex:index direction:CCCRecycleScrollAnimateDirectionAuto animated:YES];
    }
    else {
        if (self.scrollViewVer.isScrolling) return;
        
        [self.scrollViewVer scrollToIndex:index direction:CCCRecycleScrollAnimateDirectionAuto animated:YES];
    }
}

#pragma mark - CCCRecycleScrollViewDataSource

- (NSInteger)numberOfSubViewsInRecycleScrollView:(CCCRecycleScrollView *)scrollView {
    return self.arrayItems.count;
}

- (CCCRecycleView*)recycleScrollView:(CCCRecycleScrollView *)scrollView reusableView:(CCCRecycleView *)reuseView atIndex:(NSInteger)index {
    
    if (reuseView == nil) {
        reuseView = [[CCCRecycleView alloc] initWithFrame:CGRectZero];
        reuseView.backgroundColor = [UIColor randomColor];
        
        UIButton *button = [[UIButton alloc] initWithFrame:reuseView.bounds];
        button.backgroundColor = [UIColor clearColor];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:35.0]];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(subViewSelected:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = 222;
        [reuseView.contentView addSubview:button];
    }
    
    UIButton *button = (UIButton*)[reuseView.contentView viewWithTag:222];
    [button setTitleColor:[reuseView.backgroundColor contrastColor] forState:UIControlStateNormal];
    [button setTitle:[NSString stringWithFormat:@"%ld", (long)index] forState:UIControlStateNormal];
    if (scrollView.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        button.layer.name = @"Hor";
    }
    else {
        button.layer.name = @"Ver";
    }
    
    return reuseView;
}

- (CGSize)recycleScrollView:(CCCRecycleScrollView *)scrollView sizeOfSubViewAtIndex:(NSInteger)index {
    if (scrollView.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        return CGSizeMake(CGRectGetHeight(scrollView.bounds), CGRectGetHeight(scrollView.bounds));
    }
    else {
        return CGSizeMake(CGRectGetWidth(scrollView.bounds), CGRectGetWidth(scrollView.bounds));
    }
}

#pragma mark - CCCRecycleScrollViewDelegate

- (void)recycleScrollViewDidEndScrollingAnimation:(CCCRecycleScrollView *)scrollView {
    scrollView.scrollEnabled = YES;
    
    if (scrollView.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        [self.btnHorScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    }
    else {
        [self.btnVerScroll setTitle:@"Scroll" forState:UIControlStateNormal];
    }
}

#pragma mark - View controller rotation methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

@end
