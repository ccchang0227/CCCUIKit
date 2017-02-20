//
//  CCCUIKit.h
//  
//
//  Created by realtouchapp on 2017/2/16.
//
//

#ifndef CCCUIKit_h
#define CCCUIKit_h

/**
 * C.C.Chang's custom UIKit.
 *
 * @version 1.0.2
 * @author Chih-chieh Chang
 * @date 2017-02-20
 */

#if !TARGET_OS_MAC

#import "UIKit+CCCAdditions.h"
#import "CCCDevice.h"
#import "CCCSwitch.h"

#if !TARGET_OS_TV
#import "CCCAssetsViewController.h"
#import "CCCCamera.h"
#import "CCCCanvas.h"
#import "CCCCycleView.h"
#import "CCCMaskedLabel.h"
#import "CCCPageControl.h"
#import "CCCRatingControl.h"
#import "CCCRecycleScrollView.h"
#import "CCCSlider.h"
#import "CCCSlidingViewController.h"
#endif

#endif

#endif
