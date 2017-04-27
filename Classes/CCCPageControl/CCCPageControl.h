//
//  CCCPageControl.h
//
//  Created by freeidea on 13/10/27.
//  Copyright (c) 2013年 realtouch. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN UIImage *customCurrentPageImageWithColor(UIColor *strokeColor, UIColor *fillColor);
UIKIT_EXTERN UIImage *customPageImageWithColor(UIColor *strokeColor, UIColor *fillColor);

/**
 * Custom UIPageControl (UIImage assignable)
 *
 * @version 1.0.2
 * @author Chih-chieh Chang
 * @date 2017-04-26
 */
@interface CCCPageControl : UIControl

@property (retain, nonatomic) UIImage *currentPageImage; // default is nil.
@property (retain, nonatomic) UIImage *pageImage; // default is nil.

@property (assign, nonatomic) CGFloat pageImageAlpha; // default is 0.2, display the pages that not current page with this alpha value. the alpha of current page must be 1.

@property (assign, nonatomic) NSInteger numberOfPages; // default is 0
@property (assign, nonatomic) NSInteger currentPage; // default is 0. value pinned to 0..numberOfPages-1

@property (assign, nonatomic) BOOL hidesForSinglePage; // hide the the indicator if there is only one page. default is NO

@property (assign, nonatomic) BOOL defersCurrentPageDisplay; // if set, clicking to a new page won't update the currently displayed page until -updateCurrentPageDisplay is called. default is NO.

- (instancetype)initWithFrame:(CGRect)frame pageImage:(UIImage*)pageImage currentPageImage:(UIImage*)currentPageImage;

- (void)updateCurrentPageDisplay; // update page display to match the currentPage. ignored if defersCurrentPageDisplay is NO.

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount; // returns minimum size required to display dots for given page count. can be used to size control if page count could change.

@end
