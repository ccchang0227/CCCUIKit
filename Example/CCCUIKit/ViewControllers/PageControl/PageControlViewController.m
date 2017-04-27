//
//  PageControlViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/25.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "PageControlViewController.h"
#import <CCCUIKit/CCCPageControl.h>
#import <CCCUIKit/UIKit+CCCAdditions.h>

@interface PageControlViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet CCCPageControl *pageControl;

@end

@implementation PageControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"PageControl";
    
    self.scrollView.delegate = self;
    
    self.pageControl.pageImage = customPageImageWithColor([UIColor blackColor], [UIColor clearColor]);
    self.pageControl.pageImageAlpha = 1.0;
    self.pageControl.currentPageImage = customCurrentPageImageWithColor([UIColor blackColor], [UIColor redColor]);
    [self.pageControl addTarget:self action:@selector(pageCtrlChanged:) forControlEvents:UIControlEventValueChanged];
    
    [self setupScrollView];
    
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

#pragma mark - setup

- (void)setupScrollView {
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *previousView = nil;
    for (int i = 0; i < 10; i ++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = [UIColor randomColor];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.scrollView addSubview:view];
        
        UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        label.text = [NSString stringWithFormat:@"%d", i];
        label.textColor = [view.backgroundColor contrastColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:100];
        [view addSubview:label];
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view(==_scrollView)]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(view, _scrollView)];
        [self.scrollView addConstraints:constraints];
        
        if (previousView) {
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[previousView][view(==previousView)]-(>=0)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(previousView, view)];
            [self.scrollView addConstraints:constraints];
        }
        else {
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view(==_scrollView)]-(>=0)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(view, _scrollView)];
            [self.scrollView addConstraints:constraints];
        }
        
        previousView = view;
    }
    
    self.scrollView.pagingEnabled = YES;
    //self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds)*10, CGRectGetHeight(self.scrollView.bounds));
    
    self.pageControl.numberOfPages = 10;
    self.pageControl.currentPage = 0;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.isDragging) return;
    
    self.pageControl.currentPage = scrollView.contentOffset.x/CGRectGetWidth(scrollView.bounds);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.pageControl.currentPage = scrollView.contentOffset.x/CGRectGetWidth(scrollView.bounds);
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.pageControl.currentPage = scrollView.contentOffset.x/CGRectGetWidth(scrollView.bounds);
}

#pragma mark - PageControlAction

- (void)pageCtrlChanged:(CCCPageControl*)pageCtrl {
    [self.scrollView setContentOffset:CGPointMake(pageCtrl.currentPage*CGRectGetWidth(self.scrollView.bounds), 0) animated:YES];
}

@end
