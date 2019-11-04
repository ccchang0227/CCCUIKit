//
//  CCCAssetsViewController.h
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCAssetsModel.h"
#import "CCCAssetsGroupsViewController.h"
#import "CCCAllAssetsViewController.h"

@protocol CCCAssetsViewControllerDelegate;

/**
 * Custom ImagePickerViewController
 *
 * @version 1.1.4
 * @author Chih-chieh Chang
 * @date 2019-11-04
 */
@interface CCCAssetsViewController : UIViewController <UINavigationControllerDelegate, CCCAssetsGroupsViewControllerDelegate, CCCAllAssetsViewControllerDelegate>

@property (assign, nonatomic) id<CCCAssetsViewControllerDelegate> delegate;

@property (readonly, retain, nonatomic) CCCAssetsModel *model;

// default to CCCAssetsFetchTypeBoth.
@property (assign, nonatomic) CCCAssetsFetchType assetsFetchType;

@property (readonly, nonatomic) BOOL isTopLibraryViewController;

@property (retain, nonatomic) UIView *contentView;

@property (retain, nonatomic) IBOutlet UIView *titleBgView;
@property (readonly, nonatomic) UIView *titleView;
@property (readonly, nonatomic) UILabel *titleLabel;
@property (readonly, nonatomic) UIButton *closeButton;
@property (readonly, nonatomic) UIButton *backButton;

@property (retain, nonatomic) IBOutlet UIView *libraryContainerView;
@property (readonly, retain, nonatomic) UINavigationController *libraryNavigationController;
@property (readonly, retain, nonatomic) CCCAssetsGroupsViewController *assetsGroupsViewController;
@property (readonly, retain, nonatomic) CCCAllAssetsViewController *allAssetsViewController;

@property (retain, nonatomic) IBOutlet NSLayoutConstraint *titleViewHeightConstraint;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *contentBottomSpaceConstraint;

// Override method
- (IBAction)closeAction:(id)sender;
- (IBAction)backAction:(id)sender;

- (void)didSelectGroup:(CCCAssetsGroup *)assetsGroup;
- (void)didPickAsset:(CCCAsset *)asset;

@end

@protocol CCCAssetsViewControllerDelegate <NSObject>
@optional

- (void)cccAssetsViewControllerDidCancel:(CCCAssetsViewController *)viewController;

- (void)cccAssetsViewController:(CCCAssetsViewController *)viewController didSelectGroup:(CCCAssetsGroup *)assetsGroup;
- (void)cccAssetsViewController:(CCCAssetsViewController *)viewController didPickAsset:(CCCAsset *)asset;

@end
