//
//  CCCCanvas.h
//
//  Created by CHIEN-HSU WU on 2015/5/19.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCCanvasPaletteView.h"
#import "CCCCanvasLineWidthSelectionView.h"

typedef NS_ENUM(NSInteger, CCCCanvasPath) {
    CCCCanvasPathPen = 0,
    CCCCanvasPathStraightLine,
    CCCCanvasPathCurveLine,
    CCCCanvasPathFillPolygon,
    CCCCanvasPathStrokePolygon,
    CCCCanvasPathFillRect,
    CCCCanvasPathStrokeRect,
    CCCCanvasPathFillEllipse,
    CCCCanvasPathStrokeEllipse,
    CCCCanvasPathEraser
};

@protocol CCCCanvasDelegate;
@class CCCCanvasPathObject;


/**
 * Custom canvas view.
 *
 * @version 1.0.0
 * @author Chih-chieh Chang
 * @date 2017-02-17
 */
@interface CCCCanvas : UIView <CCCCanvasPaletteDelegate, CCCCanvasLineWidthSelectionDelegate>

@property (assign, nonatomic) IBOutlet id<CCCCanvasDelegate> delegate;

// you should not change its delegate.
@property (retain, nonatomic) IBOutlet CCCCanvasPaletteView *paletteView;

@property (retain, nonatomic) IBOutlet CCCCanvasLineWidthSelectionView *lineWidthSelectionView;

@property (nonatomic) BOOL backgroundErasable;

@property (retain, nonatomic) UIImage *backgroundImage;

@property (copy, nonatomic) UIColor *strokeColor;
@property (copy, nonatomic) UIColor *fillColor;

@property (nonatomic) CGFloat lineWidth;

@property (assign, nonatomic) CCCCanvasPath canvasMode;

@property (readonly, nonatomic) BOOL canUndo;
@property (readonly, nonatomic) BOOL canRedo;

- (void)undo;
- (void)redo;
- (void)clear;

- (UIImage *)outputImage;

// Save & Load
@property (readonly, nonatomic) NSArray<CCCCanvasPathObject *> *paintingPaths;
- (void)restorePaintingWithPaths:(NSArray<CCCCanvasPathObject *> *)paintingPaths;

// temporary
@property (nonatomic) BOOL hasShadowEffect;

@end

@protocol CCCCanvasDelegate <NSObject>
@optional

- (void)canvasDidBeginPainting:(CCCCanvas *)canvas;
- (void)canvasIsPainting:(CCCCanvas *)canvas;
- (void)canvasDidEndPainting:(CCCCanvas *)canvas;

- (void)canvas:(CCCCanvas *)canvas didClosePaletteView:(CCCCanvasPaletteView *)paletteView;
- (void)canvas:(CCCCanvas *)canvas didCloseLineWidthSelectionView:(CCCCanvasLineWidthSelectionView *)lineWidthSelectionView;

@end


@interface CCCCanvasPathObject : NSObject <NSCopying, NSCoding>
@end
