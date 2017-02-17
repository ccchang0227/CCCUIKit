//
//  CCCCanvasColorSelectionView.h
//
//  Created by CHIEN-HSU WU on 2015/5/27.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCSlider.h"

#define CCCCanvasDefaultStrokeColor     [UIColor blackColor]
#define CCCCanvasDefaultFillColor       [UIColor blackColor]

#define CCCCanvasDefaultTitleTextSize   16.0
#define CCCCanvasDefaultValueTextSize   14.0

typedef NS_ENUM(NSUInteger, CCCCanvasDefaultColors) {
    CCCCanvasDefaultColorBlack      = 0x000000,
    CCCCanvasDefaultColorDarkGray   = 0x555555,
    CCCCanvasDefaultColorGray       = 0x929292,
    CCCCanvasDefaultColorLightGray  = 0xB8B8B8,
    CCCCanvasDefaultColorWhite      = 0xFFFFFF,
    CCCCanvasDefaultColorBrown      = 0x996633,
    CCCCanvasDefaultColorMagenta    = 0xFF00FF,
    CCCCanvasDefaultColorRed        = 0xFF0000,
    CCCCanvasDefaultColorOrange     = 0xFF7F00,
    CCCCanvasDefaultColorYellow     = 0xFFFF00,
    CCCCanvasDefaultColorGreen      = 0x00FF00,
    CCCCanvasDefaultColorCyan       = 0x00FFFF,
    CCCCanvasDefaultColorBlue       = 0x0000FF,
    CCCCanvasDefaultColorPurple     = 0x7F007F
};

typedef NS_ENUM(NSUInteger, CCCCanvasPaletteModes) {
    CCCCanvasPaletteModeStroke,
    CCCCanvasPaletteModeFill
};


@protocol CCCCanvasPaletteDelegate;


@interface CCCCanvasPaletteView : UIView {
@private
    CCCCanvasPaletteModes _currentPaletteMode;
}

@property (assign, nonatomic) IBOutlet id<CCCCanvasPaletteDelegate> delegate;

@property (readonly, nonatomic) UIColor *strokeColor;
@property (readonly, nonatomic) UIColor *fillColor;

// default is YES
@property (assign, nonatomic) BOOL sliderColorAnimatable;

+ (UIColor *)colorWithHexRGB:(NSUInteger)hexRGB alpha:(CGFloat)alpha;
+ (UIColor *)contrastColorWithColor:(UIColor *)color alpha:(CGFloat)alpha;

+ (CGFloat)flexibleSizeWithOriginalSize:(CGFloat)size referenceWidth:(CGFloat)width;

- (void)showInView:(UIView *)superview animated:(BOOL)animated;

- (void)saveColorWithStrokeColor:(UIColor *)strokeColor fillColor:(UIColor *)fillColor;

// -- subviews

@property (retain, nonatomic) IBOutlet UIView *contentView;

@property (retain, nonatomic) IBOutlet UIButton *strokeColorButton;
@property (retain, nonatomic) IBOutlet UIButton *fillColorButton;

@property (retain, nonatomic) IBOutlet UIView *colorDisplayView;

@property (retain, nonatomic) IBOutletCollection(UIButton) NSArray *defaultColorButtons;

@property (retain, nonatomic) IBOutlet UILabel *redTitleLabel;
@property (retain, nonatomic) IBOutlet CCCSlider *redComponentSlider;
@property (retain, nonatomic) IBOutlet UILabel *redValueLabel;

@property (retain, nonatomic) IBOutlet UILabel *greenTitleLabel;
@property (retain, nonatomic) IBOutlet CCCSlider *greenComponentSlider;
@property (retain, nonatomic) IBOutlet UILabel *greenValueLabel;

@property (retain, nonatomic) IBOutlet UILabel *blueTitleLabel;
@property (retain, nonatomic) IBOutlet CCCSlider *blueComponentSlider;
@property (retain, nonatomic) IBOutlet UILabel *blueValueLabel;

@property (retain, nonatomic) IBOutlet UILabel *alphaTitleLabel;
@property (retain, nonatomic) IBOutlet CCCSlider *alphaComponentSlider;
@property (retain, nonatomic) IBOutlet UILabel *alphaValueLabel;

@property (retain, nonatomic) IBOutlet UIButton *saveButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;

@end

@protocol CCCCanvasPaletteDelegate <NSObject>
@optional

- (void)paletteView:(CCCCanvasPaletteView *)view didFinishSelectColorWithStrokeColor:(UIColor *)strokeColor andFillColor:(UIColor *)fillColor;
- (void)paletteViewDidClose:(CCCCanvasPaletteView *)view;

@end
