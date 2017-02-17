//
//  CCCCanvasLineWidthSelectionView.h
//  
//
//  Created by CHIEN-HSU WU on 2015/5/29.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCSlider.h"

@protocol CCCCanvasLineWidthSelectionDelegate;

@interface CCCCanvasLineWidthSelectionView : UIView

@property (assign, nonatomic) IBOutlet id<CCCCanvasLineWidthSelectionDelegate> delegate;

@property (readonly, nonatomic) CGFloat lineWidth;

// default is [UIColor blackColor]
@property (copy, nonatomic) UIColor *lineWidthDisplayColor;

- (void)setLineWidthRangeFromMin:(CGFloat)min toMax:(CGFloat)max;

- (void)showInView:(UIView *)superview animated:(BOOL)animated;

- (void)saveLineWidthWithWidth:(CGFloat)lineWidth;

// -- subviews

@property (retain, nonatomic) IBOutlet UIView *contentView;

@property (retain, nonatomic) IBOutlet CCCSlider *lineWidthSlider;
@property (retain, nonatomic) IBOutlet UILabel *lineWidthValueLabel;

@property (retain, nonatomic) IBOutlet UIImageView *lineWidthDisplayImageView;

@property (retain, nonatomic) IBOutlet UIButton *saveButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;

@end

@protocol CCCCanvasLineWidthSelectionDelegate <NSObject>
@optional

- (void)lineWidthSelectionView:(CCCCanvasLineWidthSelectionView *)view didFinishSelectLineWidthWithWidth:(CGFloat)lineWidth;
- (void)lineWidthSelectionViewDidClose:(CCCCanvasLineWidthSelectionView *)view;

@end
