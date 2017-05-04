//
//  DisplayImageViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/27.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "DisplayImageViewController.h"

@interface DisplayImageViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar *myToolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareAction;

@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation DisplayImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Image";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    _imageView = nil;
    _image = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configureImage];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configureZoomScale];
    
    NSLog(@"Picture take = %.3f sec.", self.executionTime);
    [self showAlertWithTitle:[NSString stringWithFormat:@"Picture take = %.3f sec.", self.executionTime] message:nil actions:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil], nil];
    
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

- (void)configureImage {
    [self.imageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.imageScrollView.maximumZoomScale = 1.0;
    self.imageScrollView.minimumZoomScale = 1.0;
    self.imageScrollView.zoomScale = 1.0;
    
    if (!self.image) {
        self.title = @"Image";
        
        return;
    }
    
    self.title = [NSString stringWithFormat:@"%ldx%ld", (long)self.image.size.width, (long)self.image.size.height];
    
    _imageView = [[UIImageView alloc] init];
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.image = self.image;
    [_imageScrollView addSubview:_imageView];
    
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_imageScrollView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_imageView]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_imageView)]];
    [_imageScrollView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_imageView)]];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.image.size.width];
    [_imageScrollView.superview addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.image.size.height];
    [_imageScrollView.superview addConstraint:constraint];
    
}

- (void)configureZoomScale {
    UIImage *image = self.image;
    if (!image) {
        return;
    }
    
    float scaleWidth = CGRectGetWidth(self.imageScrollView.frame)/image.size.width;
    float scaleHeight = CGRectGetHeight(self.imageScrollView.frame)/image.size.height;
    
    self.imageScrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
    self.imageScrollView.maximumZoomScale = MAX(scaleWidth, scaleHeight);
    self.imageScrollView.maximumZoomScale = MAX(self.imageScrollView.maximumZoomScale, 1.0);
    
    //初始化縮放比例
    [self.imageScrollView setZoomScale:self.imageScrollView.minimumZoomScale animated:YES];
    
}

#pragma mark -

- (IBAction)share:(id)sender {
    if (!self.image) {
        return;
    }
    
    
    
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (CGRectEqualToRect(scrollView.bounds, CGRectZero)) {
        return;
    }
    
    UIImageView *imageView = self.imageView;
    UIImage *image = imageView.image;
    if (!image) {
        return;
    }
    
    CGSize imageSize = CGSizeMake(image.size.width*scrollView.zoomScale, image.size.height*scrollView.zoomScale);
    //NSLog(@"%@", NSStringFromCGRect(self.imageViewPhoto.frame));
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    if (imageSize.width < CGRectGetWidth(scrollView.bounds)) {
        contentInset.left = (CGRectGetWidth(scrollView.bounds)-imageSize.width)/2.0;
        contentInset.right = contentInset.left;
    }
    
    if (imageSize.height < CGRectGetHeight(scrollView.bounds)) {
        contentInset.top = (CGRectGetHeight(scrollView.bounds)-imageSize.height)/2.0;
        contentInset.bottom = contentInset.top;
    }
    
    scrollView.contentInset = contentInset;
    
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
