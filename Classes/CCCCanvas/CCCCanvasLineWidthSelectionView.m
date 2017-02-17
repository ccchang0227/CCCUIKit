//
//  CCCCanvasLineWidthSelectionView.m
//
//
//  Created by CHIEN-HSU WU on 2015/5/29.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCanvasLineWidthSelectionView.h"
#import "CCCCanvasPaletteView.h"

NSString *const _CCCCanvasLineWidthKey = @"CCCCanvasLineWidthKey";

CGFloat _CCCCanvasDefaultMinLineWidth = 1.0;
CGFloat _CCCCanvasDefaultMaxLineWidth = 10.0;

@interface CCCCanvasLineWidthSelectionView () {
    BOOL _isIBResource;
    
    NSLock *_lock;
}

@property (nonatomic) CGFloat lineWidth;

@end

@implementation CCCCanvasLineWidthSelectionView

+ (void)load {
    [super load];
    
    _CCCCanvasDefaultMinLineWidth = 1.0;
    _CCCCanvasDefaultMaxLineWidth = 10.0;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isIBResource = NO;
        [self _setupLayout];
        
        [self _setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _isIBResource = YES;
        
        [self _setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isIBResource = NO;
        [self _setupLayout];
        
        [self _setup];
    }
    
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_lineWidthDisplayColor release];
    [_contentView release];
    [_lineWidthSlider release];
    [_lineWidthValueLabel release];
    [_lineWidthDisplayImageView release];
    [_saveButton release];
    [_cancelButton release];
    
    if (_lock) {
        [_lock release];
    }
    
    [super dealloc];
#endif
    
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.superview) {
        return;
    }
    
    [self _setupConstraints];
}

- (void)layoutSubviews {
    
    if (!CGRectEqualToRect(self.frame, CGRectZero) && self.superview) {
        [self _setupConstraints];
    }
    
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    if (!self.superview) {
        return;
    }
    
    [self _setupConstraints];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview) {
        [self _loadLineWidth];
        
        [self _setupLineWidthSliderValue];
    }
}

- (void)showInView:(UIView *)superview animated:(BOOL)animated {
    if (!superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addSubview:self];
    
    CCCCanvasLineWidthSelectionView *view = self;
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(view)];
    [superview addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(view)];
    [superview addConstraints:constraints];
    
    if (animated) {
        CALayer *viewLayer = self.contentView.layer;
        CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        
        animation.duration = 0.35555555;
        animation.values = [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat:0.6],
                            [NSNumber numberWithFloat:1.1],
                            [NSNumber numberWithFloat:.9],
                            [NSNumber numberWithFloat:1],
                            nil];
        animation.keyTimes = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.0],
                              [NSNumber numberWithFloat:0.6],
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:1.0],
                              nil];
        [viewLayer addAnimation:animation forKey:@"transform.scale"];
    }
}

- (void)setLineWidthRangeFromMin:(CGFloat)min toMax:(CGFloat)max {
    _CCCCanvasDefaultMinLineWidth = min;
    _CCCCanvasDefaultMaxLineWidth = max;
    
    if (self.lineWidthSlider) {
        self.lineWidthSlider.minimumValue = min;
        self.lineWidthSlider.maximumValue = max;
        
        if (self.superview) {
            [self sliderValueChanged:self.lineWidthSlider];
        }
    }
    
}

#pragma mark - setter

- (void)setLineWidthDisplayColor:(UIColor *)lineWidthDisplayColor {
    if (_lineWidthDisplayColor != lineWidthDisplayColor) {
#if !__has_feature(objc_arc)
        [_lineWidthDisplayColor release];
#endif
        _lineWidthDisplayColor = [lineWidthDisplayColor copy];
        
        [self _setupLineWidthValue];
    }
}

#pragma mark - Button Actions

- (IBAction)sliderValueChanged:(CCCSlider *)sender {
    self.lineWidth = self.lineWidthSlider.value;
    
    [self _setupLineWidthValue];
}

- (IBAction)cancelAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(lineWidthSelectionViewDidClose:)]) {
        [self.delegate lineWidthSelectionViewDidClose:self];
    }
    
    [self removeFromSuperview];
}

- (IBAction)saveAction:(id)sender {
    [self saveLineWidthWithWidth:self.lineWidth];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(lineWidthSelectionView:didFinishSelectLineWidthWithWidth:)]) {
        [self.delegate lineWidthSelectionView:self didFinishSelectLineWidthWithWidth:self.lineWidth];
    }
    
    [self removeFromSuperview];
}

#pragma mark - Setup

- (void)_setup {
    _lineWidthDisplayColor = [[UIColor blackColor] copy];
    [self _loadLineWidth];
    
    [self _setupLineWidthSliderValue];
}

- (void)_setupLineWidthSliderValue {
    self.lineWidthSlider.value = self.lineWidth;
    
    [self _setupLineWidthValue];
}

- (void)_setupLineWidthValue {
    self.lineWidthValueLabel.text = [NSString stringWithFormat:@"%.2f", self.lineWidth];
    
    self.lineWidthDisplayImageView.image = [self _lineWidthDisplayImage];
}

- (void)_loadLineWidth {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _lineWidth = [defaults floatForKey:_CCCCanvasLineWidthKey];
    if (_lineWidth < _CCCCanvasDefaultMinLineWidth || _lineWidth > _CCCCanvasDefaultMaxLineWidth) {
        _lineWidth = _CCCCanvasDefaultMinLineWidth;
    }
}

- (void)saveLineWidthWithWidth:(CGFloat)lineWidth {
    if (_lineWidth >= _CCCCanvasDefaultMinLineWidth && _lineWidth <= _CCCCanvasDefaultMaxLineWidth) {
        self.lineWidth = lineWidth;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:self.lineWidth forKey:_CCCCanvasLineWidthKey];
        [defaults synchronize];
    }
}

- (UIImage *)_lineWidthDisplayImage {
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.lineWidthDisplayColor.CGColor);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    CGContextMoveToPoint(context, 20, 20);
    CGContextAddCurveToPoint(context, -20, 120, 110, -30, 80, 80);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)_customCancelImage {
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRoundedRect(path, &CGAffineTransformIdentity, CGRectMake(0, 0, 100, 100), 20.0, 20.0);
    CGContextAddPath(context, path);
    CGPathRelease(path);
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextMoveToPoint(context, 20, 20);
    CGContextAddLineToPoint(context, 80, 80);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextMoveToPoint(context, 80, 20);
    CGContextAddLineToPoint(context, 20, 80);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)_customSaveImage {
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRoundedRect(path, &CGAffineTransformIdentity, CGRectMake(0, 0, 100, 100), 20.0, 20.0);
    CGContextAddPath(context, path);
    CGPathRelease(path);
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextMoveToPoint(context, 20, 40);
    CGContextAddLineToPoint(context, 40, 70);
    CGContextAddLineToPoint(context, 80, 30);
    
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Setup Layout

- (void)_setupLayout {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    
    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.700];
    _contentView.layer.cornerRadius = 8.0f;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_contentView];
    
    _lineWidthSlider = [[CCCSlider alloc] init];
    _lineWidthSlider.backgroundColor = [UIColor clearColor];
    _lineWidthSlider.sliderBorderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0];
    _lineWidthSlider.sliderTrackingColors = @[[UIColor blackColor]];
    _lineWidthSlider.minimumValue = _CCCCanvasDefaultMinLineWidth;
    _lineWidthSlider.maximumValue = _CCCCanvasDefaultMaxLineWidth;
    [_lineWidthSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _lineWidthSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_lineWidthSlider];
    
    _lineWidthValueLabel = [[UILabel alloc] init];
    _lineWidthValueLabel.backgroundColor = [UIColor clearColor];
    _lineWidthValueLabel.textAlignment = NSTextAlignmentLeft;
    _lineWidthValueLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultValueTextSize];
    _lineWidthValueLabel.textColor = [UIColor blackColor];
    _lineWidthValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_lineWidthValueLabel];
    
    _lineWidthDisplayImageView = [[UIImageView alloc] init];
    _lineWidthDisplayImageView.backgroundColor = [UIColor clearColor];
    _lineWidthDisplayImageView.contentMode = UIViewContentModeScaleAspectFit;
    _lineWidthDisplayImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_lineWidthDisplayImageView];
    
    _cancelButton = [[UIButton alloc] init];
    _cancelButton.backgroundColor = [UIColor clearColor];
    [_cancelButton setImage:[self _customCancelImage] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_cancelButton];
    
    _saveButton = [[UIButton alloc] init];
    _saveButton.backgroundColor = [UIColor clearColor];
    [_saveButton setImage:[self _customSaveImage] forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
    _saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_saveButton];
    
    [self _setupConstraints];
}

- (void)_setupConstraints {
    if (_isIBResource) {
        return;
    }
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return;
    }
    
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    
    if (![_lock tryLock]) {
        return;
    }
    
    [self removeConstraints:self.constraints];
    
    // width=height
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_cancelButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    // width=height
    constraint = [NSLayoutConstraint constraintWithItem:_saveButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_saveButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    // width=height
    constraint = [NSLayoutConstraint constraintWithItem:_lineWidthDisplayImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_lineWidthDisplayImageView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    // align center x
    constraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    // align center y
    constraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_lineWidthDisplayImageView]-[_lineWidthValueLabel]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_lineWidthDisplayImageView, _lineWidthValueLabel)];
    [self addConstraints:constraints];
    
    constraint = [NSLayoutConstraint constraintWithItem:_lineWidthDisplayImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelButton][_lineWidthSlider][_saveButton]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton, _lineWidthSlider, _saveButton)];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_lineWidthValueLabel][_lineWidthSlider]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTrailing metrics:nil views:NSDictionaryOfVariableBindings(_lineWidthSlider, _lineWidthValueLabel)];
    [self addConstraints:constraints];
    
    constraint = [NSLayoutConstraint constraintWithItem:_lineWidthValueLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_lineWidthSlider attribute:NSLayoutAttributeHeight multiplier:(3/4.0) constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:_lineWidthSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[_cancelButton]-(>=0)-[_saveButton(==_cancelButton)]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton, _saveButton)];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelButton]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton)];
    [self addConstraints:constraints];
    
    if (self.bounds.size.width <= self.bounds.size.height) {
        CGSize size = CGRectInset(self.bounds, 10, 10).size;
        size.height = size.width/2.0;
        CGFloat width = size.width;
        CGFloat height = size.height;
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_contentView(width)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"width":@(width)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView(height)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"height":@(height)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraint = [NSLayoutConstraint constraintWithItem:_lineWidthSlider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/6.0)];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/6.0)];
        [self addConstraint:constraint];
        
        CGFloat textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultValueTextSize referenceWidth:self.bounds.size.width];
        _lineWidthValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
    }
    else {
        CGSize size = CGRectInset(self.bounds, 10, 50).size;
        CGFloat width = size.height*2.0;
        CGFloat height = size.width/2.0;
        if (height > size.height) {
            height = size.height;
        }
        else {
            width = size.width;
        }
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_contentView(width)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"width":@(width)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView(height)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"height":@(height)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraint = [NSLayoutConstraint constraintWithItem:_lineWidthSlider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/4.0)];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/4.0)];
        [self addConstraint:constraint];
        
        CGFloat textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultValueTextSize referenceWidth:self.bounds.size.width];
        _lineWidthValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
    }
    
    [_lock unlock];
}

@end
