//
//  CCCRecycleScrollView.m
//  
//
//  Created by CHIEN-HSU WU on 2015/2/11.
//  Copyright (c) 2015年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCRecycleScrollView.h"


#define kCCCRecycleScrollViewTimerInterval 0.03
#define kCCCRecycleScrollViewFrameDicFrameKey @"frame"
#define kCCCRecycleScrollViewFrameDicIndexKey @"index"

@interface NSThread (MainThreadExecute)

+ (void)_executeOnMainThread:(void (^)(void))block;

@end

@implementation NSThread (MainThreadExecute)

+ (void)_executeOnMainThread:(void (^)(void))block {
    if (!block) return;
    
    if ([[NSThread currentThread] isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^ {
            block();
        });
    }
}

@end


@interface CCCRecycleFrame : NSObject

+ (instancetype)frame;

@property (nonatomic) NSInteger subviewIndex;
@property (nonatomic) CGRect frame;

@end

@implementation CCCRecycleFrame

+ (instancetype)frame {
    return [[[self alloc] init] autorelease];
}

@end


@interface CCCRecycleView ()

// inner variables.

@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL willDisplay;
@property (nonatomic) BOOL didDisplay;

@end

@implementation CCCRecycleView

- (void)_setup {
    self.index = -1;
    self.willDisplay = NO;
    self.didDisplay = NO;
    
    _contentView = [[UIView alloc] init];
    _contentView.frame = self.bounds;
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self addSubview:_contentView];
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_contentView release];
    [super dealloc];
#endif
    
}

- (NSString *)description {
    NSMutableString *descriptionString = [NSMutableString stringWithString:[super description]];
    [descriptionString deleteCharactersInRange:NSMakeRange(descriptionString.length-1, 1)];
    
    [descriptionString appendFormat:@"; tag = %ld; index = %ld; center = %@>", (long)self.tag, (long)self.index, NSStringFromCGPoint(self.center)];
    
    return descriptionString;
}

@end


@interface CCCRecycleScrollView () <UIGestureRecognizerDelegate> {
    CGFloat _edge;
    NSInteger _subViewsToPreloadPerSide;
    
    CGPoint _startPoint;         // 開始拉動位置
    CGPoint _endPoint;           // 結束拉動位置
    CGPoint _scrollVelocity;     // 用來判斷拉動方向
    CGPoint _lastScrollOffset;   // 拉動速度
    CGFloat _accuracy;           // 加速度
    dispatch_source_t _decelerateTimer;
    id _userInfo;
    
    CGFloat _minimumEdge;        // 最小邊界 (在reloadData時重新計算)
    CGFloat _maximumEdge;        // 最大邊界 (在reloadData時重新計算)
    
    NSInteger _centerIndex;
    
    BOOL _shouldDecelerate;
    
    NSLock *_lock;
    
    BOOL _threadShouldStart;
    
    CGRect _currentBounds;
}

// inner variables.

@property (assign, nonatomic) NSInteger numberOfSubViews;       // 全部的view總數
@property (retain, nonatomic) NSMutableSet<CCCRecycleView *> *viewSet;            // 存放未使用的view
@property (retain, nonatomic) NSMutableArray<CCCRecycleFrame *> *arrayViewFrames;  // 存放畫面上view的frame
@property (retain, nonatomic) NSMutableArray<CCCRecycleView *> *arraySubViews;    // 存放實際在畫面上的view (按位置從左而右/從上而下 <-> 0~N-1)

/// Deprecated
+ (NSThread *)timerThread;

@end

@implementation CCCRecycleScrollView

/// Deprecated
+ (NSThread *)timerThread {
    static dispatch_once_t pred;
    static NSThread *timerThread = nil;
    
    dispatch_once(&pred, ^ {
        timerThread = [[NSThread alloc] initWithTarget:self selector:@selector(_runThread) object:nil];
        timerThread.name = @"CCCScrollViewThread";
    });
    
    return timerThread;
}

/// Deprecated
+ (void)_runThread {
    @autoreleasepool {
        CFRunLoopRun();
//        [[NSRunLoop currentRunLoop] run];
    }
}

#pragma mark -

- (void)_setup {
    self.clipsToBounds = YES;
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panGesture:)];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_panGestureRecognizer];
    
    _edge = 0;
    
    self.delegate = nil;
    self.dataSource = nil;
    
    _currentIndex = -1;
    _centerIndex = -1;
    self.scrollDirection = CCCRecycleScrollDirectionHorizontal;
    
    self.scrollEnabled = YES;
    self.pagingEnabled = YES;
    
    _dragging = NO;
    _decelerating = NO;
    
    self.decelerateRate = 40.0;
    
    self.displayAnimated = YES;
    
    self.numberOfSubViews = 0;
    self.viewSet = [NSMutableSet setWithCapacity:0];
    self.arrayViewFrames = [NSMutableArray arrayWithCapacity:0];
    self.arraySubViews = [NSMutableArray arrayWithCapacity:0];
    
    _lock = [[NSLock alloc] init];
    
    _threadShouldStart = NO;
    
    _currentBounds = self.bounds;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    
    return self;
}

- (void)dealloc {
    if (_decelerateTimer != NULL) {
        dispatch_source_cancel(_decelerateTimer);
        dispatch_release(_decelerateTimer);
    }
    _decelerateTimer = NULL;
    
    [_arrayViewFrames removeAllObjects];
    [_arraySubViews removeAllObjects];
    [_viewSet removeAllObjects];
    
#if !__has_feature(objc_arc)
    [_userInfo release];
    [_arrayViewFrames release];
    [_arraySubViews release];
    [_viewSet release];
    [_panGestureRecognizer release];
    [_lock release];
    [super dealloc];
#endif
    
}

#pragma mark - Assign

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if ([_lock tryLock]) {
        [self _resizeSubViews];
        [_lock unlock];
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _currentBounds) && CGRectEqualToRect(self.bounds, CGRectZero)) {
        _currentBounds = self.bounds;
        
        if ([_lock tryLock]) {
            [self _resizeSubViews];
            [_lock unlock];
        }
    }
    
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (!self.superview) {
        return;
    }
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    if (CGRectEqualToRect(self.bounds, _currentBounds)) {
        return;
    }
    _currentBounds = self.bounds;
    
    id userInfo = nil;
    BOOL isTimerActive = NO;
    if (_decelerateTimer) {
        isTimerActive = YES;
        userInfo = [self _stopTimer];
    }
    
    if ([_lock tryLock]) {
        [self _resizeSubViews];
        [_lock unlock];
    }
    
    if (isTimerActive) {
        if (!userInfo) {
            [self _startDecelerate];
        }
        else {
            [self _startScrollWithDirection:[userInfo integerValue]];
        }
    }
    
}

- (void)setScrollDirection:(CCCRecycleScrollDirections)scrollDirection {
    if (scrollDirection == CCCRecycleScrollDirectionHorizontal ||
        scrollDirection == CCCRecycleScrollDirectionVertical) { // ignore invalid setting.
        _scrollDirection = scrollDirection;
    }
}

- (void)setPagingEnabled:(BOOL)pagingEnabled {
    _pagingEnabled = pagingEnabled;
    
    if (pagingEnabled) {
        [self _resizeSubViews];
    }
}

#pragma mark - Getter

- (NSInteger)numberOfSubViews {
    return _numberOfSubViews;
}

- (CCCRecycleView *)subViewWithIndex:(NSInteger)index {
    if (self.arraySubViews.count == 0) {
        return nil;
    }
    
    return [self _subViewWithIndex:index searchDirection:CCCRecycleScrollAnimateDirectionAuto];
}

- (CGRect)rectForSubViewAtIndex:(NSInteger)index {
    CCCRecycleView *subView = [self subViewWithIndex:index];
    if (subView == nil) {
        return CGRectZero;
    }
    
    return subView.frame;
}

- (NSArray *)visibleSubViews {
    __block typeof(self) tempSelf = self;
    __block NSMutableArray *arrayVisibleSubViews = [NSMutableArray arrayWithCapacity:0];
    [tempSelf _enumerateObjectsInArray:tempSelf.arraySubViews withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (CGRectGetMaxX(subView.frame) > tempSelf.bounds.origin.x && CGRectGetMinX(subView.frame) < tempSelf.bounds.size.width) {
                [arrayVisibleSubViews addObject:subView];
            }
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (CGRectGetMaxY(subView.frame) > tempSelf.bounds.origin.y && CGRectGetMinY(subView.frame) < tempSelf.bounds.size.height) {
                [arrayVisibleSubViews addObject:subView];
            }
        }
    }];
    
    return arrayVisibleSubViews;
}

- (NSArray *)indexesForVisibleSubViews {
    __block typeof(self) tempSelf = self;
    __block NSMutableArray *arrayVisibleIndexes = [NSMutableArray arrayWithCapacity:0];
    [tempSelf _enumerateObjectsInArray:tempSelf.arraySubViews withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (CGRectGetMaxX(subView.frame) > tempSelf.bounds.origin.x && CGRectGetMinX(subView.frame) < tempSelf.bounds.size.width) {
                [arrayVisibleIndexes addObject:@(subView.index)];
            }
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (CGRectGetMaxY(subView.frame) > tempSelf.bounds.origin.y && CGRectGetMinY(subView.frame) < tempSelf.bounds.size.height) {
                [arrayVisibleIndexes addObject:@(subView.index)];
            }
        }
    }];
    
    return arrayVisibleIndexes;
}

#pragma mark - Index Estimation

- (NSInteger)_previousIndexOfIndex:(NSInteger)index {
    return (((index-1)<0)? (self.numberOfSubViews-1): (index-1));
}

- (NSInteger)_nextIndexOfIndex:(NSInteger)index {
    return (((index+1)>=self.numberOfSubViews)? 0: (index+1));
}

#pragma mark - Single

- (void)_relocateSubView:(CCCRecycleView *)subView usingFrame:(CGRect)frame {
    subView.frame = frame;
    
    [self _subViewDisplay:subView withIndex:subView.index];
}

- (void)_relocateSubView:(CCCRecycleView *)subView withOffset:(CGPoint)offset {
    // 重新計算frame
    CGRect rect = subView.frame;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        rect.origin.x -= offset.x;
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        rect.origin.y -= offset.y;
    }
    subView.frame = rect;
    
    [self _subViewDisplay:subView withIndex:subView.index];
}

- (void)_estimateCentralIndexWithSubView:(CCCRecycleView *)subView minimumOffset:(CGFloat *)minimumOffset estimatedIndex:(NSInteger *)estimateIndex {
    // 計算centralIndex (正中央的subView的index)
    CGFloat delta = CGFLOAT_MAX;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        delta = fabs(subView.center.x-self.bounds.size.width/2.0);
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        delta = fabs(subView.center.y-self.bounds.size.height/2.0);
    }
    if (!minimumOffset) {
        return;
    }
    
    if (delta < (*minimumOffset)) {
        (*minimumOffset) = delta;
        if (estimateIndex) {
            (*estimateIndex) = subView.index;
        }
    }
    
}

- (void)_reloadSubView:(id)viewOrFrame withIndex:(NSInteger)index {
    CGRect frame = CGRectZero;
    if ([viewOrFrame isKindOfClass:[UIView class]]) {
        frame = [(UIView*)viewOrFrame frame];
    }
    else if ([viewOrFrame isKindOfClass:[NSValue class]]) {
        frame = [viewOrFrame CGRectValue];
    }
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        if (CGRectGetMaxX(frame)-CGRectGetWidth(frame)/2.0 < _minimumEdge) {
            [self _removeSubViewAtIndex:index];
            
            CCCRecycleView *edgeSubView = [self.arraySubViews lastObject];
            [self _loadViewWithSubViewIndex:[self _nextIndexOfIndex:edgeSubView.index] atIndex:self.arraySubViews.count];
        }
        else if (CGRectGetMinX(frame)+CGRectGetWidth(frame)/2.0 > _maximumEdge) {
            [self _removeSubViewAtIndex:index];
            
            CCCRecycleView *edgeSubView = [self.arraySubViews objectAtIndex:0];
            [self _loadViewWithSubViewIndex:[self _previousIndexOfIndex:edgeSubView.index] atIndex:-1];
        }
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        if (CGRectGetMaxY(frame)-CGRectGetHeight(frame)/2.0 < _minimumEdge) {
            [self _removeSubViewAtIndex:index];
            
            CCCRecycleView *edgeSubView = [self.arraySubViews lastObject];
            [self _loadViewWithSubViewIndex:[self _nextIndexOfIndex:edgeSubView.index] atIndex:self.arraySubViews.count];
        }
        else if (CGRectGetMinY(frame)+CGRectGetHeight(frame)/2.0 > _maximumEdge) {
            [self _removeSubViewAtIndex:index];
            
            CCCRecycleView *edgeSubView = [self.arraySubViews objectAtIndex:0];
            [self _loadViewWithSubViewIndex:[self _previousIndexOfIndex:edgeSubView.index] atIndex:-1];
        }
    }
}

#pragma mark - Group

- (void)_enumerateObjectsInArray:(NSArray *)array withActions:(void(^)(id obj, NSUInteger idx, BOOL *stop))actionsBlock {
    [array enumerateObjectsUsingBlock:actionsBlock];
}

/// Deprecated
- (void)_relocateSubViewsWithOffset:(CGPoint)offset {
    __block typeof(self) tempSelf = self;
    [tempSelf _enumerateObjectsInArray:tempSelf.arraySubViews withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        [tempSelf _relocateSubView:subView withOffset:offset];
    }];
}

- (void)_estimateCentralIndex {
    __block NSInteger estimateIndex = 0;
    __block CGFloat minimumDelta = CGFLOAT_MAX;
    
    __block typeof(self) tempSelf = self;
    [tempSelf _enumerateObjectsInArray:tempSelf.arraySubViews withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        [tempSelf _estimateCentralIndexWithSubView:subView minimumOffset:&minimumDelta estimatedIndex:&estimateIndex];
    }];
    _centerIndex = estimateIndex;
}

// invoked by setFrame:
- (void)_resizeSubViews {
    if (self.arraySubViews.count == 0) {
        return;
    }
    
    CCCRecycleView *centralSubView = [self.arraySubViews objectAtIndex:self.arraySubViews.count/2];
    CGPoint delta = CGPointZero;
    __block typeof(self) tempSelf = self;
    
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        delta.x = centralSubView.center.x-self.bounds.size.width/2.0;
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        delta.y = centralSubView.center.y-self.bounds.size.height/2.0;
    }
    [self _enumerateObjectsInArray:self.arraySubViews withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        CGRect rect = subView.frame;
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            rect.origin.x -= delta.x;
            rect.size.height = tempSelf.bounds.size.height-2*rect.origin.y;
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            rect.origin.y -= delta.y;
            rect.size.width = tempSelf.bounds.size.width-2*rect.origin.x;
        }
        subView.frame = rect;
        
        CCCRecycleFrame *frameData = [CCCRecycleFrame frame];
        frameData.subviewIndex = subView.index;
        frameData.frame = rect;
        [tempSelf.arrayViewFrames replaceObjectAtIndex:idx withObject:frameData];
        
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (idx == 0) {
                _minimumEdge = CGRectGetMinX(rect);
            }
            else if (idx == tempSelf.arraySubViews.count-1) {
                _maximumEdge = CGRectGetMaxX(rect);
            }
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (idx == 0) {
                _minimumEdge = CGRectGetMinY(rect);
            }
            else if (idx == tempSelf.arraySubViews.count-1) {
                _maximumEdge = CGRectGetMaxY(rect);
            }
        }
        
        [tempSelf _subViewDisplay:subView withIndex:subView.index];
    }];
}

#pragma mark - Others

// find the nearest subView matching index by searchDirection.
- (CCCRecycleView *)_subViewWithIndex:(NSInteger)subViewIndex
                      searchDirection:(CCCRecycleScrollAnimateDirections)direction {
    
    if (direction < CCCRecycleScrollAnimateDirectionAuto ||
        direction > CCCRecycleScrollAnimateDirectionAscending) {
        direction = CCCRecycleScrollAnimateDirectionAuto;
    }
    
    if (direction == CCCRecycleScrollAnimateDirectionAuto) {
        for (NSInteger i = self.arraySubViews.count/2; i >= 0; i --) {
            CCCRecycleView *searchingSubViewLeft = [self.arraySubViews objectAtIndex:i];
            CCCRecycleView *searchingSubViewRight = [self.arraySubViews objectAtIndex:self.arraySubViews.count-1-i];
            if (searchingSubViewLeft.index == subViewIndex) {
                return searchingSubViewLeft;
            }
            else if (searchingSubViewRight.index == subViewIndex) {
                return searchingSubViewRight;
            }
        }
    }
    else {
        NSEnumerationOptions option = NSEnumerationConcurrent;
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.arraySubViews.count)];
        if (direction == CCCRecycleScrollAnimateDirectionDescending) {
            option = NSEnumerationReverse;
            indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.arraySubViews.count/2+1)];
        }
        else if (direction == CCCRecycleScrollAnimateDirectionAscending) {
            option = NSEnumerationConcurrent;
            indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.arraySubViews.count/2, self.arraySubViews.count/2+1)];
        }
        
        __block CCCRecycleView *searchedSubView = nil;
        [self.arraySubViews enumerateObjectsAtIndexes:indexSet options:option usingBlock:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
            
            if (subView.index == subViewIndex) {
                searchedSubView = subView;
                (*stop) = YES;
            }
        }];
        
        return searchedSubView;
    }
    
    return nil;
}

- (CCCRecycleView *)_subViewAtCurrentIndex {
    if (self.arraySubViews.count == 0) {
        return nil;
    }
    
    // 正中央
    CCCRecycleView *centralSubView = [self.arraySubViews objectAtIndex:self.arraySubViews.count/2];
    if (centralSubView.index == self.currentIndex) {
        return centralSubView;
    }
    
    // 中央偏左
    centralSubView = [self.arraySubViews objectAtIndex:self.arraySubViews.count/2-1];
    if (centralSubView.index == self.currentIndex) {
        return centralSubView;
    }
    
    // 中央偏右
    centralSubView = [self.arraySubViews objectAtIndex:self.arraySubViews.count/2+1];
    if (centralSubView.index == self.currentIndex) {
        return centralSubView;
    }
    
    return nil;
}

- (CCCRecycleView *)_subViewAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.arraySubViews.count) {
        return nil;
    }
    
    return [self.arraySubViews objectAtIndex:index];
}

- (NSInteger)_indexOfSubView:(CCCRecycleView *)subView {
    return [self.arraySubViews indexOfObject:subView];
}

- (CGRect)_frameValueAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.arrayViewFrames.count) {
        return CGRectZero;
    }
    
    return [self.arrayViewFrames objectAtIndex:index].frame;
}

- (NSArray *)_indexesListFromCentralIndex:(NSInteger)centralIndex withIndexLength:(NSInteger)length {
    if (centralIndex < 0 || centralIndex >= self.numberOfSubViews) {
        return nil;
    }
    
    NSMutableArray *indexesList = [NSMutableArray arrayWithCapacity:0];
    
    for (NSInteger i = -length; i <= length; i ++) {
        NSInteger index = centralIndex+i;
        while (index < 0 || index >= self.numberOfSubViews) {
            if (index < 0) {
                index += self.numberOfSubViews;
            }
            else if (index >= self.numberOfSubViews) {
                index -= self.numberOfSubViews;
            }
        }
        
        [indexesList addObject:@(index)];
    }
    
    return indexesList;
}

- (void)_subViewDisplay:(CCCRecycleView *)subView withIndex:(NSInteger)index {
    CGRect frame = subView.frame;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        if ((CGRectGetMinX(frame) < self.bounds.size.width && CGRectGetMaxX(frame) > self.bounds.size.width) || (CGRectGetMinX(frame) < self.bounds.origin.x && CGRectGetMaxX(frame) > self.bounds.origin.x)) {
            if (!subView.willDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:willDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self willDisplaySubView:subView atIndex:index];
                }
                subView.willDisplay = YES;
            }
        }
        else if (CGRectGetMinX(frame) >= self.bounds.origin.x && CGRectGetMaxX(frame) <= self.bounds.size.width) {
            if (!subView.willDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:willDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self willDisplaySubView:subView atIndex:index];
                }
                subView.willDisplay = YES;
            }
            if (!subView.didDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:didDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self didDisplaySubView:subView atIndex:index];
                }
                subView.didDisplay = YES;
            }
        }
        else if (CGRectGetMinX(frame) >= self.bounds.size.width || CGRectGetMaxX(frame) <= self.bounds.origin.x) {
            subView.willDisplay = NO;
            subView.didDisplay = NO;
        }
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        if ((CGRectGetMinY(frame) <= self.bounds.size.height && CGRectGetMaxY(frame) > self.bounds.size.height) || (CGRectGetMinY(frame) < self.bounds.origin.y && CGRectGetMaxY(frame) >= self.bounds.origin.y)) {
            if (!subView.willDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:willDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self willDisplaySubView:subView atIndex:index];
                }
                subView.willDisplay = YES;
            }
        }
        else if (CGRectGetMinY(frame) >= self.bounds.origin.y && CGRectGetMaxY(frame) <= self.bounds.size.height) {
            if (!subView.willDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:willDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self willDisplaySubView:subView atIndex:index];
                }
                subView.willDisplay = YES;
            }
            if (!subView.didDisplay) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollView:didDisplaySubView:atIndex:)]) {
                    [self.delegate recycleScrollView:self didDisplaySubView:subView atIndex:index];
                }
                subView.didDisplay = YES;
            }
        }
        else if (CGRectGetMinY(frame) >= self.bounds.size.height || CGRectGetMaxY(frame) <= self.bounds.origin.y) {
            subView.willDisplay = NO;
            subView.didDisplay = NO;
        }
    }
}

#pragma mark - Queue

- (void)_queueSubView:(CCCRecycleView *)subView {
    if (subView) {
        [self.viewSet addObject:subView];
    }
}

- (void)_queueAllSubViews {
    __block typeof(self) tempSelf = self;
    [self.arraySubViews enumerateObjectsUsingBlock:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        [tempSelf _queueSubView:subView];
    }];
}

- (CCCRecycleView *)_dequeueSubView {
    CCCRecycleView *subView = [self.viewSet anyObject];
    if (subView) {
        [self.viewSet removeObject:subView];
    }
    
    return subView;
}

#pragma mark - Calculate Frames

// return Indexes List
- (NSArray *)_calculateSubViewFramesWithCentralSubView:(CCCRecycleView *)centralSubView {
    NSMutableArray *indexesList = [NSMutableArray arrayWithObject:@(centralSubView.index)];
    NSInteger preIndex = centralSubView.index;
    NSInteger nxtIndex = centralSubView.index;
    CGRect preFrame = centralSubView.frame;
    CGRect nxtFrame = centralSubView.frame;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        while (CGRectGetMinX(preFrame) >= -1*self.bounds.size.width && CGRectGetMaxX(nxtFrame) <= 2*self.bounds.size.width) {
            if (CGRectGetMinX(preFrame) >= -1*self.bounds.size.width) {
                preIndex = [self _previousIndexOfIndex:preIndex];
                [indexesList insertObject:@(preIndex) atIndex:0];
                
                preFrame = [self _calculateSubViewFrameWithSubViewIndex:preIndex atIndex:-1];
                if (CGRectGetMinX(preFrame) < -1*self.bounds.size.width) {
                    _minimumEdge = CGRectGetMinX(preFrame);
                }
            }
            if (CGRectGetMaxX(nxtFrame) <= 2*self.bounds.size.width) {
                nxtIndex = [self _nextIndexOfIndex:nxtIndex];
                [indexesList addObject:@(nxtIndex)];
                
                nxtFrame = [self _calculateSubViewFrameWithSubViewIndex:nxtIndex atIndex:self.arrayViewFrames.count];
                if (CGRectGetMaxX(nxtFrame) > 2*self.bounds.size.width) {
                    _maximumEdge = CGRectGetMaxX(nxtFrame);
                }
            }
        }
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        while (CGRectGetMinY(preFrame) >= -1*self.bounds.size.height && CGRectGetMaxY(nxtFrame) <= 2*self.bounds.size.height) {
            if (CGRectGetMinY(preFrame) >= -1*self.bounds.size.height) {
                preIndex = [self _previousIndexOfIndex:preIndex];
                [indexesList insertObject:@(preIndex) atIndex:0];
                
                preFrame = [self _calculateSubViewFrameWithSubViewIndex:preIndex atIndex:-1];
                if (CGRectGetMinY(preFrame) < -1*self.bounds.size.height) {
                    _minimumEdge = CGRectGetMinY(preFrame);
                }
            }
            if (CGRectGetMaxY(nxtFrame) <= 2*self.bounds.size.height) {
                nxtIndex = [self _nextIndexOfIndex:nxtIndex];
                [indexesList addObject:@(nxtIndex)];
                
                nxtFrame = [self _calculateSubViewFrameWithSubViewIndex:nxtIndex atIndex:self.arrayViewFrames.count];
                if (CGRectGetMaxY(nxtFrame) > 2*self.bounds.size.height) {
                    _maximumEdge = CGRectGetMaxY(nxtFrame);
                }
            }
        }
    }
    
    return indexesList;
}

- (CGRect)_calculateSubViewFrameWithSubViewIndex:(NSInteger)subViewIndex atIndex:(NSInteger)index {
    if (self.dataSource) {
        __block typeof(self) tempSelf = self;
        __block CGSize size = self.bounds.size;
        if ([self.dataSource respondsToSelector:@selector(recycleScrollView:sizeOfSubViewAtIndex:)]) {
            [NSThread _executeOnMainThread:^ {
                size = [tempSelf.dataSource recycleScrollView:tempSelf sizeOfSubViewAtIndex:subViewIndex];
            }];
        }
        
        CGRect frame = CGRectMake(0.0, 0.0, size.width, size.height);
        if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, (self.bounds.size.height-frame.size.height)/2.0);
        }
        else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
            frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, (self.bounds.size.height-frame.size.height)/2.0);
        }
        
        NSInteger neighborIndex = (index-1<0)? ((index+1>=self.numberOfSubViews)? -1: index+1): index-1;
        CGRect neighborFrame = [self _frameValueAtIndex:neighborIndex];
        if (!CGRectEqualToRect(neighborFrame, CGRectZero)) {
            if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
                if (neighborIndex < index) {
                    frame.origin = CGPointMake(CGRectGetMaxX(neighborFrame)+_edge, (self.bounds.size.height-frame.size.height)/2.0);
                }
                else if (neighborIndex > index) {
                    frame.origin = CGPointMake(CGRectGetMinX(neighborFrame)-_edge-frame.size.width, (self.bounds.size.height-frame.size.height)/2.0);
                }
            }
            else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
                if (neighborIndex < index) {
                    frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, CGRectGetMaxY(neighborFrame)+_edge);
                }
                else if (neighborIndex > index) {
                    frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, CGRectGetMinY(neighborFrame)-_edge-frame.size.height);
                }
            }
        }
        
        CCCRecycleFrame *frameData = [CCCRecycleFrame frame];
        frameData.subviewIndex = subViewIndex;
        frameData.frame = frame;
        if (index < self.arrayViewFrames.count && index >= 0) {
            [self.arrayViewFrames insertObject:frameData atIndex:index];
        }
        else if (index < 0) {
            [self.arrayViewFrames insertObject:frameData atIndex:0];
        }
        else {
            [self.arrayViewFrames addObject:frameData];
        }
        
        return frame;
    }
    
    return CGRectZero;
}

#pragma mark - Load

- (void)_reloadSubViews {
    __block typeof(self) tempSelf = self;
    NSMutableArray *arraySubViewsTemp = [NSMutableArray arrayWithArray:self.arraySubViews];
    [tempSelf _enumerateObjectsInArray:arraySubViewsTemp withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        [tempSelf _reloadSubView:subView withIndex:idx];
    }];
}

- (CCCRecycleView *)_loadSubViewWithSubViewIndex:(NSInteger)subViewIndex frame:(CGRect)frame atIndex:(NSInteger)index {
    if (self.dataSource) {
        CCCRecycleView *dequeuedSubView = [self _dequeueSubView];
        CGRect rect = dequeuedSubView.frame;
        rect.origin = CGPointZero;
        rect.size = frame.size;
        dequeuedSubView.frame = rect;
        
        CCCRecycleView *subView = [self.dataSource recycleScrollView:self reusableView:dequeuedSubView atIndex:subViewIndex];
        if (!subView) {
            subView = [[[CCCRecycleView alloc] init] autorelease];
        }
        
        if (![subView isKindOfClass:[CCCRecycleView class]]) {
            subView = [[[CCCRecycleView alloc] init] autorelease];
            // throw這個是故意弄當掉...還是別玩好了XD
            //@throw [NSException exceptionWithName:NSGenericException reason:@"recycleScrollView:reusableView:atIndex: returns a view with invalid class." userInfo:nil];
        }
        subView.clipsToBounds = YES;
        subView.frame = frame;
        subView.index = subViewIndex;
        subView.willDisplay = NO;
        subView.didDisplay = NO;
        
        [self addSubview:subView];
        if (self.displayAnimated) {
            subView.alpha = 0.0f;
            [UIView animateWithDuration:0.3 animations:^ {
                subView.alpha = 1.0f;
            }];
        }
        else {
            subView.alpha = 1.0f;
        }
        if (index < self.arraySubViews.count && index >= 0) {
            [self.arraySubViews insertObject:subView atIndex:index];
        }
        else if (index < 0) {
            [self.arraySubViews insertObject:subView atIndex:0];
        }
        else {
            [self.arraySubViews addObject:subView];
        }
        
        [self _subViewDisplay:subView withIndex:subView.index];
        
        return subView;
    }
    
    return nil;
}

- (CCCRecycleView *)_loadViewWithSubViewIndex:(NSInteger)subViewIndex atIndex:(NSInteger)index {
    __block CGSize size = self.bounds.size;
    __block typeof(self) tempSelf = self;
    if (tempSelf.dataSource && [tempSelf.dataSource respondsToSelector:@selector(recycleScrollView:sizeOfSubViewAtIndex:)]) {
        [NSThread _executeOnMainThread:^ {
            size = [tempSelf.dataSource recycleScrollView:tempSelf sizeOfSubViewAtIndex:subViewIndex];
        }];
    }
    
    CGRect frame = CGRectZero;
    frame.size = size;
    frame.origin = CGPointZero;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, (self.bounds.size.height-frame.size.height)/2.0);
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, (self.bounds.size.height-frame.size.height)/2.0);
    }
    
    NSInteger neighborIndex = (index-1<0)? ((index+1>=self.numberOfSubViews)? -1: index+1): index-1;
    CGRect neighborFrame = [self _frameValueAtIndex:neighborIndex];
    if (!CGRectEqualToRect(neighborFrame, CGRectZero)) {
        if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (neighborIndex < index) {
                frame.origin = CGPointMake(CGRectGetMaxX(neighborFrame)+_edge, (self.bounds.size.height-frame.size.height)/2.0);
            }
            else if (neighborIndex > index) {
                frame.origin = CGPointMake(CGRectGetMinX(neighborFrame)-_edge-frame.size.width, (self.bounds.size.height-frame.size.height)/2.0);
            }
            
        }
        else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (neighborIndex < index) {
                frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, CGRectGetMaxY(neighborFrame)+_edge);
            }
            else if (neighborIndex > index) {
                frame.origin = CGPointMake((self.bounds.size.width-frame.size.width)/2.0, CGRectGetMinY(neighborFrame)-_edge-frame.size.height);
            }
        }
    }
    
    CCCRecycleFrame *frameData = [CCCRecycleFrame frame];
    frameData.subviewIndex = subViewIndex;
    frameData.frame = frame;
    if (index < self.arrayViewFrames.count && index >= 0) {
        [self.arrayViewFrames insertObject:frameData atIndex:index];
    }
    else if (index < 0) {
        [self.arrayViewFrames insertObject:frameData atIndex:0];
    }
    else {
        [self.arrayViewFrames addObject:frameData];
    }
    
    __block CCCRecycleView *subView = nil;
    [NSThread _executeOnMainThread:^ {
        subView = [tempSelf _loadSubViewWithSubViewIndex:subViewIndex frame:frame atIndex:index];
    }];
    return subView;
}

- (void)_removeSubViewAtIndex:(NSInteger)index {
    CCCRecycleView *subView = [self _subViewAtIndex:index];
    if (subView) {
        [[subView retain] autorelease];
        subView.index = -1;
        subView.willDisplay = NO;
        subView.didDisplay = NO;
        [self.arraySubViews removeObject:subView];
        [self.arrayViewFrames removeObjectAtIndex:index];
        [self _queueSubView:subView];
        
        [NSThread _executeOnMainThread:^ {
            [subView removeFromSuperview];
        }];
    }
}

- (void)_removeAllSubViewsAnimated:(BOOL)animated {
    __block typeof(self) tempSelf = self;
    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setCompletionBlock:^ {
            [tempSelf.viewSet enumerateObjectsUsingBlock:^(CCCRecycleView *subView, BOOL *stop) {
                subView.alpha = 1.0f;
                [subView removeFromSuperview];
            }];
        }];
    }
    
    [self.arraySubViews enumerateObjectsUsingBlock:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        [subView retain];
        subView.index = -1;
        subView.willDisplay = NO;
        subView.didDisplay = NO;
        subView.alpha = 0.0f;
        if (!animated) {
            [subView removeFromSuperview];
        }
    }];
    [self _queueAllSubViews];
    [self.arraySubViews removeAllObjects];
    [self.arrayViewFrames removeAllObjects];
    
    if (animated) {
        [CATransaction commit];
    }
}

- (void)_clearData {
    [self.arraySubViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.arraySubViews removeAllObjects];
    [self.arrayViewFrames removeAllObjects];
    [self.viewSet removeAllObjects];
    self.numberOfSubViews = 0;
    _edge = 0;
    _subViewsToPreloadPerSide = 2;
    
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        _minimumEdge = CGRectGetMinX(self.bounds);
        _maximumEdge = CGRectGetMaxX(self.bounds);
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        _minimumEdge = CGRectGetMinY(self.bounds);
        _maximumEdge = CGRectGetMaxY(self.bounds);
    }
}

- (void)reloadData {
    if (![_lock tryLock]) {
        return;
    }
    
    [self _clearData];
    if (self.dataSource) {
        self.numberOfSubViews = [self.dataSource numberOfSubViewsInRecycleScrollView:self];
        if (self.numberOfSubViews == 0) {
            _currentIndex = -1;
        }
        else if (self.currentIndex < 0 || self.currentIndex >= self.numberOfSubViews) {
            _currentIndex = 0;
        }
        
        _centerIndex = self.currentIndex;
        
        if ([self.dataSource respondsToSelector:@selector(edgeBetweenSubViewsInRecycleScrollView:)]) {
            _edge = [self.dataSource edgeBetweenSubViewsInRecycleScrollView:self];
        }
        
        [self _loadSubViewLayouts];
    }
}

- (void)_loadSubViewLayouts {
    if (self.numberOfSubViews == 0) {
        [_lock unlock];
        return;
    }
    
    NSInteger index = self.currentIndex;
    CCCRecycleView *subViewCenter = [self _loadViewWithSubViewIndex:index atIndex:self.arraySubViews.count/2];
    
    [self _loadSubViewsWithCentralSubView:subViewCenter];
}

- (void)_loadSubViewsWithCentralSubView:(CCCRecycleView *)centralSubView {
    __block typeof(self) tempSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
        NSArray *indexesList = [tempSelf _calculateSubViewFramesWithCentralSubView:centralSubView];
        /*
        [tempSelf.arrayViewFrames enumerateObjectsUsingBlock:^(NSValue *frameValue, NSUInteger i, BOOL *stop) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                NSValue *frameValue = [tempSelf.arrayViewFrames objectAtIndex:i];
                NSArray *filteredArray = [tempSelf.arraySubViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.frame=%@", frameValue]];
                if (filteredArray.count == 0) {
                    NSInteger subViewIndex = [[indexesList objectAtIndex:i] integerValue];
                    [tempSelf loadSubViewWithSubViewIndex:subViewIndex frame:[frameValue CGRectValue] atIndex:i];
                }
            });
        }];
        //*/
        //*
        dispatch_apply(tempSelf.arrayViewFrames.count, dispatch_get_main_queue(), ^(size_t i) {
            CGRect frame = [tempSelf.arrayViewFrames objectAtIndex:i].frame;
            NSValue *frameValue = [NSValue valueWithCGRect:frame];
            NSArray *filteredArray = [tempSelf.arraySubViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.frame=%@", frameValue]];
            if (filteredArray.count == 0) {
                NSInteger subViewIndex = [[indexesList objectAtIndex:i] integerValue];
                [tempSelf _loadSubViewWithSubViewIndex:subViewIndex frame:frame atIndex:i];
            }
        });
        //*/
        dispatch_async(dispatch_get_main_queue(), ^ {
            [tempSelf _resizeSubViews];
            [_lock unlock];
        });
    });
}

#pragma mark - Stop Timer

- (id)_stopTimer {
    _dragging = NO;
    _decelerating = NO;
    _scrolling = NO;
    
    id userInfo = _userInfo;
    if (_decelerateTimer != NULL) {
        //userInfo = [_decelerateTimer userInfo];
        
        dispatch_source_cancel(_decelerateTimer);
        dispatch_release(_decelerateTimer);
    }
    _decelerateTimer = NULL;
    
    _threadShouldStart = NO;
    
    return userInfo;
}

#pragma mark - Scroll Animations

- (void)setSubViewsScrollWithDistance:(CGFloat)distance {
    
    CGPoint offset = CGPointMake(-distance, -distance);
    __block NSInteger estimateIndex = 0;
    __block CGFloat minimumDelta = CGFLOAT_MAX;
    __block typeof(self) tempSelf = self;
    NSMutableArray *arrayFramesTemp = [NSMutableArray arrayWithArray:self.arrayViewFrames];
    [self _enumerateObjectsInArray:arrayFramesTemp withActions:^(CCCRecycleFrame *frameData, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = frameData.frame;
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            frame.origin.x -= offset.x;
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            frame.origin.y -= offset.y;
        }
        frameData.frame = frame;
        
        [tempSelf.arrayViewFrames replaceObjectAtIndex:idx withObject:frameData];
        
    }];
    NSMutableArray *arraySubViewsTemp = [NSMutableArray arrayWithArray:self.arraySubViews];
    [self _enumerateObjectsInArray:arraySubViewsTemp withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = [tempSelf _frameValueAtIndex:idx];
        [tempSelf _relocateSubView:subView usingFrame:frame];
        [tempSelf _reloadSubView:[NSValue valueWithCGRect:frame] withIndex:idx];
        
        [tempSelf _estimateCentralIndexWithSubView:subView minimumOffset:&minimumDelta estimatedIndex:&estimateIndex];
        
    }];
    _centerIndex = estimateIndex;
    _currentIndex = _centerIndex;
}

- (void)scrollToIndex:(NSInteger)index direction:(CCCRecycleScrollAnimateDirections)direction animated:(BOOL)animated {
    if (self.numberOfSubViews == 0) {
        return;
    }
    
    _currentIndex = index;
    
    [self _stopTimer];
    if (!animated) {
        if (index < 0 || index >= self.numberOfSubViews) {
            _currentIndex = _centerIndex;
        }
        else {
            [self _removeAllSubViewsAnimated:self.displayAnimated];
            [self _loadSubViewLayouts];
            _centerIndex = index;
        }
        
    }
    else {
        [self _startScrollWithDirection:direction];
    }
}

- (void)_startScrollWithDirection:(CCCRecycleScrollAnimateDirections)direction {
    [self _stopTimer];
    
    _scrolling = YES;
    
    _accuracy = self.decelerateRate;
    _shouldDecelerate = NO;
    
    if (_userInfo) {
        [_userInfo release];
    }
    _userInfo = [@(direction) retain];
    
    _decelerateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_decelerateTimer, DISPATCH_TIME_NOW, kCCCRecycleScrollViewTimerInterval * NSEC_PER_SEC, 0.005 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_decelerateTimer, ^{
        [self _scrollAnimation:direction];
    });
    dispatch_resume(_decelerateTimer);
    /*
    NSThread *thread = CCCRecycleScrollView.timerThread;
    [self performSelector:@selector(_startScrollAnimationTimer:) onThread:thread withObject:@(direction) waitUntilDone:NO];
    if (!_threadShouldStart) {
        _threadShouldStart = YES;
    }
    
    if (!thread.isExecuting && !thread.isFinished) {
        [thread start];
    }
    */
}

- (void)_startScrollAnimationTimer:(NSNumber *)direction {
    @autoreleasepool {
//        _decelerateTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(_scrollAnimation:) userInfo:direction repeats:YES];
        
//        CFRunLoopRun();
//        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)stopScroll {
    if (self.currentIndex < 0 || self.currentIndex >= self.numberOfSubViews) {
        _currentIndex = _centerIndex;
    }
    
    __block typeof(self) tempSelf = self;
    if (self.pagingEnabled) {
        [NSThread _executeOnMainThread:^ {
            [tempSelf _resizeSubViews];
        }];
    }
    
    id userInfo = [self _stopTimer];
    
    if (userInfo) {
        [NSThread _executeOnMainThread:^ {
            if (tempSelf.delegate && [tempSelf.delegate respondsToSelector:@selector(recycleScrollViewDidEndScrollingAnimation:)]) {
                [tempSelf.delegate recycleScrollViewDidEndScrollingAnimation:tempSelf];
            }
        }];
    }
}

- (void)stopScrollAtIndex:(NSInteger)index {
    _currentIndex = index;
}

- (void)decelerate {
    _shouldDecelerate = YES;
}

- (void)decelerateToIndex:(NSInteger)index {
    _currentIndex = index;
    
    _shouldDecelerate = YES;
}

- (void)_scrollAnimation:(CCCRecycleScrollAnimateDirections)direction {
    if (_decelerateTimer == NULL) {
        return;
    }
    
//    CCCRecycleScrollAnimateDirections direction = [_decelerateTimer.userInfo integerValue];
    
    CCCRecycleView *targetSubView = [self _subViewWithIndex:self.currentIndex searchDirection:direction];
    CGFloat delta = targetSubView.center.x-self.bounds.size.width/2.0;
    if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        delta = targetSubView.center.y-self.bounds.size.height/2.0;
    }
    
    BOOL shouldStopScroll = NO;
    CGPoint relocateOffset = CGPointZero;
    if (!_shouldDecelerate) {
        if (_currentIndex >= 0 && _currentIndex < self.numberOfSubViews) {
            if (fabs(delta) < _accuracy/2.0) {
                shouldStopScroll = YES;
            }
        }
    }
    else if (_shouldDecelerate) {
        if (_currentIndex >= 0 && _currentIndex < self.numberOfSubViews) {
            if (fabs(delta) < _accuracy) {
                shouldStopScroll = YES;
            }
            else {
//                _accuracy = MAX(_accuracy, 1);
            }
        }
        else if (_accuracy < 0.1) {
            shouldStopScroll = YES;
        }
    }
    
    if (shouldStopScroll) {
        [self stopScroll];
    }
    else {
        if (direction == CCCRecycleScrollAnimateDirectionDescending || (delta < 0 && direction == CCCRecycleScrollAnimateDirectionAuto)) {
            relocateOffset = CGPointMake(-_accuracy, -_accuracy);
        }
        else if (direction == CCCRecycleScrollAnimateDirectionAscending || (delta > 0 && direction == CCCRecycleScrollAnimateDirectionAuto)) {
            relocateOffset = CGPointMake(_accuracy, _accuracy);
        }
        
        if (_shouldDecelerate && _accuracy > 0.1)
            _accuracy -= 0.1;
    }
    
    if (CGPointEqualToPoint(relocateOffset, CGPointZero)) {
        return;
    }
    
    __block typeof(self) tempSelf = self;
    NSMutableArray *arrayFramesTemp = [NSMutableArray arrayWithArray:self.arrayViewFrames];
    [self _enumerateObjectsInArray:arrayFramesTemp withActions:^(CCCRecycleFrame *frameData, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = frameData.frame;
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            frame.origin.x -= relocateOffset.x;
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            frame.origin.y -= relocateOffset.y;
        }
        frameData.frame = frame;
        
        [tempSelf.arrayViewFrames replaceObjectAtIndex:idx withObject:frameData];
        
    }];
    
    //dispatch_async(dispatch_get_main_queue(), ^ {
        __block NSInteger estimateIndex = 0;
        __block CGFloat minimumDelta = CGFLOAT_MAX;
        NSMutableArray *arraySubViewsTemp = [NSMutableArray arrayWithArray:self.arraySubViews];
        
        estimateIndex = tempSelf.currentIndex;
        [tempSelf _enumerateObjectsInArray:arraySubViewsTemp withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
            
            CGRect frame = [tempSelf _frameValueAtIndex:idx];
            [tempSelf _relocateSubView:subView usingFrame:frame];
            //[tempSelf _reloadSubView:[NSValue valueWithCGRect:frame] withIndex:idx];
            
            [tempSelf _subViewDisplay:subView withIndex:subView.index];
            
            [tempSelf _estimateCentralIndexWithSubView:subView minimumOffset:&minimumDelta estimatedIndex:&estimateIndex];
            
        }];
        _centerIndex = estimateIndex;
        
        [tempSelf _reloadSubViews];
        
        if (tempSelf.delegate && [tempSelf.delegate respondsToSelector:@selector(recycleScrollViewDidScroll:)]) {
            [tempSelf.delegate recycleScrollViewDidScroll:tempSelf];
        }
    //});
}

#pragma mark - PanGestureRecognizer

- (void)_panGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!self.isScrollEnabled) {
        return;
    }
    
    __block NSInteger estimateIndex = 0;
    __block CGFloat minimumDelta = CGFLOAT_MAX;
    __block typeof(self) tempSelf = self;
    
    // 計算偏移
    CGPoint offset = self.bounds.origin;
    offset.x -= [gestureRecognizer translationInView:self].x;
    offset.y -= [gestureRecognizer translationInView:self].y;
    
    NSMutableArray *arrayFramesTemp = [NSMutableArray arrayWithArray:self.arrayViewFrames];
    [self _enumerateObjectsInArray:arrayFramesTemp withActions:^(CCCRecycleFrame *frameData, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = frameData.frame;
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            frame.origin.x -= offset.x;
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            frame.origin.y -= offset.y;
        }
        frameData.frame = frame;
        
        [tempSelf.arrayViewFrames replaceObjectAtIndex:idx withObject:frameData];
        
    }];
    
    NSMutableArray *arraySubViewsTemp = [NSMutableArray arrayWithArray:self.arraySubViews];
    [self _enumerateObjectsInArray:arraySubViewsTemp withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = [tempSelf _frameValueAtIndex:idx];
        [tempSelf _relocateSubView:subView usingFrame:frame];
        //[tempSelf _reloadSubView:[NSValue valueWithCGRect:frame] withIndex:idx];
        
        [tempSelf _estimateCentralIndexWithSubView:subView minimumOffset:&minimumDelta estimatedIndex:&estimateIndex];
        
    }];
    _centerIndex = estimateIndex;
    _currentIndex = _centerIndex;
    
    [self _reloadSubViews];
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStatePossible: {
            break;
        }
        case UIGestureRecognizerStateBegan: {
            _startPoint = [gestureRecognizer locationInView:self];
            [self _stopTimer];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollViewWillBeginDragging:)]) {
                [self.delegate recycleScrollViewWillBeginDragging:self];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            _lastScrollOffset = offset;
            _scrollVelocity = [gestureRecognizer velocityInView:self];
            
            _dragging = YES;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollViewDidScroll:)]) {
                [self.delegate recycleScrollViewDidScroll:self];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            _endPoint = [gestureRecognizer locationInView:self];
            
            [self _startDecelerate];
            break;
        }
        default:
            break;
    }
    
    // 重置
    [gestureRecognizer setTranslation:CGPointZero inView:self];
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (!self.isScrollEnabled) {
        return NO;
    }
    
    [self _stopTimer];
    
    _startPoint = [gestureRecognizer locationInView:self];
    _endPoint = _startPoint;
    _lastScrollOffset = CGPointZero;
    _scrollVelocity = CGPointZero;
    
    return YES;
}

#pragma mark - NSTimer

- (void)_startDecelerate {
    [self _stopTimer];
    
    _decelerating = YES;
    
    if (self.isPagingEnabled) {
        // 加速度
        _accuracy = self.decelerateRate;
        BOOL willDecelerate = YES;
        
        // 若是很快速的滑動，則直接切換到上/下一頁 (增加靈敏度)
        CCCRecycleFrame *frameData = [self.arrayViewFrames objectAtIndex:self.arrayViewFrames.count/2];
        CGRect centerFrame = CGRectZero;
        if ((NSNull *)frameData != [NSNull null]) {
            centerFrame = frameData.frame;
        }
        
        if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (fabs(self.bounds.size.width-centerFrame.size.width) <= 2.0) {
                if (_scrollVelocity.x < -400 && fabs(_startPoint.x-_endPoint.x) < self.bounds.size.width*0.4) {
                    _currentIndex = [self _nextIndexOfIndex:self.currentIndex];
                }
                else if (_scrollVelocity.x > 400 && fabs(_startPoint.x-_endPoint.x) < self.bounds.size.width*0.4) {
                    _currentIndex = [self _previousIndexOfIndex:self.currentIndex];
                }
            }
            
            CCCRecycleView *centralSubView = [self _subViewAtCurrentIndex];
            CGFloat delta = centralSubView.center.x-self.bounds.size.width/2.0;
            if (fabs(delta) < _accuracy) {
                willDecelerate = NO;
            }
        }
        else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (fabs(self.bounds.size.height-centerFrame.size.height) <= 2.0) {
                if (_scrollVelocity.y < -400 && fabs(_startPoint.y-_endPoint.y) < self.bounds.size.height*0.4) {
                    _currentIndex = [self _nextIndexOfIndex:self.currentIndex];
                }
                else if (_scrollVelocity.y > 400 && fabs(_startPoint.y-_endPoint.y) < self.bounds.size.height*0.4) {
                    _currentIndex = [self _previousIndexOfIndex:self.currentIndex];
                }
            }
            
            CCCRecycleView *centralSubView = [self _subViewAtCurrentIndex];
            CGFloat delta = centralSubView.center.y-self.bounds.size.height/2.0;
            if (fabs(delta) < _accuracy) {
                willDecelerate = NO;
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollViewDidEndDragging:willDecelerate:)]) {
            [self.delegate recycleScrollViewDidEndDragging:self willDecelerate:willDecelerate];
        }
        if (willDecelerate) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollViewWillBeginDecelerating:)]) {
                [self.delegate recycleScrollViewWillBeginDecelerating:self];
            }
        }
    }
    else {
        // 加速度
        _accuracy = 0.5;
        
        // 限速
        if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            if (_lastScrollOffset.x > 60.0) {
                _lastScrollOffset.x = 60.0;
            }
            else if (_lastScrollOffset.x < -60.0) {
                _lastScrollOffset.x = -60.0;
            }
        }
        else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
            if (_lastScrollOffset.y > 60.0) {
                _lastScrollOffset.y = 60.0;
            }
            else if (_lastScrollOffset.y < -60.0) {
                _lastScrollOffset.y = -60.0;
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(recycleScrollViewDidEndDragging:willDecelerate:)]) {
            [self.delegate recycleScrollViewDidEndDragging:self willDecelerate:YES];
        }
    }
    
    if (_userInfo) {
        [_userInfo release];
    }
    _userInfo = nil;
    
    _decelerateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_decelerateTimer, DISPATCH_TIME_NOW, kCCCRecycleScrollViewTimerInterval * NSEC_PER_SEC, 0.005 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_decelerateTimer, ^{
        [self _decelerate];
    });
    dispatch_resume(_decelerateTimer);
    /*
    NSThread *thread = CCCRecycleScrollView.timerThread;
    [self performSelector:@selector(_startDecelerateTimer) onThread:thread withObject:nil waitUntilDone:NO];
    if (!_threadShouldStart) {
        _threadShouldStart = YES;
    }
    
    if (!thread.isExecuting && !thread.isFinished) {
        [thread start];
    }
    */
}

- (void)_startDecelerateTimer {
    @autoreleasepool {
        //_decelerateTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(_decelerate:) userInfo:nil repeats:YES];
        
//        CFRunLoopRun();
//        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)_stopDecelerate {
    [self _stopTimer];
    
    __block typeof(self) tempSelf = self;
    [NSThread _executeOnMainThread:^ {
        if (tempSelf.delegate && [tempSelf.delegate respondsToSelector:@selector(recycleScrollViewDidEndDecelerating:)]) {
            [tempSelf.delegate recycleScrollViewDidEndDecelerating:tempSelf];
        }
    }];
}

- (void)_decelerate {
    if (_decelerateTimer == NULL) {
        return;
    }
    
    CGPoint relocateOffset = CGPointZero;
    if (self.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
        if (self.isPagingEnabled) {
            CCCRecycleView *centralSubView = [self _subViewAtCurrentIndex];
            
            CGFloat delta = centralSubView.center.x-self.bounds.size.width/2.0;
            if (fabs(delta) < _accuracy) {
                relocateOffset = CGPointMake(delta, 0.0);
                [self _stopDecelerate];
            }
            else if (delta < 0.0) {
                relocateOffset = CGPointMake(-_accuracy, 0.0);
            }
            else {
                relocateOffset = CGPointMake(_accuracy, 0.0);
            }
        }
        else {
            if (_scrollVelocity.x > 0.0) {
                if (_lastScrollOffset.x < 0.0) {
                    _lastScrollOffset.x += _accuracy;
                    relocateOffset = _lastScrollOffset;
                }
                else {
                    [self _stopDecelerate];
                }
            }
            else if (_scrollVelocity.x < 0.0) {
                if (_lastScrollOffset.x < 0.0) {
                    [self _stopDecelerate];
                }
                else {
                    _lastScrollOffset.x -= _accuracy;
                    relocateOffset = _lastScrollOffset;
                }
            }
        }
    }
    else if (self.scrollDirection == CCCRecycleScrollDirectionVertical) {
        if (self.isPagingEnabled) {
            CCCRecycleView *centralSubView = [self _subViewAtCurrentIndex];
            
            CGFloat delta = centralSubView.center.y-self.bounds.size.height/2.0;
            if (fabs(delta) < _accuracy) {
                relocateOffset = CGPointMake(0.0, delta);
                [self _stopDecelerate];
            }
            else if (delta < 0.0) {
                relocateOffset = CGPointMake(0.0, -_accuracy);
            }
            else {
                relocateOffset = CGPointMake(0.0, _accuracy);
            }
        }
        else {
            if (_scrollVelocity.y > 0.0) {
                if (_lastScrollOffset.y < 0.0) {
                    _lastScrollOffset.y += _accuracy;
                    relocateOffset = _lastScrollOffset;
                }
                else {
                    [self _stopDecelerate];
                }
            }
            else if (_scrollVelocity.y < 0.0) {
                if (_lastScrollOffset.y < 0.0) {
                    [self _stopDecelerate];
                }
                else {
                    _lastScrollOffset.y -= _accuracy;
                    relocateOffset = _lastScrollOffset;
                }
            }
        }
    }
    __block typeof(self) tempSelf = self;
    NSMutableArray *arrayFramesTemp = [NSMutableArray arrayWithArray:self.arrayViewFrames];
    [tempSelf _enumerateObjectsInArray:arrayFramesTemp withActions:^(CCCRecycleFrame *frameData, NSUInteger idx, BOOL *stop) {
        
        CGRect frame = frameData.frame;
        if (tempSelf.scrollDirection == CCCRecycleScrollDirectionHorizontal) {
            frame.origin.x -= relocateOffset.x;
        }
        else if (tempSelf.scrollDirection == CCCRecycleScrollDirectionVertical) {
            frame.origin.y -= relocateOffset.y;
        }
        frameData.frame = frame;
        
        [tempSelf.arrayViewFrames replaceObjectAtIndex:idx withObject:frameData];
        
    }];
    
    //dispatch_async(dispatch_get_main_queue(), ^ {
        __block NSInteger estimateIndex = 0;
        __block CGFloat minimumDelta = CGFLOAT_MAX;
        NSMutableArray *arraySubViewsTemp = [NSMutableArray arrayWithArray:tempSelf.arraySubViews];
        
        if (tempSelf.isPagingEnabled) {
            estimateIndex = tempSelf.currentIndex;
        }
        [tempSelf _enumerateObjectsInArray:arraySubViewsTemp withActions:^(CCCRecycleView *subView, NSUInteger idx, BOOL *stop) {
            
            CGRect frame = [tempSelf _frameValueAtIndex:idx];
            [tempSelf _relocateSubView:subView usingFrame:frame];
            //[tempSelf _reloadSubView:[NSValue valueWithCGRect:frame] withIndex:idx];
            
            [tempSelf _subViewDisplay:subView withIndex:subView.index];
            
            if (!tempSelf.isPagingEnabled) {
                [tempSelf _estimateCentralIndexWithSubView:subView minimumOffset:&minimumDelta estimatedIndex:&estimateIndex];
            }
            
        }];
        _centerIndex = estimateIndex;
        _currentIndex = _centerIndex;
        
        [tempSelf _reloadSubViews];
    
        if (tempSelf.delegate && [tempSelf.delegate respondsToSelector:@selector(recycleScrollViewDidScroll:)]) {
            [tempSelf.delegate recycleScrollViewDidScroll:tempSelf];
        }
    //});
}

@end
