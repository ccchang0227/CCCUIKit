//
//  CCCAllAssetsViewController.h
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCAssetsModel.h"


@class CCCAssetPreviewView;

@protocol CCCAllAssetsViewControllerDelegate;
@interface CCCAllAssetsViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (assign, nonatomic) id<CCCAllAssetsViewControllerDelegate> delegate;

@property (assign, nonatomic) CCCAssetsFetchType assetsFetchType;

@property (retain, nonatomic) NSArray<CCCAsset *> *allAssetsArray;
@property (readonly, nonatomic) NSUInteger numberOfPhotos;
@property (readonly, nonatomic) NSUInteger numberOfVideos;

@property (readonly, retain, nonatomic) NSOperationQueue *operationQueue;

// default is NO.
@property (assign, nonatomic) BOOL collectionViewFooterHidden;

@property (retain, nonatomic) IBOutlet UICollectionView *assetsCollectionView;

// default is YES.
@property (assign, nonatomic) BOOL showPreviewOnLongPress;
// default is 0.5.
@property (assign, nonatomic) NSTimeInterval longPressDuration;
@property (retain, nonatomic) IBOutlet CCCAssetPreviewView *assetPreviewView;


- (void)reloadData;

// Override method
- (void)didPickAsset:(CCCAsset *)asset;

@end

@protocol CCCAllAssetsViewControllerDelegate <NSObject>
@optional

- (void)cccAllAssetsViewController:(CCCAllAssetsViewController *)viewController didPickAsset:(CCCAsset *)asset;

@end


@protocol CCCAssetCollectionViewCellDelegate;
@interface CCCAssetCollectionViewCell : UICollectionViewCell

@property (assign, nonatomic) id<CCCAssetCollectionViewCellDelegate> delegate;

@property (copy, nonatomic) NSIndexPath *indexPath;
@property (retain, nonatomic) UIImageView *assetThumbImageView;

@property (retain, nonatomic) UIImageView *videoSymbolImageView;

- (void)adjustVideoSymbolPosition;

@property (readonly, retain, nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;

@end

@protocol CCCAssetCollectionViewCellDelegate <NSObject>
@optional

- (BOOL)cccAssetCollectionViewCellShouldBeginLongPress:(CCCAssetCollectionViewCell *)cell;

- (void)cccAssetCollectionViewCellDidBeginLongPress:(CCCAssetCollectionViewCell *)cell;
- (void)cccAssetCollectionViewCellDidEndLongPress:(CCCAssetCollectionViewCell *)cell;

@end


@interface CCCAllAssetsCollectionFooterView : UICollectionReusableView

@property (retain, nonatomic) UILabel *allAssetsInfoLabel;

@end
