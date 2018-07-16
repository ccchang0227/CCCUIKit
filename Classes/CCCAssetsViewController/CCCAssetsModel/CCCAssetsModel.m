//
//  CCCAssetsModel.m
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAssetsModel.h"


@interface CCCAssetsModel ()
@end

@implementation CCCAssetsModel

+ (ALAssetsLibrary *)sharedAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *assetsLibrary = nil;
    dispatch_once(&pred, ^{
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return assetsLibrary;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
    
}

#pragma mark -

- (BOOL)isPhotoLibraryAuthorized {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
            return YES;
        }
        else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        if ([ALAssetsLibrary respondsToSelector:@selector(authorizationStatus)]) {
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
                return YES;
            }
            else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                return YES;
            }
            else {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)_checkAuthority {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
            
            __block BOOL access = NO;
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    access = YES;
                }
                
                dispatch_group_leave(group);
            }];
            
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
#if !__has_feature(objc_arc)
            dispatch_release(group);
#endif
            
            return access;
        }
        else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        if ([ALAssetsLibrary respondsToSelector:@selector(authorizationStatus)]) {
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined) {
                return YES;
            }
            else if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                return YES;
            }
            else {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark - Group

- (void)loadAssetsGroupsWithAssetFetchType:(CCCAssetsFetchType)type handler:(void(^)(NSArray<CCCAssetsGroup *> *assetsGroups))handler {
    
    if (![self _checkAuthority]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (handler) {
                handler(nil);
            }
        });
        return;
    }
    
    NSMutableArray<CCCAssetsGroup *> *groupsArray = [NSMutableArray arrayWithCapacity:0];
    __block CCCAssetsGroup *allVideoAssetsGroup = nil;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        if (type & CCCAssetsFetchTypeVideo) {
            MPMediaPropertyPredicate *videoPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];
            MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:videoPredicate]];
            //[videoQuery addFilterPredicate: videoPredicate];
            NSArray *items = [videoQuery items];
            if (items) {
                for (MPMediaItem *mediaItem in items)  {
                    allVideoAssetsGroup = [CCCAssetsGroup cccAssetsGroupWithMPMediaItem:mediaItem];
                    if (allVideoAssetsGroup) {
                        [groupsArray addObject:allVideoAssetsGroup];
                        break;
                    }
                }
                
                if (allVideoAssetsGroup) {
                    allVideoAssetsGroup.numberOfVideoAssets += items.count;
                }
            }
            [videoQuery release];
        }
        dispatch_group_leave(group);
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    __block BOOL hasVideoGroup = (BOOL)(allVideoAssetsGroup);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            
            NSArray *collectionTypes = @[@(PHAssetCollectionTypeSmartAlbum), @(PHAssetCollectionTypeAlbum)];
            for (NSNumber *collectionTypeNumer in collectionTypes) {
                PHAssetCollectionType collectionType = [collectionTypeNumer integerValue];
                PHFetchResult<PHAssetCollection *> *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:collectionType subtype:PHAssetCollectionSubtypeAny options:nil];
                [fetchResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
                    if (collection) {
                        if (@available(iOS 9.0, *)) {
                            if (!hasVideoGroup && (type & CCCAssetsFetchTypeVideo) && [CCCAssetsGroup collectionHasVideoAssets:collection]) {
                                allVideoAssetsGroup = [CCCAssetsGroup cccAssetsGroupWithPHAssetCollection:collection isAllVideosGroup:YES];
                                if (allVideoAssetsGroup) {
                                    [groupsArray addObject:allVideoAssetsGroup];
                                    hasVideoGroup = YES;
                                }
                            }
                            
                            if (((type & CCCAssetsFetchTypeVideo) && [CCCAssetsGroup collectionHasVideoAssets:collection]) ||
                                ((type & CCCAssetsFetchTypeImage) && [CCCAssetsGroup collectionHasImageAssets:collection])) {
                                CCCAssetsGroup *assetsGroup = [CCCAssetsGroup cccAssetsGroupWithPHAssetCollection:collection isAllVideosGroup:NO];
                                if (assetsGroup) {
                                    assetsGroup.shouldIncludePhotos = (type & CCCAssetsFetchTypeImage);
                                    assetsGroup.shouldIncludeVideos = (type & CCCAssetsFetchTypeVideo);
                                    [groupsArray addObject:assetsGroup];
                                    
                                    if (allVideoAssetsGroup &&
                                        collectionType == PHAssetCollectionTypeSmartAlbum &&
                                        collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumVideos) {
                                        allVideoAssetsGroup.numberOfVideoAssets += assetsGroup.numberOfVideoAssets;
                                    }
                                }
                            }
                        }
                    }
                    
                }];
            }
            
            dispatch_group_leave(group);
        });
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
            if (handler) {
                if (groupsArray.count > 0) {
                    handler(groupsArray);
                }
                else {
                    handler(nil);
                }
            }
        });
    }
    else {
        ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *alAssetsGroup, BOOL *stop) {
            if (alAssetsGroup && alAssetsGroup.numberOfAssets > 0) {
                BOOL hasPhotos = [CCCAssetsGroup assetsGroupHasImageAssets:alAssetsGroup];
                BOOL hasVideos = [CCCAssetsGroup assetsGroupHasVideoAssets:alAssetsGroup];
                
                if (!hasVideoGroup && (type & CCCAssetsFetchTypeVideo) && hasVideos) {
                    allVideoAssetsGroup = [CCCAssetsGroup cccAssetsGroupWithALAssetsGroup:alAssetsGroup isAllVideosGroup:YES];
                    if (allVideoAssetsGroup) {
                        [groupsArray addObject:allVideoAssetsGroup];
                        hasVideoGroup = YES;
                    }
                }
                
                if (((type & CCCAssetsFetchTypeVideo) && hasVideos) ||
                    ((type & CCCAssetsFetchTypeImage) && hasPhotos)) {
                    
                    CCCAssetsGroup *assetsGroup = [CCCAssetsGroup cccAssetsGroupWithALAssetsGroup:alAssetsGroup isAllVideosGroup:NO];
                    if (assetsGroup) {
                        assetsGroup.shouldIncludePhotos = (type & CCCAssetsFetchTypeImage);
                        assetsGroup.shouldIncludeVideos = (type & CCCAssetsFetchTypeVideo);
                        [groupsArray addObject:assetsGroup];
                        
                        if (allVideoAssetsGroup) {
                            ALAssetsGroupType groupType = [[alAssetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
                            if (groupType == ALAssetsGroupSavedPhotos) {
                                allVideoAssetsGroup.numberOfVideoAssets += assetsGroup.numberOfVideoAssets;
                            }
                        }
                    }
                    
                }
                
            }
            else if (!alAssetsGroup) {
                if (handler) {
                    if (groupsArray.count > 0) {
                        handler(groupsArray);
                    }
                    else {
                        handler(nil);
                    }
                }
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
#if DEBUG
            NSLog(@"CCCAssetsModel -loadAssetsGroupsWithAssetFetchType:%@", error);
#endif
            
            if (handler) {
                if (groupsArray.count > 0) {
                    handler(groupsArray);
                }
                else {
                    handler(nil);
                }
            }
        };
        
        ALAssetsGroupType type = ALAssetsGroupAll;
        [CCCAssetsModel.sharedAssetsLibrary enumerateGroupsWithTypes:type usingBlock:resultsBlock failureBlock:failureBlock];
    }
    
#if !__has_feature(objc_arc)
    dispatch_release(group);
#endif
}

#pragma mark - Assets

// 從group裡讀取所有的資源
- (void)loadAllAssetsFromGroup:(CCCAssetsGroup *)assetsGroup withAssetFetchType:(CCCAssetsFetchType)type handler:(void(^)(NSArray<CCCAsset *> *allAssets))handler {
    
    if (![self _checkAuthority] ||
        !assetsGroup ||
        (assetsGroup.numberOfPhotoAssets == 0 && assetsGroup.numberOfVideoAssets == 0)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (handler) {
                handler(nil);
            }
        });
        return;
    }
    if (assetsGroup.isAllVideosGroup && !(type & CCCAssetsFetchTypeVideo)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (handler) {
                handler(nil);
            }
        });
        return;
    }
    
    if (assetsGroup.isAllVideosGroup) {
        [self _loadAllVideoAssetsWithGroup:assetsGroup handler:handler];
    }
    else {
        [self _loadAllAssetsFromPhotosWithAssetsGroup:assetsGroup assetFetchType:type handler:handler];
    }
}

/// 從手機裡讀取所有的影片源 (相片app+影片app)
- (void)_loadAllVideoAssetsWithGroup:(CCCAssetsGroup *)assetsGroup handler:(void(^)(NSArray<CCCAsset *> *allAssets))handler {
    
    NSMutableArray<CCCAsset *> *allAssetsArray = [NSMutableArray arrayWithCapacity:0];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        if (assetsGroup.isAllVideosGroup) {
            MPMediaPropertyPredicate *videoPredicate = [MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeAnyVideo] forProperty:MPMediaItemPropertyMediaType];
            MPMediaQuery *videoQuery = [[MPMediaQuery alloc] initWithFilterPredicates:[NSSet setWithObject:videoPredicate]];
            //[videoQuery addFilterPredicate: videoPredicate];
            NSArray *items = [videoQuery items];
            if (items) {
                for (MPMediaItem *mediaItem in items)  {
                    CCCAsset *asset = [CCCAsset cccAssetWithMPMediaItem:mediaItem];
                    if (asset) {
                        [allAssetsArray addObject:asset];
                    }
                }
            }
            [videoQuery release];
        }
        dispatch_group_leave(group);
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        dispatch_group_enter(group);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:YES]];
            
            NSArray *collectionTypes = @[@(PHAssetCollectionTypeSmartAlbum), @(PHAssetCollectionTypeAlbum)];
            for (NSNumber *collectionTypeNumer in collectionTypes) {
                PHAssetCollectionType collectionType = [collectionTypeNumer integerValue];
                
                PHFetchResult<PHAssetCollection *> *fetchCollectionsResult = [PHAssetCollection fetchAssetCollectionsWithType:collectionType subtype:PHAssetCollectionSubtypeAny options:nil];
                [fetchCollectionsResult enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
                    if (collection) {
                        PHFetchResult<PHAsset *> *fetchAssetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                        [fetchAssetsResult enumerateObjectsUsingBlock:^(PHAsset *phAsset, NSUInteger idx, BOOL *stop) {
                            if (phAsset) {
                                CCCAsset *asset = [CCCAsset cccAssetWithPHAsset:phAsset];
                                if (asset) {
                                    if (![self _checkAssetIsAlreadyInArray:allAssetsArray asset:asset]) {
                                        [allAssetsArray addObject:asset];
                                    }
                                }
                            }
                        }];
                    }
                    
                }];
                
            }
            
#if !__has_feature(objc_arc)
            [options release];
#endif
            
            dispatch_group_leave(group);
        });
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
            if (handler) {
                if (allAssetsArray.count > 0) {
                    handler(allAssetsArray);
                }
                else {
                    handler(nil);
                }
            }
        });
    }
    else {
        ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *alAssetsGroup, BOOL *stop) {
            if (alAssetsGroup && alAssetsGroup.numberOfAssets > 0) {
                [alAssetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
                if (alAssetsGroup.numberOfAssets > 0) {
                    ALAssetsGroupEnumerationResultsBlock alAssetResultsBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        
                        if (result) {
                            CCCAsset *asset = [CCCAsset cccAssetWithALAsset:result];
                            if (asset) {
                                if (![self _checkAssetIsAlreadyInArray:allAssetsArray asset:asset]) {
                                    [allAssetsArray addObject:asset];
                                }
                            }
                        }
                        
                    };
                    
                    [alAssetsGroup enumerateAssetsUsingBlock:alAssetResultsBlock];
                }
            }
            else if (!alAssetsGroup) {
                if (handler) {
                    if (allAssetsArray.count > 0) {
                        handler(allAssetsArray);
                    }
                    else {
                        handler(nil);
                    }
                }
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
            if (handler) {
                if (allAssetsArray.count > 0) {
                    handler(allAssetsArray);
                }
                else {
                    handler(nil);
                }
            }
        };
        
        [CCCAssetsModel.sharedAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:resultsBlock failureBlock:failureBlock];
    }
    
#if !__has_feature(objc_arc)
    dispatch_release(group);
#endif
    
}

/**
 *  @author Chih-chieh Chang, 16-01-30
 *
 *  從相片app的相簿讀取所有的資源
 *
 *  @param assetsGroup 相簿
 *  @param type        用來篩選相片/影片/全部
 *  @param handler     回傳的callback
 */
- (void)_loadAllAssetsFromPhotosWithAssetsGroup:(CCCAssetsGroup *)assetsGroup assetFetchType:(CCCAssetsFetchType)type handler:(void(^)(NSArray<CCCAsset *> *allAssets))handler {
    NSMutableArray<CCCAsset *> *allAssetsArray = [NSMutableArray arrayWithCapacity:0];
    
    dispatch_group_t group = dispatch_group_create();
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        dispatch_group_enter(group);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
            
            if (@available(iOS 9.0, *)) {
                if (assetsGroup.phAssetCollection) {
                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    if (type == CCCAssetsFetchTypeImage) {
                        options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeImage];
                    }
                    else if (type == CCCAssetsFetchTypeVideo) {
                        options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
                    }
                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                    
                    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetsGroup.phAssetCollection options:options];
                    [fetchResult enumerateObjectsUsingBlock:^(PHAsset *phAsset, NSUInteger idx, BOOL *stop) {
                        if (phAsset) {
                            CCCAsset *asset = [CCCAsset cccAssetWithPHAsset:phAsset];
                            if (asset) {
                                [allAssetsArray addObject:asset];
                            }
                        }
                    }];
#if !__has_feature(objc_arc)
                    [options release];
#endif
                }
            }
            
            dispatch_group_leave(group);
        });
    }
    else {
        dispatch_group_enter(group);
        
        if (assetsGroup.alAssetsGroup) {
            __block ALAssetsGroup *alAssetsGroup = assetsGroup.alAssetsGroup;
            ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result) {
                    CCCAsset *asset = [CCCAsset cccAssetWithALAsset:result];
                    if (asset) {
                        [allAssetsArray addObject:asset];
                    }
                }
                else if (!result) {
                    [alAssetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
                    dispatch_group_leave(group);
                }
                
            };
            
            if (type == CCCAssetsFetchTypeImage) {
                [alAssetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
            }
            else if (type == CCCAssetsFetchTypeVideo) {
                [alAssetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
            }
            [alAssetsGroup enumerateAssetsUsingBlock:resultsBlock];
        }
        else {
            dispatch_group_leave(group);
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
        if (handler) {
            if (allAssetsArray.count > 0) {
                handler(allAssetsArray);
            }
            else {
                handler(nil);
            }
        }
    });
#if !__has_feature(objc_arc)
    dispatch_release(group);
#endif
}

/// 檢查陣列裡是否已存在一樣的asset
- (BOOL)_checkAssetIsAlreadyInArray:(NSArray *)assetsArray asset:(CCCAsset *)asset {
    if (!asset || !assetsArray) {
        return YES;
    }
    if (assetsArray.count == 0) {
        return NO;
    }
    
    NSArray *filteredArray = [assetsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier=%@", asset.identifier]];
    
    return (filteredArray.count > 0);
}

#pragma mark - MediaPlayer

/// 判斷是否是合法的mediaItem
+ (BOOL)isValidMediaItem:(MPMediaItem *)mpMediaItem {
    if (!mpMediaItem) {
        return NO;
    }
    
    if ([mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL]) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL]];
        if (playerItem == nil) {
            return NO;
        }
        else if (playerItem.asset.hasProtectedContent) {
            return NO;
        }
    }
    else {
        return NO;
    }
    
    return YES;
}

#pragma mark - UIImage

+ (UIImage *)resizeAspectFillImage:(UIImage *)image maxSize:(CGFloat)max {
    // use ImageIO to get a thumbnail for a file at a given path
    
    if(!image){
        return nil;
    }
    
    CGSize imageSize = image.size;
    CGFloat scale = max/MIN(imageSize.width, imageSize.height);
    max = scale*MAX(imageSize.width, imageSize.height);
    
    CGImageSourceRef imageSource = NULL;
    CGImageRef resizeImage = NULL;
    
    /*********在這裡壓縮圖片沒什麼太大用處，存檔前再壓縮比較有用*********/
    NSData *jpeg = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
    
    // Create a CGImageSource from the URL.
    imageSource = CGImageSourceCreateWithData((CFDataRef)jpeg, NULL);
    if(imageSource == NULL) {
        return nil;
    }
    
    CFStringRef imageSourceType = CGImageSourceGetType(imageSource);
    if (imageSourceType == NULL) {
        CFRelease(imageSource);
        return nil;
    }
    CFRelease(imageSourceType);
    
    // create a thumbnail:
    // - specify max pixel size
    // - create the thumbnail with honoring the EXIF orientation flag (correct transform)
    // - always create the thumbnail from the full image (ignore the thumbnail that may be embedded in the image -
    //                                                  reason: our MAX_ICON_SIZE is larger than existing thumbnail)
    NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent : @YES,
                               (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                               (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(max) };
    //create thumbnail picture
    resizeImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    
    UIImage *img = [UIImage imageWithCGImage:resizeImage];
    
    CGImageRelease(resizeImage);
    CFRelease(imageSource);
    
    return img;
}

+ (UIImage *)resizeAspectFitImage:(UIImage *)image maxSize:(CGFloat)max {
    // use ImageIO to get a thumbnail for a file at a given path
    
    if(!image){
        return nil;
    }
    
    CGImageSourceRef imageSource = NULL;
    CGImageRef resizeImage = NULL;
    
    /*********在這裡壓縮圖片沒什麼太大用處，存檔前再壓縮比較有用*********/
    NSData *jpeg = [NSData dataWithData:UIImageJPEGRepresentation(image, 1.0)];
    
    // Create a CGImageSource from the URL.
    imageSource = CGImageSourceCreateWithData((CFDataRef)jpeg, NULL);
    if(imageSource == NULL) {
        return nil;
    }
    
    CFStringRef imageSourceType = CGImageSourceGetType(imageSource);
    if (imageSourceType == NULL) {
        CFRelease(imageSource);
        return nil;
    }
    CFRelease(imageSourceType);
    
    // create a thumbnail:
    // - specify max pixel size
    // - create the thumbnail with honoring the EXIF orientation flag (correct transform)
    // - always create the thumbnail from the full image (ignore the thumbnail that may be embedded in the image -
    //                                                  reason: our MAX_ICON_SIZE is larger than existing thumbnail)
    NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent : @YES,
                               (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                               (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(max) };
    //create thumbnail picture
    resizeImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
    
    UIImage *img = [UIImage imageWithCGImage:resizeImage];
    
    CGImageRelease(resizeImage);
    CFRelease(imageSource);
    
    return img;
}

+ (UIImage *)createSquareImageFromImage:(UIImage *)image {
    CGSize imageSize = image.size;
    if (imageSize.width == imageSize.height) {
        return image;
    }
    
    CGFloat croppedSize = MIN(imageSize.width, imageSize.height);
    CGRect cropRect = {CGPointZero, {croppedSize, croppedSize}};
    cropRect.origin.x = (imageSize.width-croppedSize)/2.0;
    cropRect.origin.y = (imageSize.height-croppedSize)/2.0;
    
    return [self _croppedImage:image InRect:cropRect];
}

+ (UIImage *)_croppedImage:(UIImage *)orignialImage InRect:(CGRect)visibleRect {
    //transform visible rect to image orientation
    CGAffineTransform rectTransform = [self _orientationTransformedRectOfImage:orignialImage];
    visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);
    
    //將數值整數化
    visibleRect = CGRectMake(roundf(CGRectGetMinX(visibleRect)), roundf(CGRectGetMinY(visibleRect)), roundf(CGRectGetWidth(visibleRect)), roundf(CGRectGetHeight(visibleRect)));
    
    //crop image
    CGImageRef imageRef = CGImageCreateWithImageInRect([orignialImage CGImage], visibleRect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:orignialImage.scale orientation:orignialImage.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

+ (CGAffineTransform)_orientationTransformedRectOfImage:(UIImage *)img {
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    return CGAffineTransformScale(rectTransform, img.scale, img.scale);
}

@end
