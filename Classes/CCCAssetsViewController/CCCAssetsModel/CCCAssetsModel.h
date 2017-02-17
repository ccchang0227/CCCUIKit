//
//  CCCAssetsModel.h
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCAssetsGroup.h"
#import "CCCAsset.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CCCAssetsFetchType) {
    CCCAssetsFetchTypeImage = 1<<0,
    CCCAssetsFetchTypeVideo = 1<<1,
    CCCAssetsFetchTypeBoth = (CCCAssetsFetchTypeImage|CCCAssetsFetchTypeVideo)
};

@interface CCCAssetsModel : NSObject

+ (ALAssetsLibrary *)sharedAssetsLibrary;

@property (readonly, nonatomic) BOOL isPhotoLibraryAuthorized;

- (void)loadAssetsGroupsWithAssetFetchType:(CCCAssetsFetchType)type
                                   handler:(void(^ _Nullable)(NSArray<CCCAssetsGroup *> *__nullable assetsGroups))handler;

- (void)loadAllAssetsFromGroup:(CCCAssetsGroup *)assetsGroup
            withAssetFetchType:(CCCAssetsFetchType)type
                       handler:(void(^ _Nullable)(NSArray<CCCAsset *> *__nullable allAssets))handler;

#pragma mark -

+ (BOOL)isValidMediaItem:(MPMediaItem *)mpMediaItem;

#pragma mark -

+ (UIImage *)resizeAspectFillImage:(UIImage *)image maxSize:(CGFloat)max;
+ (UIImage *)resizeAspectFitImage:(UIImage *)image maxSize:(CGFloat)max;
+ (UIImage *)createSquareImageFromImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
