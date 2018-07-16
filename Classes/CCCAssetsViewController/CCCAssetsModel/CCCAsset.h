//
//  CCCAsset.h
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <MediaPlayer/MediaPlayer.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CCCAssetType) {
    CCCAssetTypeUnknown,
    CCCAssetTypeImage,
    CCCAssetTypeVideo
};

@interface CCCAsset : NSObject

@property (readonly, nonatomic) CCCAssetType assetType;

@property (readonly, copy, nonatomic, nullable) NSString *title;

@property (readonly, copy, nonatomic, nullable) NSString *identifier;

- (nullable NSURL *)loadAssetURLWithHandler:(void(^ _Nullable)(NSURL *__nullable assetURL))handler;

- (nullable UIImage *)loadSquareThumbImageInOperationQueue:(nullable NSOperationQueue *)operationQueue
                                               withHandler:(void(^ _Nullable)(UIImage *__nullable thumbImage))handler;
- (nullable UIImage *)loadAspectRatioThumbImageInOperationQueue:(nullable NSOperationQueue *)operationQueue
                                                    withHandler:(void(^ _Nullable)(UIImage *__nullable thumbImage))handler;
- (nullable UIImage *)loadLargeImageInOperationQueue:(nullable NSOperationQueue *)operationQueue
                               withHandler:(void(^ _Nullable)(UIImage *__nullable image))handler;

- (nullable AVPlayerItem *)loadPlayerItemWithHandler:(void(^ _Nullable)(AVPlayerItem *__nullable playerItem))handler;

@property (readonly, strong, nonatomic, nullable) ALAsset *alAsset;

+ (instancetype)cccAssetWithALAsset:(ALAsset *)alAsset;
- (instancetype)initWithALAsset:(ALAsset *)alAsset NS_DESIGNATED_INITIALIZER;


#ifdef Photos_Photos_h

@property (readonly, strong, nonatomic, nullable) PHAsset *phAsset NS_AVAILABLE_IOS(9_0);

+ (instancetype)cccAssetWithPHAsset:(PHAsset *)phAsset NS_AVAILABLE_IOS(9_0);
- (instancetype)initWithPHAsset:(PHAsset *)phAsset NS_DESIGNATED_INITIALIZER NS_AVAILABLE_IOS(9_0);

#endif


@property (readonly, strong, nonatomic, nullable) MPMediaItem *mpMediaItem;

+ (nullable instancetype)cccAssetWithMPMediaItem:(MPMediaItem *)mpMediaItem;
- (nullable instancetype)initWithMPMediaItem:(MPMediaItem *)mpMediaItem NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
