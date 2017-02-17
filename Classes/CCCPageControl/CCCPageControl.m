//
//  CCCPageControl.m
//
//  Created by freeidea on 13/10/27.
//  Copyright (c) 2013年 realtouch. All rights reserved.
//

#import "CCCPageControl.h"

UIImage *customCurrentPageImageWithColor(UIColor *strokeColor, UIColor *fillColor) {
    CGFloat dotWidth = 12.0f;
    
    UIGraphicsBeginImageContext(CGSizeMake(dotWidth, dotWidth));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddArc(ctx, dotWidth/2.0, dotWidth/2.0, dotWidth/2.0, 0, 2*M_PI, 0);
    CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);
    
    CGContextSetLineWidth(ctx, 1.0);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

UIImage *customPageImageWithColor(UIColor *strokeColor, UIColor *fillColor) {
    CGFloat dotWidth = 12.0f;
    
    UIGraphicsBeginImageContext(CGSizeMake(dotWidth, dotWidth));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddArc(ctx, dotWidth/2.0, dotWidth/2.0, dotWidth/2.0, 0, 2*M_PI, 0);
    CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, strokeColor.CGColor);
    
    CGContextSetLineWidth(ctx, 1.0);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}


#define kCCCPageControlDotWidth            6.0 // dot size width:6
#define kCCCPageControlSizeBetweenDots     10.0 // size between dots:10

@interface CCCPageControl ()

@property (assign, nonatomic) NSInteger displayedPage;
@property (retain, nonatomic) NSArray *arrayPageLayers;

- (UIImage*)defaultDotImage;
- (UIImage*)defaultDotCurrentPageImage;

@end

@implementation CCCPageControl

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame pageImage:(UIImage*)pageImage currentPageImage:(UIImage*)currentPageImage {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setup];
        
        self.pageImage = pageImage;
        self.currentPageImage = currentPageImage;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setup];
        
    }
    
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_arrayPageLayers release];
    [_currentPageImage release];
    [_pageImage release];
    [super dealloc];
#endif
    
}

- (UIImage*)defaultDotImage {
    return customPageImageWithColor([UIColor colorWithWhite:0.498 alpha:0.500], [UIColor colorWithWhite:0.498 alpha:0.500]);
}

- (UIImage*)defaultDotCurrentPageImage {
    return customCurrentPageImageWithColor([UIColor grayColor], [UIColor grayColor]);
}

#pragma mark - Setter

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    [self setupPageLayers];
}

- (void)updateConstraints {
    [super updateConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    
    [self setNeedsDisplay];
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    _numberOfPages = numberOfPages;
    
    [self setupPageLayers];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = (currentPage >= self.numberOfPages? self.numberOfPages-1: (currentPage < 0? 0: currentPage));
    
    if (self.defersCurrentPageDisplay) {
        return;
    }
    
    self.displayedPage = currentPage;
}

- (void)setDisplayedPage:(NSInteger)displayedPage {
    _displayedPage = (displayedPage >= self.numberOfPages? self.numberOfPages-1: (displayedPage < 0? 0: displayedPage));
    
    [self setupCurrentPageLayer];
}

- (void)setPageImageAlpha:(CGFloat)pageImageAlpha {
    _pageImageAlpha = pageImageAlpha;
    
    [self setupCurrentPageLayer];
}

- (void)setCurrentPageImage:(UIImage *)currentPageImage {
    if (_currentPageImage != currentPageImage) {
#if !__has_feature(objc_arc)
        [_currentPageImage release];
#endif
        _currentPageImage = [currentPageImage retain];
        
        [self setupCurrentPageLayer];
    }
}

- (void)setPageImage:(UIImage *)pageImage {
    if (_pageImage != pageImage) {
#if !__has_feature(objc_arc)
        [_pageImage release];
#endif
        _pageImage = [pageImage retain];
        
        [self setupCurrentPageLayer];
    }
}

- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage {
    _hidesForSinglePage = hidesForSinglePage;
    
    if (self.numberOfPages == 1) {
        [self.arrayPageLayers makeObjectsPerformSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:hidesForSinglePage]];
    }
}

- (void)setDefersCurrentPageDisplay:(BOOL)defersCurrentPageDisplay {
    _defersCurrentPageDisplay = defersCurrentPageDisplay;
}

- (void)updateCurrentPageDisplay {
    if (!self.defersCurrentPageDisplay) {
        return;
    }
    
    self.displayedPage = self.currentPage;
}

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount {
    CGFloat sizeWidth = pageCount*kCCCPageControlDotWidth + (pageCount-1)*kCCCPageControlSizeBetweenDots;
    
    return CGSizeMake(sizeWidth, kCCCPageControlDotWidth);
}

#pragma mark - Setup

- (void)setup {
    self.clipsToBounds = NO;
    
    self.numberOfPages = 0;
    self.currentPage = 0;
    self.displayedPage = self.currentPage;
    self.pageImageAlpha = 0.2f;
    
    self.hidesForSinglePage = NO;
    self.defersCurrentPageDisplay = NO;
    
    self.currentPageImage = nil;
    self.pageImage = nil;
}

- (void)setupPageLayers {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    CGSize size = [self sizeForNumberOfPages:self.numberOfPages];
    CGFloat originalX = (self.bounds.size.width - size.width) / 2.0;
    
    NSMutableArray *arrayDots = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i < self.numberOfPages; i ++) {
        CALayer *dotLayer = [CALayer layer];
        dotLayer.frame = CGRectMake(originalX, 0, kCCCPageControlDotWidth, self.bounds.size.height);
        dotLayer.backgroundColor = [UIColor clearColor].CGColor;
        dotLayer.opacity = self.pageImageAlpha;
        dotLayer.contents = (id)self.pageImage.CGImage;
        if (!self.pageImage) {
            dotLayer.contents = (id)self.defaultDotImage.CGImage;
        }
        dotLayer.contentsGravity = kCAGravityResizeAspect;
        [self.layer addSublayer:dotLayer];
        [arrayDots addObject:dotLayer];
        if (self.numberOfPages == 1 && self.hidesForSinglePage) {
            dotLayer.hidden = YES;
        }
        
        originalX += (kCCCPageControlDotWidth+kCCCPageControlSizeBetweenDots);
    }
    self.arrayPageLayers = arrayDots;
    
    self.currentPage = self.currentPage;
    if (self.defersCurrentPageDisplay) {
        self.displayedPage = self.displayedPage;
    }
}

- (void)setupCurrentPageLayer {
    [self.arrayPageLayers enumerateObjectsUsingBlock:^(CALayer *dotLayer, NSUInteger idx, BOOL *stop) {
        if (idx == self.displayedPage) {
            dotLayer.contents = (id)self.currentPageImage.CGImage;
            if (!self.pageImage) {
                dotLayer.contents = (id)self.defaultDotCurrentPageImage.CGImage;
            }
            dotLayer.opacity = 1.0f;
        }
        else {
            dotLayer.contents = (id)self.pageImage.CGImage;
            if (!self.pageImage) {
                dotLayer.contents = (id)self.defaultDotImage.CGImage;
            }
            dotLayer.opacity = self.pageImageAlpha;
        }
    }];
}

#pragma mark - Tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    CGPoint point = [touch locationInView:self];
    
    if (point.x < self.bounds.size.width/2.0) {
        if (self.currentPage != 0) {
            self.currentPage --;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
    else {
        if (self.currentPage != self.numberOfPages-1) {
            self.currentPage ++;
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}

@end
