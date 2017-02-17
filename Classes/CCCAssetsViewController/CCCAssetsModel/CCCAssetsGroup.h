//
//  CCCAssetsGroup.h
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <MediaPlayer/MediaPlayer.h>


NS_ASSUME_NONNULL_BEGIN

@interface CCCAssetsGroup : NSObject

@property (readonly, copy, nonatomic, nullable) NSString *groupName;
@property (readonly, copy, nonatomic, nullable) NSString *groupURL;
@property (readonly, strong, nonatomic, nullable) UIImage *posterImage;

@property (nonatomic) NSUInteger numberOfPhotoAssets;
@property (nonatomic) NSUInteger numberOfVideoAssets;

@property (readonly, nonatomic) BOOL isAllVideosGroup;

@property (assign, nonatomic) BOOL shouldIncludeVideos; // default to YES. Ignores when isAllVideosGroup is YES.
@property (assign, nonatomic) BOOL shouldIncludePhotos; // default to YES. Ignores when isAllVideosGroup is YES.

- (nullable UIImage *)loadGroupPosterImageInOperationQueue:(nullable NSOperationQueue *)operationQueue
                                               withHandler:(void(^ _Nullable)(UIImage *__nullable posterImage))handler;


@property (readonly, strong, nonatomic, nullable) ALAssetsGroup *alAssetsGroup;

+ (instancetype)cccAssetsGroupWithALAssetsGroup:(ALAssetsGroup *)group
                                isAllVideosGroup:(BOOL)isAllVideosGroup;
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)group
                     isAllVideosGroup:(BOOL)isAllVideosGroup NS_DESIGNATED_INITIALIZER;

+ (BOOL)assetsGroupHasVideoAssets:(ALAssetsGroup *)group;
+ (BOOL)assetsGroupHasImageAssets:(ALAssetsGroup *)group;


#ifdef Photos_Photos_h

@property (readonly, strong, nonatomic, nullable) PHAssetCollection *phAssetCollection NS_AVAILABLE_IOS(9_0);

+ (instancetype)cccAssetsGroupWithPHAssetCollection:(PHAssetCollection *)collection
                                   isAllVideosGroup:(BOOL)isAllVideosGroup NS_AVAILABLE_IOS(9_0);
- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection
                         isAllVideosGroup:(BOOL)isAllVideosGroup NS_DESIGNATED_INITIALIZER NS_AVAILABLE_IOS(9_0);

+ (BOOL)collectionHasVideoAssets:(PHAssetCollection *)collection NS_AVAILABLE_IOS(9_0);
+ (BOOL)collectionHasImageAssets:(PHAssetCollection *)collection NS_AVAILABLE_IOS(9_0);

#endif


+ (nullable instancetype)cccAssetsGroupWithMPMediaItem:(MPMediaItem *)mediaItem;
- (nullable instancetype)initWithMPMediaItem:(MPMediaItem *)mediaItem NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
