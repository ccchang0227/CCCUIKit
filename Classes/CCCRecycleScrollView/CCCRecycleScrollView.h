//
//  CCCRecycleScrollView.h
//
//
//  Created by CHIEN-HSU WU on 2015/2/11.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CCCRecycleScrollDirections) {
    CCCRecycleScrollDirectionHorizontal = 0,
    CCCRecycleScrollDirectionVertical
};

typedef NS_ENUM(NSInteger, CCCRecycleScrollAnimateDirections) {
    CCCRecycleScrollAnimateDirectionAuto = 0,       // scroll to nearest subView of proposed index.
    CCCRecycleScrollAnimateDirectionDescending,
    CCCRecycleScrollAnimateDirectionAscending
};


@interface CCCRecycleView : UIView

// you should add your custom views on contentView.
@property (readonly, retain, nonatomic) UIView *contentView;

@end


@protocol CCCRecycleScrollViewDelegate;
@protocol CCCRecycleScrollViewDataSource;

/**
 * A double sided scrollView
 *
 * @version 1.1.0-beta
 * @author Chih-chieh Chang
 * @date 2017-09-18
 */
@interface CCCRecycleScrollView : UIView

@property (assign, nonatomic) id<CCCRecycleScrollViewDelegate> delegate;
@property (assign, nonatomic) id<CCCRecycleScrollViewDataSource> dataSource;

@property (readonly, nonatomic) NSInteger currentIndex;
// default is CCCRecycleScrollDirectionHorizontal.
@property (assign, nonatomic) CCCRecycleScrollDirections scrollDirection;

// default is YES.
@property (assign, nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
// default is YES.
@property (assign, nonatomic, getter=isPagingEnabled) BOOL pagingEnabled;

@property (readonly, nonatomic, getter=isDragging) BOOL dragging;
@property (readonly, nonatomic, getter=isDecelerating) BOOL decelerating;

@property (assign, nonatomic) CGFloat decelerateRate;

// default is YES.
@property (assign, nonatomic) BOOL displayAnimated;

// Do not change the gestures' delegates or override the getters for these properties.
@property (readonly, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

- (void)reloadData;

- (NSInteger)numberOfSubViews;
- (CCCRecycleView *)subViewWithIndex:(NSInteger)index;
- (CGRect)rectForSubViewAtIndex:(NSInteger)index;

- (NSArray *)visibleSubViews;
- (NSArray *)indexesForVisibleSubViews;

// scroll animations

@property (readonly, nonatomic, getter=isScrolling) BOOL scrolling;

// positive value for scroll right, negative value for scroll left.
- (void)setSubViewsScrollWithDistance:(CGFloat)distance;

// pass -1 to index to scroll infinitely, only works when animated is YES.
- (void)scrollToIndex:(NSInteger)index direction:(CCCRecycleScrollAnimateDirections)direction animated:(BOOL)animated;
- (void)decelerate;
- (void)decelerateToIndex:(NSInteger)index;
- (void)stopScrollAtIndex:(NSInteger)index;
- (void)stopScroll;

@end

@protocol CCCRecycleScrollViewDelegate <NSObject>
@optional

- (void)recycleScrollViewWillBeginDragging:(CCCRecycleScrollView *)scrollView;
- (void)recycleScrollViewDidScroll:(CCCRecycleScrollView *)scrollView;
- (void)recycleScrollViewDidEndDragging:(CCCRecycleScrollView *)scrollView willDecelerate:(BOOL)decelerate;

- (void)recycleScrollViewWillBeginDecelerating:(CCCRecycleScrollView *)scrollView;
- (void)recycleScrollViewDidEndDecelerating:(CCCRecycleScrollView *)scrollView;

- (void)recycleScrollViewDidEndScrollingAnimation:(CCCRecycleScrollView *)scrollView;

- (void)recycleScrollView:(CCCRecycleScrollView *)scrollView willDisplaySubView:(CCCRecycleView *)subView atIndex:(NSInteger)index;
- (void)recycleScrollView:(CCCRecycleScrollView *)scrollView didDisplaySubView:(CCCRecycleView *)subView atIndex:(NSInteger)index;

@end

@protocol CCCRecycleScrollViewDataSource <NSObject>

- (NSInteger)numberOfSubViewsInRecycleScrollView:(CCCRecycleScrollView *)scrollView;
- (CCCRecycleView *)recycleScrollView:(CCCRecycleScrollView *)scrollView reusableView:(CCCRecycleView *)reuseView atIndex:(NSInteger)index;

@optional

- (CGSize)recycleScrollView:(CCCRecycleScrollView *)scrollView sizeOfSubViewAtIndex:(NSInteger)index;
- (CGFloat)edgeBetweenSubViewsInRecycleScrollView:(CCCRecycleScrollView *)scrollView;

@end
