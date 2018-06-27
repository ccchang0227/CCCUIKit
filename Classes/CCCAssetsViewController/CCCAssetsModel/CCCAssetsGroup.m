//
//  CCCAssetsGroup.m
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAssetsGroup.h"
#import "CCCAssetsModel.h"


@interface CCCAssetsGroup ()

- (instancetype)_initWithGroupName:(NSString *)name groupURL:(NSString *)URL posterImage:(UIImage *)posterImage NS_DESIGNATED_INITIALIZER;

@end

@implementation CCCAssetsGroup

- (void)_setup {
    _shouldIncludePhotos = YES;
    _shouldIncludeVideos = YES;
}

- (instancetype)_initWithGroupName:(NSString *)name groupURL:(NSString *)URL posterImage:(UIImage *)posterImage {
    self = [super init];
    if (self) {
        [self _setup];
        
        _groupName = [name copy];
        _groupURL = [URL copy];
        _posterImage = [posterImage retain];
        _numberOfPhotoAssets = 0;
        _numberOfVideoAssets = 0;
        
        _isAllVideosGroup = NO;
    }
    return self;
}

+ (instancetype)cccAssetsGroupWithALAssetsGroup:(ALAssetsGroup *)group isAllVideosGroup:(BOOL)isAllVideosGroup {
    return [[[[self class] alloc] initWithALAssetsGroup:group isAllVideosGroup:isAllVideosGroup] autorelease];
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)group isAllVideosGroup:(BOOL)isAllVideosGroup {
    self = [super init];
    if (self) {
        _alAssetsGroup = [group retain];
        _isAllVideosGroup = isAllVideosGroup;
        
        [self _setup];
        
        if (group) {
            if (!isAllVideosGroup) {
                _groupName = [[group valueForProperty:ALAssetsGroupPropertyName] copy];
                _groupURL = [[[group valueForProperty:ALAssetsGroupPropertyURL] absoluteString] copy];
                _numberOfPhotoAssets = 0;
                _numberOfVideoAssets = 0;
                
                [self _estimateAssetNumberForAssetsGroup:group];
            }
            else {
                _groupName = [NSLocalizedString(@"All Videos", nil) copy];
                _groupURL = [@"com.realtouchapp.cccassetgroup.videos" copy];
                _numberOfPhotoAssets = 0;
                _numberOfVideoAssets = 0;
            }
            
            UIImage *image = [UIImage imageWithCGImage:group.posterImage];
            image = [CCCAssetsModel createSquareImageFromImage:image];
            _posterImage = [image retain];
            
        }
        else {
            _numberOfPhotoAssets = 0;
            _numberOfVideoAssets = 0;
        }
    }
    return self;
}

+ (instancetype)cccAssetsGroupWithPHAssetCollection:(PHAssetCollection *)collection isAllVideosGroup:(BOOL)isAllVideosGroup {
    return [[[[self class] alloc] initWithPHAssetCollection:collection isAllVideosGroup:isAllVideosGroup] autorelease];
}

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection isAllVideosGroup:(BOOL)isAllVideosGroup {
    self = [super init];
    if (self) {
        _phAssetCollection = [collection retain];
        _isAllVideosGroup = isAllVideosGroup;
        
        [self _setup];
        
        if (collection) {
            if (!isAllVideosGroup) {
                _groupName = [collection.localizedTitle copy];
                _groupURL = [collection.localIdentifier copy];
                _numberOfPhotoAssets = 0;
                _numberOfVideoAssets = 0;
                
                [self _estimateAssetNumberForCollection:collection];
            }
            else {
                _groupName = [NSLocalizedString(@"All Videos", nil) copy];
                _groupURL = [@"com.realtouchapp.cccassetgroup.videos" copy];
                _numberOfPhotoAssets = 0;
                _numberOfVideoAssets = 0;
            }
            
            //[self _loadPosterImageFromPHAssetCollection:collection];
        }
        else {
            _numberOfPhotoAssets = 0;
            _numberOfVideoAssets = 0;
        }
    }
    return self;
}

+ (instancetype)cccAssetsGroupWithMPMediaItem:(MPMediaItem *)mediaItem {
    return [[[[self class] alloc] initWithMPMediaItem:mediaItem] autorelease];
}

- (instancetype)initWithMPMediaItem:(MPMediaItem *)mediaItem {
    self = [super init];
    if (self) {
        if (![CCCAssetsModel isValidMediaItem:mediaItem]) {
            return nil;
        }
        
        _isAllVideosGroup = YES;
        
        if (mediaItem) {
            _groupName = [NSLocalizedString(@"All Videos", nil) copy];
            _groupURL = [@"com.realtouchapp.cccassetgroup.videos" copy];
            _numberOfPhotoAssets = 0;
            _numberOfVideoAssets = 0;
            
            [self _loadPosterImageFromMPMediaItem:mediaItem];
        }
    }
    return self;
}

- (instancetype)init {
    self = [self _initWithGroupName:nil groupURL:nil posterImage:nil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_groupName release];
    [_groupURL release];
    [_posterImage release];
    [_alAssetsGroup release];
#ifdef Photos_Photos_h
    [_phAssetCollection release];
#endif
    [super dealloc];
#endif
    
}

- (NSString *)description {
    NSMutableString *strDescription = [NSMutableString stringWithFormat:@"<%@", [super description]];
    
    [strDescription appendFormat:@" groupName=%@", _groupName];
    [strDescription appendFormat:@", groupURL=%@", _groupURL];
    [strDescription appendFormat:@", numberOfPhotoAssets=%ld", (long)_numberOfPhotoAssets];
    [strDescription appendFormat:@", numberOfVideoAssets=%ld", (long)_numberOfVideoAssets];
    [strDescription appendFormat:@", posterImage=%@", _posterImage];
    [strDescription appendFormat:@", alAssetsGroup=%@", _alAssetsGroup];
#ifdef Photos_Photos_h
    [strDescription appendFormat:@", phAssetCollection=%@", _phAssetCollection];
#endif
    [strDescription appendString:@">"];
    
    return strDescription;
}

- (NSString *)debugDescription {
    return [self description];
}

#pragma mark - Setter

- (void)setShouldIncludePhotos:(BOOL)shouldIncludePhotos {
    if (_shouldIncludePhotos != shouldIncludePhotos) {
        _shouldIncludePhotos = shouldIncludePhotos;
        
        if (_alAssetsGroup) {
            [self _estimateAssetNumberForAssetsGroup:_alAssetsGroup];
        }
        else if (_phAssetCollection) {
            [self _estimateAssetNumberForCollection:_phAssetCollection];
        }
    }
}

- (void)setShouldIncludeVideos:(BOOL)shouldIncludeVideos {
    if (_shouldIncludeVideos != shouldIncludeVideos) {
        _shouldIncludeVideos = shouldIncludeVideos;
        
        if (_alAssetsGroup) {
            [self _estimateAssetNumberForAssetsGroup:_alAssetsGroup];
        }
        else if (_phAssetCollection) {
            [self _estimateAssetNumberForCollection:_phAssetCollection];
        }
    }
}

#pragma mark -

- (UIImage *)loadGroupPosterImageInOperationQueue:(NSOperationQueue *)operationQueue withHandler:(void(^)(UIImage *posterImage))handler {
    if (_alAssetsGroup) {
        return [UIImage imageWithCGImage:_alAssetsGroup.posterImage];
    }
    
    UIImage *posterImage = nil;
    
    if (NSClassFromString(@"PHAssetCollection")) {
        if (_phAssetCollection) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            if (_isAllVideosGroup) {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
            }
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            options.fetchLimit = 1;
            
            if (operationQueue) {
                if (operationQueue.isSuspended) {
                    [operationQueue setSuspended:NO];
                }
                
                [operationQueue addOperationWithBlock:^ {
                    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:_phAssetCollection options:options];
                    if (fetchResult.count > 0) {
                        PHAsset *phAsset = [fetchResult lastObject];
                        if (phAsset) {
                            PHImageManager *imageManager = [PHImageManager defaultManager];
                            PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                            imageRequestOptions.synchronous = YES;
                            
                            [imageManager requestImageForAsset:phAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                                
                                result = [CCCAssetsModel createSquareImageFromImage:result];
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                    if (handler) {
                                        handler (result);
                                    }
                                }];
                                
                            }];
                            
#if !__has_feature(objc_arc)
                            [imageRequestOptions release];
#endif
                        }
                    }
                }];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:_phAssetCollection options:options];
                    if (fetchResult.count > 0) {
                        PHAsset *phAsset = [fetchResult lastObject];
                        if (phAsset) {
                            PHImageManager *imageManager = [PHImageManager defaultManager];
                            PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                            imageRequestOptions.synchronous = YES;
                            
                            [imageManager requestImageForAsset:phAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                                
                                result = [CCCAssetsModel createSquareImageFromImage:result];
                                dispatch_async(dispatch_get_main_queue(), ^ {
                                    if (handler) {
                                        handler (result);
                                    }
                                });
                                
                            }];
                            
#if !__has_feature(objc_arc)
                            [imageRequestOptions release];
#endif
                        }
                    }
                });
            }
            
#if !__has_feature(objc_arc)
            [options release];
#endif
        }
    }
    
    if (_posterImage) {
        posterImage = _posterImage;
    }
    
    return posterImage;
}

#pragma mark - Photos

/// 讀取圖示
- (void)_loadPosterImageFromPHAssetCollection:(PHAssetCollection *)collection {
#if !__has_feature(objc_arc)
    if (_posterImage) {
        [_posterImage release];
    }
#endif
    if (!collection) {
        _posterImage = nil;
        return;
    }
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (_isAllVideosGroup) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
    }
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.fetchLimit = 1;
    
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    if (fetchResult.count > 0) {
        PHAsset *phAsset = [fetchResult lastObject];
        if (phAsset) {
            PHImageManager *imageManager = [PHImageManager defaultManager];
            PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
            imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
            imageRequestOptions.synchronous = YES;
            
            [imageManager requestImageForAsset:phAsset targetSize:CGSizeMake(200, 200) contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                
                result = [CCCAssetsModel createSquareImageFromImage:result];
                _posterImage = [result retain];
                
            }];
            
#if !__has_feature(objc_arc)
            [imageRequestOptions release];
#endif
        }
        else {
            _posterImage = nil;
        }
    }
    else {
        _posterImage = nil;
    }
    
#if !__has_feature(objc_arc)
    [options release];
#endif
    
}

+ (BOOL)collectionHasVideoAssets:(PHAssetCollection *)collection {
    if (!collection) {
        return NO;
    }
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
    
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
#if !__has_feature(objc_arc)
    [options release];
#endif
    
    return (fetchResult.count > 0);
}

+ (BOOL)collectionHasImageAssets:(PHAssetCollection *)collection {
    if (!collection) {
        return NO;
    }
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeImage];
    
    PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
#if !__has_feature(objc_arc)
    [options release];
#endif
    
    return (fetchResult.count > 0);
}

- (void)_estimateAssetNumberForCollection:(PHAssetCollection *)collection {
    if (!collection) {
        return;
    }
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    if (_shouldIncludePhotos) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeImage];
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        _numberOfPhotoAssets = fetchResult.count;
    }
    else {
        _numberOfPhotoAssets = 0;
    }
    
    if (_shouldIncludeVideos) {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType=%ld", (long)PHAssetMediaTypeVideo];
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        _numberOfVideoAssets = fetchResult.count;
    }
    else {
        _numberOfVideoAssets = 0;
    }
    
#if !__has_feature(objc_arc)
    [options release];
#endif
}

#pragma mark - ALAssetsGroup

+ (BOOL)assetsGroupHasVideoAssets:(ALAssetsGroup *)group {
    if (!group) {
        return NO;
    }
    
    [group setAssetsFilter:[ALAssetsFilter allVideos]];
    BOOL hasVideos = (group.numberOfAssets > 0);
    
    [group setAssetsFilter:[ALAssetsFilter allAssets]];
    
    return hasVideos;
}

+ (BOOL)assetsGroupHasImageAssets:(ALAssetsGroup *)group {
    if (!group) {
        return NO;
    }
    
    [group setAssetsFilter:[ALAssetsFilter allPhotos]];
    BOOL hasPhotos = (group.numberOfAssets > 0);
    
    [group setAssetsFilter:[ALAssetsFilter allAssets]];
    
    return hasPhotos;
}

- (void)_estimateAssetNumberForAssetsGroup:(ALAssetsGroup *)group {
    if (!group) {
        return;
    }
    
    if (_shouldIncludePhotos) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        _numberOfPhotoAssets = group.numberOfAssets;
    }
    else {
        _numberOfPhotoAssets = 0;
    }
    
    if (_shouldIncludeVideos) {
        [group setAssetsFilter:[ALAssetsFilter allVideos]];
        _numberOfVideoAssets = group.numberOfAssets;
    }
    else {
        _numberOfVideoAssets = 0;
    }
    
    [group setAssetsFilter:[ALAssetsFilter allAssets]];
}

#pragma mark - MediaPlayer

/// 謮取圖示
- (void)_loadPosterImageFromMPMediaItem:(MPMediaItem *)mediaItem {
#if !__has_feature(objc_arc)
    if (_posterImage) {
        [_posterImage release];
    }
#endif
    if (!mediaItem) {
        _posterImage = nil;
        return;
    }
    NSURL *url = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    if (!url || url.absoluteString.length == 0) {
        _posterImage = nil;
        return;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imgGenerator.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
    CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
    
    if (cgImage) {
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        image = [CCCAssetsModel resizeAspectFillImage:image maxSize:200];
        image = [CCCAssetsModel createSquareImageFromImage:image];
        
        _posterImage = [image retain];
        
        CFRelease(cgImage);
        cgImage = NULL;
    }
}

@end
