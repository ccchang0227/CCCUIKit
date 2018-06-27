//
//  CCCCycleView.h
//
//  Created by realtouchapp on 2016/5/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"
#import "CCCFloatRange.h"

@protocol CCCCycleViewDelegate;
@protocol CCCCycleViewDataSource;

/**
 * A roulette view
 *
 * @version 1.1.0
 * @author Chih-chieh Chang
 * @date 2018-06-27
 */
@interface CCCCycleView : UIView <XYPieChartDelegate, XYPieChartDataSource>

@property (assign, nonatomic) id<CCCCycleViewDelegate> delegate;
@property (assign, nonatomic) id<CCCCycleViewDataSource> dataSource;

@property (readonly, retain, nonatomic) XYPieChart *pieChartView;

@property (readonly, nonatomic) CGFloat currentRotation;

@property (assign, nonatomic, getter=isDraggable) BOOL draggable;
@property (readonly, nonatomic, getter=isClockwise) BOOL clockwise;
@property (readonly, nonatomic, getter=isDragging) BOOL dragging;

/// 當前角速度
@property (readonly, nonatomic) CGFloat angularVelocity;
@property (readonly, nonatomic, getter=isRotating) BOOL rotating;

@property (assign, nonatomic, getter=isDecelerateEnabled) BOOL decelerateEnabled;
@property (readonly, nonatomic, getter=isDecelerating) BOOL decelerating;
@property (assign, nonatomic) CGFloat decelerateRate;
@property (assign, nonatomic) CGFloat totalDecelerateTime;

- (void)reloadData;
- (void)reloadSliceAtIndex:(NSInteger)index;

- (void)resetRotationAnimated:(BOOL)animated;
- (void)rotateToSliceAtIndex:(NSUInteger)index
                    animated:(BOOL)animated;
- (void)rotateToAngle:(CGFloat)angleByDegree
             animated:(BOOL)animated;

- (void)rotateInfinitelyWithVelocity:(CGFloat)velocity
                           clockwise:(BOOL)clockwise;
- (void)rotateInfinitelyByIncreasingToVelocity:(CGFloat)velocity
                                     clockwise:(BOOL)clockwise
                                    completion:(void(^)(void))handler;
- (void)rotateInfinitelyByIncreasingToVelocity:(CGFloat)velocity
                                     inSeconds:(NSTimeInterval)seconds
                                     clockwise:(BOOL)clockwise
                                    completion:(void(^)(void))handler;
- (void)decelerate;
- (void)decelerateToAngle:(CGFloat)angle;

- (void)forceStopRotating;

- (NSUInteger)indexAtRotation:(CGFloat)rotation;
- (CCCFloatRange)angleRangeAtIndex:(NSUInteger)index;

@property (readonly, nonatomic) NSUInteger numberOfSlices;
- (CGFloat)valueForSliceAtIndex:(NSUInteger)index;
/// returns float between 0~100
- (CGFloat)percentageForSliceAtIndex:(NSUInteger)index;

@end

@protocol CCCCycleViewDelegate <NSObject>
@optional

- (void)cccCycleView:(CCCCycleView*)view didSelectSliceAtIndex:(NSUInteger)index;

- (void)cccCycleView:(CCCCycleView*)view
     touchesDidBegin:(NSSet<UITouch*>*)touches
          withEvents:(UIEvent*)event;

- (void)cccCycleViewWillBeginDragging:(CCCCycleView*)view;
- (void)cccCycleView:(CCCCycleView*)view isDragging:(CGFloat)currentRotation;
- (void)cccCycleViewDidEndDragging:(CCCCycleView*)view willDecelerate:(BOOL)decelerate;
- (void)cccCycleViewDidEndDecelerating:(CCCCycleView*)view;

- (void)cccCycleView:(CCCCycleView*)view isRotating:(CGFloat)currentRotation;

@end

@protocol CCCCycleViewDataSource <NSObject>

- (NSUInteger)numberOfSlicesInCCCCycleView:(CCCCycleView*)view;
- (CGFloat)cccCycleView:(CCCCycleView*)view valueForSliceAtIndex:(NSUInteger)index;

@optional

- (UIColor*)cccCycleView:(CCCCycleView*)view colorForSliceAtIndex:(NSUInteger)index;

- (NSString*)cccCycleView:(CCCCycleView*)view textForSliceAtIndex:(NSUInteger)index;
- (UIColor*)cccCycleView:(CCCCycleView*)view textColorForSliceAtIndex:(NSUInteger)index;

- (BOOL)cccCycleView:(CCCCycleView *)view showImageForSliceAtIndex:(NSUInteger)index;
- (UIImage*)cccCycleView:(CCCCycleView*)view imageForSliceAtIndex:(NSUInteger)index;
- (UIColor*)cccCycleView:(CCCCycleView*)view imageBackgroundColorForSliceAtIndex:(NSUInteger)index;
- (UIColor*)cccCycleView:(CCCCycleView*)view imageBorderColorForSliceAtIndex:(NSUInteger)index;

@end
