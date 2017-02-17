//
//  CCCCanvasColorSelectionView.m
//
//  Created by CHIEN-HSU WU on 2015/5/27.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCCanvasPaletteView.h"


NSString *const _CCCCanvasStrokeColorKey = @"CCCCanvasStrokeColorKey";
NSString *const _CCCCanvasFillColorKey = @"CCCCanvasFillColorKey";

@interface CCCCanvasPaletteView () {
    BOOL _isIBResource;
    
    NSLock *_lock;
}

@property (retain, nonatomic) UIColor *strokeColor;
@property (retain, nonatomic) UIColor *fillColor;

@end

@implementation CCCCanvasPaletteView

- (instancetype)init {
    self = [super init];
    if (self) {
        _isIBResource = NO;
        [self _setupLayout];
        
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _isIBResource = YES;
        
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_contentView release];
    [_strokeColorButton release];
    [_fillColorButton release];
    [_colorDisplayView release];
    [_defaultColorButtons release];
    [_redTitleLabel release];
    [_redComponentSlider release];
    [_redValueLabel release];
    [_greenTitleLabel release];
    [_greenComponentSlider release];
    [_greenValueLabel release];
    [_blueTitleLabel release];
    [_blueComponentSlider release];
    [_blueValueLabel release];
    [_alphaTitleLabel release];
    [_alphaComponentSlider release];
    [_alphaValueLabel release];
    [_saveButton release];
    [_cancelButton release];
    [_strokeColor release];
    [_fillColor release];
    
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
        [self _loadColor];
        
        [self _setupPaletteMode:CCCCanvasPaletteModeStroke];
    }
}

- (void)showInView:(UIView *)superview animated:(BOOL)animated {
    if (!superview) {
        return;
    }
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [superview addSubview:self];
    
    CCCCanvasPaletteView *view = self;
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

#pragma mark - setter

- (void)setSliderColorAnimatable:(BOOL)sliderColorAnimatable {
    _sliderColorAnimatable = sliderColorAnimatable;
    
    
}

#pragma mark - Static Color Methods

+ (UIColor*)colorWithHexRGB:(NSUInteger)hexRGB alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((hexRGB&0xFF0000)>>16))/255.0
                           green:((float)((hexRGB&0x00FF00)>>8))/255.0
                            blue:((float)((hexRGB&0x0000FF)>>0))/255.0
                           alpha:1.0];
}

+ (UIColor *)contrastColorWithColor:(UIColor *)color alpha:(CGFloat)alpha {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    if (alpha < 0 || alpha > 1) {
        return [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:a];
    }
    else {
        return [UIColor colorWithRed:1-r green:1-g blue:1-b alpha:alpha];
    }
}

+ (CGFloat)flexibleSizeWithOriginalSize:(CGFloat)size referenceWidth:(CGFloat)width {
    return MIN((size*(width/300.0)*0.9), size*1.5);
}

#pragma mark - Button Actions

- (IBAction)changeColorSelectionMode:(UIButton *)sender {
    [self _setupPaletteMode:sender.tag];
}

- (IBAction)selectDefaultColor:(UIButton *)sender {
    if (_currentPaletteMode == CCCCanvasPaletteModeStroke) {
        self.strokeColor = sender.backgroundColor;
    }
    else {
        self.fillColor = sender.backgroundColor;
    }
    
    [self _setupSliderValue];
}

- (IBAction)sliderValueChanged:(CCCSlider *)sender {
    [self _setupColor];
}

- (IBAction)cancelAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(paletteViewDidClose:)]) {
        [self.delegate paletteViewDidClose:self];
    }
    
    [self removeFromSuperview];
}

- (IBAction)saveAction:(id)sender {
    [self saveColorWithStrokeColor:self.strokeColor fillColor:self.fillColor];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(paletteView:didFinishSelectColorWithStrokeColor:andFillColor:)]) {
        [self.delegate paletteView:self didFinishSelectColorWithStrokeColor:self.strokeColor andFillColor:self.fillColor];
    }
    
    [self removeFromSuperview];
}

#pragma mark - Setup Functions

- (void)_setup {
    _sliderColorAnimatable = YES;
    [self _loadColor];
    
    [self _setupPaletteMode:CCCCanvasPaletteModeStroke];
}

- (void)_setupPaletteMode:(CCCCanvasPaletteModes)mode {
    _currentPaletteMode = mode;
    
    if (_currentPaletteMode == CCCCanvasPaletteModeStroke) {
        [self.strokeColorButton.superview bringSubviewToFront:self.strokeColorButton];
    }
    else {
        [self.strokeColorButton.superview bringSubviewToFront:self.fillColorButton];
    }
    
    [self _setupSliderValue];
}

- (void)_setupSliderValue {
    CGFloat r, g, b, a;
    if (_currentPaletteMode == CCCCanvasPaletteModeStroke) {
        [self.strokeColor getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        [self.fillColor getRed:&r green:&g blue:&b alpha:&a];
    }
    
    self.redComponentSlider.value = r;
    self.greenComponentSlider.value = g;
    self.blueComponentSlider.value = b;
    self.alphaComponentSlider.value = a;
    
    [self _setupColorDisplay];
    [self _setupValueText];
    [self _setupSliderColor];
}

- (void)_setupColor {
    CGFloat r = self.redComponentSlider.value;
    CGFloat g = self.greenComponentSlider.value;
    CGFloat b = self.blueComponentSlider.value;
    CGFloat a = self.alphaComponentSlider.value;
    
    if (_currentPaletteMode == CCCCanvasPaletteModeStroke) {
        self.strokeColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    else {
        self.fillColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    
    [self _setupColorDisplay];
    [self _setupValueText];
    [self _setupSliderColor];
}

- (void)_setupColorDisplay {
    self.strokeColorButton.backgroundColor = self.strokeColor;
    self.strokeColorButton.layer.borderColor = [CCCCanvasPaletteView contrastColorWithColor:self.strokeColor alpha:1.0].CGColor;
    self.fillColorButton.backgroundColor = self.fillColor;
    self.fillColorButton.layer.borderColor = [CCCCanvasPaletteView contrastColorWithColor:self.fillColor alpha:1.0].CGColor;
    
    self.colorDisplayView.backgroundColor = self.fillColor;
    self.colorDisplayView.layer.borderColor = self.strokeColor.CGColor;
}

- (void)_setupValueText {
    CGFloat r = self.redComponentSlider.value;
    CGFloat g = self.greenComponentSlider.value;
    CGFloat b = self.blueComponentSlider.value;
    CGFloat a = self.alphaComponentSlider.value;
    self.redValueLabel.text = [NSString stringWithFormat:@"%d", (int)(r*255)];
    self.greenValueLabel.text = [NSString stringWithFormat:@"%d", (int)(g*255)];
    self.blueValueLabel.text = [NSString stringWithFormat:@"%d", (int)(b*255)];
    self.alphaValueLabel.text = [NSString stringWithFormat:@"%.2f", a];
}

- (void)_setupSliderColor {
    if (_isIBResource || !self.sliderColorAnimatable) {
        return;
    }
    
    CGFloat r = self.redComponentSlider.value;
    self.redComponentSlider.sliderTrackingColors = @[[UIColor colorWithRed:r green:0 blue:0 alpha:1.0]];
    CGFloat g = self.greenComponentSlider.value;
    self.greenComponentSlider.sliderTrackingColors = @[[UIColor colorWithRed:0 green:g blue:0 alpha:1.0]];
    CGFloat b = self.blueComponentSlider.value;
    self.blueComponentSlider.sliderTrackingColors = @[[UIColor colorWithRed:0 green:0 blue:b alpha:1.0]];
    CGFloat a = self.alphaComponentSlider.value;
    self.alphaComponentSlider.sliderTrackingColors = @[[UIColor colorWithRed:0 green:0 blue:0 alpha:a]];
}

- (void)_loadColor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *dataStrokeColor = [defaults objectForKey:_CCCCanvasStrokeColorKey];
    if(dataStrokeColor != nil){
        self.strokeColor = [NSKeyedUnarchiver unarchiveObjectWithData:dataStrokeColor];
    }
    else{
        self.strokeColor = CCCCanvasDefaultStrokeColor;
    }
    
    NSData *dataFillColor = [defaults objectForKey:_CCCCanvasFillColorKey];
    if(dataFillColor != nil){
        self.fillColor = [NSKeyedUnarchiver unarchiveObjectWithData:dataFillColor];
    }
    else{
        self.fillColor = CCCCanvasDefaultFillColor;
    }
}

- (void)saveColorWithStrokeColor:(UIColor *)strokeColor fillColor:(UIColor *)fillColor {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (strokeColor) {
        self.strokeColor = strokeColor;
        
        NSData *dataStrokeColor = [NSKeyedArchiver archivedDataWithRootObject:self.strokeColor];
        [defaults setObject:dataStrokeColor forKey:_CCCCanvasStrokeColorKey];
    }
    
    if (fillColor) {
        self.fillColor = fillColor;
        
        NSData *dataFillColor = [NSKeyedArchiver archivedDataWithRootObject:self.fillColor];
        [defaults setObject:dataFillColor forKey:_CCCCanvasFillColorKey];
    }
    
    [defaults synchronize];
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

#pragma mark - Setup Layouts

- (void)_setupLayout {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    
    _contentView = [[UIView alloc] initWithFrame:CGRectZero];
    _contentView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.700];
    _contentView.layer.cornerRadius = 8.0f;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_contentView];
    
    _strokeColorButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _strokeColorButton.layer.borderWidth = 1.0f;
    _strokeColorButton.layer.borderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0].CGColor;
    _strokeColorButton.tag = CCCCanvasPaletteModeStroke;
    [_strokeColorButton addTarget:self action:@selector(changeColorSelectionMode:) forControlEvents:UIControlEventTouchUpInside];
    _strokeColorButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_strokeColorButton];
    
    _fillColorButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _fillColorButton.layer.borderWidth = 1.0f;
    _fillColorButton.layer.borderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0].CGColor;
    _fillColorButton.tag = CCCCanvasPaletteModeFill;
    [_fillColorButton addTarget:self action:@selector(changeColorSelectionMode:) forControlEvents:UIControlEventTouchUpInside];
    _fillColorButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_fillColorButton];
    
    _colorDisplayView = [[UIView alloc] initWithFrame:CGRectZero];
    _colorDisplayView.layer.borderWidth = 3.0f;
    _colorDisplayView.layer.cornerRadius = 8.0f;
    _colorDisplayView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_colorDisplayView];
    
    [self _setupDefaultColorButtons];
    
    [self _setupColorSliders];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _cancelButton.backgroundColor = [UIColor clearColor];
    [_cancelButton setImage:[self _customCancelImage] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_cancelButton];
    
    _saveButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _saveButton.backgroundColor = [UIColor clearColor];
    [_saveButton setImage:[self _customSaveImage] forState:UIControlStateNormal];
    [_saveButton addTarget:self action:@selector(saveAction:) forControlEvents:UIControlEventTouchUpInside];
    _saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_saveButton];
    
    [self _setupDefaultConstraints];
}

- (void)_setupDefaultColorButtons {
    NSMutableArray *colorButtons = [NSMutableArray arrayWithCapacity:0];
    
    NSUInteger defaultColors[] = {CCCCanvasDefaultColorBlack, CCCCanvasDefaultColorDarkGray, CCCCanvasDefaultColorGray, CCCCanvasDefaultColorLightGray, CCCCanvasDefaultColorWhite, CCCCanvasDefaultColorBrown, CCCCanvasDefaultColorMagenta, CCCCanvasDefaultColorRed, CCCCanvasDefaultColorOrange, CCCCanvasDefaultColorYellow, CCCCanvasDefaultColorGreen, CCCCanvasDefaultColorCyan, CCCCanvasDefaultColorBlue, CCCCanvasDefaultColorPurple};
    
    for (int i = 0; i < sizeof(defaultColors)/sizeof(defaultColors[0]); i ++) {
        UIButton *colorButton = [[UIButton alloc] initWithFrame:CGRectZero];
        colorButton.backgroundColor = [CCCCanvasPaletteView colorWithHexRGB:defaultColors[i] alpha:1.0];
        colorButton.tag = defaultColors[i];
        colorButton.layer.borderWidth = 1.0f;
        colorButton.layer.borderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0].CGColor;
        [colorButton addTarget:self action:@selector(selectDefaultColor:) forControlEvents:UIControlEventTouchUpInside];
        colorButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:colorButton];
        [colorButton release];
        
        [colorButtons addObject:colorButton];
    }
    
    self.defaultColorButtons = colorButtons;
    
    [self _setupDefaultColorButtonConstraints];
}

- (void)_setupColorSliders {
    // Red
    _redTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _redTitleLabel.backgroundColor = [UIColor clearColor];
    _redTitleLabel.textAlignment = NSTextAlignmentCenter;
    _redTitleLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultTitleTextSize];
    _redTitleLabel.textColor = [UIColor blackColor];
    _redTitleLabel.text = @"Red";
    _redTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_redTitleLabel];
    
    _redComponentSlider = [[CCCSlider alloc] initWithFrame:CGRectZero];
    _redComponentSlider.backgroundColor = [UIColor clearColor];
    _redComponentSlider.sliderBorderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0];
    _redComponentSlider.sliderTrackingColors = @[[UIColor redColor]];
    [_redComponentSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _redComponentSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_redComponentSlider];
    
    _redValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _redValueLabel.backgroundColor = [UIColor clearColor];
    _redValueLabel.textAlignment = NSTextAlignmentCenter;
    _redValueLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultValueTextSize];
    _redValueLabel.textColor = [UIColor blackColor];
    _redValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_redValueLabel];
    
    // Green
    _greenTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _greenTitleLabel.backgroundColor = [UIColor clearColor];
    _greenTitleLabel.textAlignment = NSTextAlignmentCenter;
    _greenTitleLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultTitleTextSize];
    _greenTitleLabel.textColor = [UIColor blackColor];
    _greenTitleLabel.text = @"Green";
    _greenTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_greenTitleLabel];
    
    _greenComponentSlider = [[CCCSlider alloc] initWithFrame:CGRectZero];
    _greenComponentSlider.backgroundColor = [UIColor clearColor];
    _greenComponentSlider.sliderBorderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0];
    _greenComponentSlider.sliderTrackingColors = @[[UIColor greenColor]];
    [_greenComponentSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _greenComponentSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_greenComponentSlider];
    
    _greenValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _greenValueLabel.backgroundColor = [UIColor clearColor];
    _greenValueLabel.textAlignment = NSTextAlignmentCenter;
    _greenValueLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultValueTextSize];
    _greenValueLabel.textColor = [UIColor blackColor];
    _greenValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_greenValueLabel];
    
    // Blue
    _blueTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _blueTitleLabel.backgroundColor = [UIColor clearColor];
    _blueTitleLabel.textAlignment = NSTextAlignmentCenter;
    _blueTitleLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultTitleTextSize];
    _blueTitleLabel.textColor = [UIColor blackColor];
    _blueTitleLabel.text = @"Blue";
    _blueTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_blueTitleLabel];
    
    _blueComponentSlider = [[CCCSlider alloc] initWithFrame:CGRectZero];
    _blueComponentSlider.backgroundColor = [UIColor clearColor];
    _blueComponentSlider.sliderBorderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0];
    _blueComponentSlider.sliderTrackingColors = @[[UIColor blueColor]];
    [_blueComponentSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _blueComponentSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_blueComponentSlider];
    
    _blueValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _blueValueLabel.backgroundColor = [UIColor clearColor];
    _blueValueLabel.textAlignment = NSTextAlignmentCenter;
    _blueValueLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultValueTextSize];
    _blueValueLabel.textColor = [UIColor blackColor];
    _blueValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_blueValueLabel];
    
    // Alpha
    _alphaTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _alphaTitleLabel.backgroundColor = [UIColor clearColor];
    _alphaTitleLabel.textAlignment = NSTextAlignmentCenter;
    _alphaTitleLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultTitleTextSize];
    _alphaTitleLabel.textColor = [UIColor blackColor];
    _alphaTitleLabel.text = @"Alpha";
    _alphaTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_alphaTitleLabel];
    
    _alphaComponentSlider = [[CCCSlider alloc] initWithFrame:CGRectZero];
    _alphaComponentSlider.backgroundColor = [UIColor clearColor];
    _alphaComponentSlider.sliderBorderColor = [CCCCanvasPaletteView contrastColorWithColor:_contentView.backgroundColor alpha:1.0];
    _alphaComponentSlider.sliderTrackingColors = @[[UIColor blackColor]];
    [_alphaComponentSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _alphaComponentSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_alphaComponentSlider];
    
    _alphaValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _alphaValueLabel.backgroundColor = [UIColor clearColor];
    _alphaValueLabel.textAlignment = NSTextAlignmentCenter;
    _alphaValueLabel.font = [UIFont boldSystemFontOfSize:CCCCanvasDefaultValueTextSize];
    _alphaValueLabel.textColor = [UIColor blackColor];
    _alphaValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_alphaValueLabel];
    
}

- (void)_setupDefaultConstraints {
    if (_isIBResource) {
        return;
    }
    
    // width=height
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_colorDisplayView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_colorDisplayView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [_contentView addConstraint:constraint];
    
    // width=height
    constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_cancelButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [_contentView addConstraint:constraint];
    
    // width=height
    constraint = [NSLayoutConstraint constraintWithItem:_saveButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_saveButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [_contentView addConstraint:constraint];
    
    // width=height
    constraint = [NSLayoutConstraint constraintWithItem:_strokeColorButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_strokeColorButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [_contentView addConstraint:constraint];
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_redTitleLabel]-[_greenTitleLabel(==_redTitleLabel)]-[_blueTitleLabel(==_redTitleLabel)]-[_alphaTitleLabel(==_redTitleLabel)]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllLeading|NSLayoutFormatAlignAllTrailing metrics:nil views:NSDictionaryOfVariableBindings(_redTitleLabel, _greenTitleLabel, _blueTitleLabel, _alphaTitleLabel)];
    [_contentView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_redComponentSlider]-[_greenComponentSlider(==_redComponentSlider)]-[_blueComponentSlider(==_redComponentSlider)]-[_alphaComponentSlider(==_redComponentSlider)]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllLeading|NSLayoutFormatAlignAllTrailing metrics:nil views:NSDictionaryOfVariableBindings(_redComponentSlider, _greenComponentSlider, _blueComponentSlider, _alphaComponentSlider)];
    [_contentView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_redValueLabel]-[_greenValueLabel(==_redValueLabel)]-[_blueValueLabel(==_redValueLabel)]-[_alphaValueLabel(==_redValueLabel)]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllLeading|NSLayoutFormatAlignAllTrailing metrics:nil views:NSDictionaryOfVariableBindings(_redValueLabel, _greenValueLabel, _blueValueLabel, _alphaValueLabel)];
    [_contentView addConstraints:constraints];
}

- (void)_setupDefaultColorButtonConstraints {
    if (_isIBResource) {
        return;
    }
    
    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableString *visualFormatHor = [NSMutableString stringWithString:@"H:"];
    NSMutableString *visualFormatVer = [NSMutableString stringWithString:@"V:"];
    UIButton *firstButton = nil;
    
    for (int i = 0; i < _defaultColorButtons.count; i ++) {
        UIButton *button = [_defaultColorButtons objectAtIndex:i];
        
        NSLayoutConstraint *constraint = nil;
        
        if (i == 0) {
            firstButton = button;
            [views setObject:button forKey:@"firstButton"];
            
            [visualFormatHor appendFormat:@"[firstButton]"];
            
            constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
            [_contentView addConstraint:constraint];
        }
        else if (i == _defaultColorButtons.count/2) {
            [views setObject:button forKey:[NSString stringWithFormat:@"button%d", i]];
            
            [visualFormatHor appendFormat:@"[button%d(==firstButton)]", i];
            
            [visualFormatVer appendFormat:@"[firstButton]-(10)-[button%d(==firstButton)]", i];
            [views setObject:firstButton forKey:@"firstButton"];
        }
        else {
            [views setObject:button forKey:[NSString stringWithFormat:@"button%d", i]];
            
            [visualFormatHor appendFormat:@"-(10)-[button%d(==firstButton)]", i];
        }
        
        if (i==_defaultColorButtons.count/2-1) {
            NSArray *constrains = [NSLayoutConstraint constraintsWithVisualFormat:visualFormatHor options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:views];
            [_contentView addConstraints:constrains];
            
            if (![visualFormatVer isEqualToString:@"V:"]) {
                NSArray *constrains = [NSLayoutConstraint constraintsWithVisualFormat:visualFormatVer options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views];
                [_contentView addConstraints:constrains];
            }
            
            [views removeAllObjects];
            [visualFormatHor setString:@"H:"];
            [visualFormatVer setString:@"V:"];
        }
        else if (i%(_defaultColorButtons.count/2) == _defaultColorButtons.count/4) {
            constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
            [_contentView addConstraint:constraint];
        }
    }
    
    if (![visualFormatHor isEqualToString:@"H:"]) {
        NSArray *constrains = [NSLayoutConstraint constraintsWithVisualFormat:visualFormatHor options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:views];
        [_contentView addConstraints:constrains];
    }
    
    if (![visualFormatVer isEqualToString:@"V:"]) {
        NSArray *constrains = [NSLayoutConstraint constraintsWithVisualFormat:visualFormatVer options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views];
        [_contentView addConstraints:constrains];
    }
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
    
    // align center x
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    // align center y
    constraint = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [self addConstraint:constraint];
    
    CGRect rectContent = self.bounds;
    
    if (self.bounds.size.width <= self.bounds.size.height) {
        CGFloat flexibleBorderWidth = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:3.0f referenceWidth:self.bounds.size.width];
        _colorDisplayView.layer.borderWidth = flexibleBorderWidth;
        
        CGFloat flexibleCornerRadius = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:8.0f referenceWidth:self.bounds.size.width];
        _colorDisplayView.layer.cornerRadius = flexibleCornerRadius;
        
        rectContent = CGRectInset(rectContent, 10, 10);
        CGFloat width = rectContent.size.height*2/3.0;
        CGFloat height = rectContent.size.width*3/2.0;
        
        if (height > rectContent.size.height) {
            height = rectContent.size.height;
        }
        else {
            width = rectContent.size.width;
        }
        rectContent.size.width = width;
        rectContent.size.height = height;
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_contentView(width)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"width":@(width)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView(height)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"height":@(height)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraint = [NSLayoutConstraint constraintWithItem:_strokeColorButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/5.0)];
        [self addConstraint:constraint];
        
        // equal width
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_strokeColorButton]-(-20)-[_fillColorButton(==_strokeColorButton)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_strokeColorButton, _fillColorButton)];
        [self addConstraints:constraints];
        
        // _strokeColorButton.maxX=_contentView.centerX+10
        constraint = [NSLayoutConstraint constraintWithItem:_strokeColorButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:10];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_colorDisplayView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/6.0)];
        [self addConstraint:constraint];
        
        // _colorDisplayView.maxX=_contentView.width-20
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fillColorButton]-(>=0)-[_colorDisplayView]-(20)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_fillColorButton, _colorDisplayView)];
        [self addConstraints:constraints];
        
        // top space AND equal height
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[_strokeColorButton]-(-20)-[_fillColorButton(==_strokeColorButton)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_strokeColorButton, _fillColorButton)];
        [self addConstraints:constraints];
        
        // align bottom
        constraint = [NSLayoutConstraint constraintWithItem:_colorDisplayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_fillColorButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/6.0)];
        [self addConstraint:constraint];
        
        CGFloat padding = self.bounds.size.width*0.3;
        // equal width AND fixed space
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelButton]-(padding)-[_saveButton(==_cancelButton)]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllCenterY metrics:@{@"padding":@(padding)} views:NSDictionaryOfVariableBindings(_cancelButton, _saveButton)];
        [self addConstraints:constraints];
        
        // bottom space
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelButton]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton)];
        [self addConstraints:constraints];
        
        constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-(padding/2.0)];
        [self addConstraint:constraint];
        
    }
    else {
        CGFloat flexibleBorderWidth = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:3.0f referenceWidth:self.bounds.size.height];
        _colorDisplayView.layer.borderWidth = flexibleBorderWidth;
        
        CGFloat flexibleCornerRadius = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:8.0f referenceWidth:self.bounds.size.height];
        _colorDisplayView.layer.cornerRadius = flexibleCornerRadius;
        
        rectContent = CGRectInset(rectContent, 10, 10);
        CGFloat width = rectContent.size.height*3/2.0;
        CGFloat height = rectContent.size.width*2/3.0;
        
        if (height > rectContent.size.height) {
            height = rectContent.size.height;
        }
        else {
            width = rectContent.size.width;
        }
        rectContent.size.width = width;
        rectContent.size.height = height;
        
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_contentView(width)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"width":@(width)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_contentView(height)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"height":@(height)} views:NSDictionaryOfVariableBindings(_contentView)];
        [self addConstraints:constraints];
        
        constraint = [NSLayoutConstraint constraintWithItem:_strokeColorButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/5.0)];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_colorDisplayView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/6.0)];
        [self addConstraint:constraint];
        
        // top space
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[_colorDisplayView]-(>=0)-[_strokeColorButton]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_colorDisplayView, _strokeColorButton)];
        [self addConstraints:constraints];
        
        // equal height
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_strokeColorButton]-(-20)-[_fillColorButton(==_strokeColorButton)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_strokeColorButton, _fillColorButton)];
        [self addConstraints:constraints];
        
        // _strokeColorButton.maxY=_contentView.centerY-10
        constraint = [NSLayoutConstraint constraintWithItem:_strokeColorButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-10];
        [self addConstraint:constraint];
        
        // leading space AND equal width
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[_strokeColorButton]-(-20)-[_fillColorButton(==_strokeColorButton)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_strokeColorButton, _fillColorButton)];
        [self addConstraints:constraints];
        
        // align leading
        constraint = [NSLayoutConstraint constraintWithItem:_colorDisplayView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_strokeColorButton attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
        [self addConstraint:constraint];
        
        constraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/6.0)];
        [self addConstraint:constraint];
        
        // equal width AND fixed space
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[_cancelButton]-(>=0)-[_saveButton(==_cancelButton)]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton, _saveButton)];
        [self addConstraints:constraints];
        
        // bottom space
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelButton]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_cancelButton)];
        [self addConstraints:constraints];
        
    }
    
    [self _setupDefaultColorButtonConstraintsOnSizeChanged:rectContent.size];
    [self _setupColorSliderConstraints:rectContent.size];
    
    [_lock unlock];
}

- (void)_setupDefaultColorButtonConstraintsOnSizeChanged:(CGSize)size {
    CGFloat width = size.width;
    CGFloat height = size.height;
    if (self.bounds.size.width <= self.bounds.size.height) {
        if (_defaultColorButtons.count > 0) {
            UIButton *firstButton = [_defaultColorButtons objectAtIndex:0];
            
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:firstButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/10.0)];
            [self addConstraint:constraint];
            
            NSArray *constrains = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fillColorButton]-(10)-[firstButton]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_fillColorButton, firstButton)];
            [self addConstraints:constrains];
        }
    }
    else {
        if (_defaultColorButtons.count > 0) {
            UIButton *firstButton = [_defaultColorButtons objectAtIndex:0];
            
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:firstButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(height/10.0)];
            [self addConstraint:constraint];
            
            firstButton = [_defaultColorButtons lastObject];
            
            constraint = [NSLayoutConstraint constraintWithItem:firstButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_saveButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
            [self addConstraint:constraint];
        }
    }
}

- (void)_setupColorSliderConstraints:(CGSize)size {
    CGFloat width = size.width;
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_redTitleLabel]-[_redComponentSlider]-[_redValueLabel]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_redTitleLabel, _redComponentSlider, _redValueLabel)];
    [self addConstraints:constraints];
    
    if (self.bounds.size.width <= self.bounds.size.height) {
        CGFloat textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultTitleTextSize referenceWidth:self.bounds.size.width];
        _redTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _greenTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _blueTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _alphaTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_redTitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/6.0)];
        [self addConstraint:constraint];
        
        textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultValueTextSize referenceWidth:self.bounds.size.width];
        _redValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _greenValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _blueValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _alphaValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
        constraint = [NSLayoutConstraint constraintWithItem:_redValueLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/10.0)];
        [self addConstraint:constraint];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[_redTitleLabel]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_redTitleLabel)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_redValueLabel]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_redValueLabel)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_alphaValueLabel]-(10)-[_saveButton]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_alphaValueLabel, _saveButton)];
        [self addConstraints:constraints];
        
        UIButton *button = [_defaultColorButtons lastObject];
        if (button) {
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-(10)-[_redTitleLabel]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(button, _redTitleLabel)];
            [self addConstraints:constraints];
        }
        else {
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_fillColorButton]-(10)-[_redTitleLabel]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_fillColorButton, _redTitleLabel)];
            [self addConstraints:constraints];
        }
        
    }
    else {
        CGFloat textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultTitleTextSize referenceWidth:self.bounds.size.height];
        _redTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _greenTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _blueTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _alphaTitleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:_redTitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/8.0)];
        [self addConstraint:constraint];
        
        textSize = [CCCCanvasPaletteView flexibleSizeWithOriginalSize:CCCCanvasDefaultValueTextSize referenceWidth:self.bounds.size.height];
        _redValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _greenValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _blueValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        _alphaValueLabel.font = [UIFont boldSystemFontOfSize:textSize];
        
        constraint = [NSLayoutConstraint constraintWithItem:_redValueLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(width/12.0)];
        [self addConstraint:constraint];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_fillColorButton]-(10)-[_redTitleLabel]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_fillColorButton, _redTitleLabel)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_redValueLabel]-(20)-|" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_redValueLabel)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[_redTitleLabel]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_redTitleLabel)];
        [self addConstraints:constraints];
        
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_alphaTitleLabel]-(30)-[_saveButton]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_alphaTitleLabel, _saveButton)];
        [self addConstraints:constraints];
        
    }
    
}

@end
