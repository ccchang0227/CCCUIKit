//
//  CCCAsset.m
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAsset.h"
#import "CCCAssetsModel.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <MediaPlayer/MediaPlayer.h>


@interface CCCAsset ()

@property (retain, nonatomic) UIImage *aspectRatioThumbImage;

- (instancetype)_initWithTitle:(NSString *)title identifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

@end

@implementation CCCAsset

- (instancetype)_initWithTitle:(NSString *)title identifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _assetType = CCCAssetTypeUnknown;
        
        _title = [title copy];
        _identifier = [identifier copy];
        
        _alAsset = nil;
        _phAsset = nil;
        _mpMediaItem = nil;
    }
    return self;
}

+ (instancetype)cccAssetWithALAsset:(ALAsset *)alAsset {
    return [[[[self class] alloc] initWithALAsset:alAsset] autorelease];
}

- (instancetype)initWithALAsset:(ALAsset *)alAsset {
    self = [super init];
    if (self) {
        _alAsset = [alAsset retain];
        
        if (alAsset) {
            _title = [alAsset.defaultRepresentation.filename copy];
            _identifier = [alAsset.defaultRepresentation.url.absoluteString copy];
            
            NSString *assetType = [alAsset valueForProperty:ALAssetPropertyType];
            if ([assetType isEqualToString:ALAssetTypePhoto]) {
                _assetType = CCCAssetTypeImage;
            }
            else if ([assetType isEqualToString:ALAssetTypeVideo]) {
                _assetType = CCCAssetTypeVideo;
            }
            else {
                _assetType = CCCAssetTypeUnknown;
            }
        }
        else {
            _assetType = CCCAssetTypeUnknown;
            _title = nil;
            _identifier = nil;
        }
        
    }
    return self;
}

+ (instancetype)cccAssetWithPHAsset:(PHAsset *)phAsset {
    return [[[[self class] alloc] initWithPHAsset:phAsset] autorelease];
}

- (instancetype)initWithPHAsset:(PHAsset *)phAsset {
    self = [super init];
    if (self) {
        _phAsset = [phAsset retain];
        
        if (phAsset) {
            _identifier = [phAsset.localIdentifier copy];
            
            [self _fetchPhotoInfo:phAsset];
        }
        else {
            _assetType = CCCAssetTypeUnknown;
            _title = nil;
            _identifier = nil;
        }
    }
    return self;
}

+ (instancetype)cccAssetWithMPMediaItem:(MPMediaItem *)mpMediaItem {
    return [[[[self class] alloc] initWithMPMediaItem:mpMediaItem] autorelease];
}

- (instancetype)initWithMPMediaItem:(MPMediaItem *)mpMediaItem {
    self = [super init];
    if (self) {
        if (![CCCAssetsModel isValidMediaItem:mpMediaItem]) {
            return nil;
        }
        
        _mpMediaItem = [mpMediaItem retain];
        
        if (mpMediaItem) {
            _assetType = CCCAssetTypeVideo;
            if ([mpMediaItem respondsToSelector:@selector(title)]) {
                _title = [mpMediaItem.title copy];
            }
            else {
                _title = [[mpMediaItem valueForProperty:MPMediaItemPropertyTitle] copy];
            }
            
            if ([mpMediaItem respondsToSelector:@selector(assetURL)]) {
                _identifier = [mpMediaItem.assetURL.absoluteString copy];
            }
            else {
                _identifier = [[[mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL] absoluteString] copy];
            }
            
        }
        else {
            _assetType = CCCAssetTypeUnknown;
            _title = nil;
            _identifier = nil;
        }
    }
    return self;
}

- (instancetype)init {
    self = [self _initWithTitle:nil identifier:nil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_title release];
    [_identifier release];
    [_alAsset release];
#ifdef Photos_Photos_h
    [_phAsset release];
#endif
    [_mpMediaItem release];
    [_aspectRatioThumbImage release];
    [super dealloc];
#endif
    
}


- (NSString *)description {
    NSMutableString *strDescription = [NSMutableString stringWithFormat:@"<%@", [super description]];
    
    NSDictionary *typeMapping = @{@(CCCAssetTypeImage):@"Image",
                                  @(CCCAssetTypeVideo):@"Video",
                                  @(CCCAssetTypeUnknown):@"Unknown"};
    
    [strDescription appendFormat:@" title=%@", _title];
    [strDescription appendFormat:@", identifier=%@", _identifier];
    [strDescription appendFormat:@", assetType=%@", [typeMapping objectForKey:@(_assetType)]];
    [strDescription appendFormat:@", alAsset=%@", _alAsset];
#ifdef Photos_Photos_h
    [strDescription appendFormat:@", phAsset=%@", _phAsset];
#endif
    [strDescription appendFormat:@", mpMediaItem=%@", _mpMediaItem];
    [strDescription appendString:@">"];
    
    return strDescription;
}

- (NSString *)debugDescription {
    return [self description];
}

#pragma mark -

// 讀取真實檔案的URL
- (NSURL *)loadAssetURLWithHandler:(void(^)(NSURL *assetURL))handler {
    if (_alAsset || _mpMediaItem) {
        NSURL *url = [NSURL URLWithString:_identifier];
        if (!url) {
            url = [NSURL fileURLWithPath:_identifier];
        }
        return url;
    }
    
    if (NSClassFromString(@"PHAsset")) {
        if (_phAsset) {
            if (_phAsset.mediaType == PHAssetMediaTypeImage) {
                PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
                options.canHandleAdjustmentData = ^(PHAdjustmentData *adjustmentData) {
                    return YES;
                };
                
                [_phAsset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        if (contentEditingInput) {
                            if (handler) {
                                handler(contentEditingInput.fullSizeImageURL);
                            }
                        }
                        else {
                            if (handler) {
                                handler(nil);
                            }
                        }
                    });
                    
                    
                }];
                
#if !__has_feature(objc_arc)
                [options release];
#endif
            }
            else if (_phAsset.mediaType == PHAssetMediaTypeVideo) {
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.version = PHVideoRequestOptionsVersionOriginal;
                
                PHImageManager *imageManager = [PHImageManager defaultManager];
                [imageManager requestAVAssetForVideo:_phAsset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        if (asset && [asset isKindOfClass:[AVURLAsset class]]) {
                            if (handler) {
                                handler(((AVURLAsset *)asset).URL);
                            }
                        }
                        else {
                            if (handler) {
                                handler(nil);
                            }
                        }
                        
                    });
                    
                }];
                
#if !__has_feature(objc_arc)
                [options release];
#endif
            }
        }
    }
    
    return nil;
}

// 讀取矩形縮圖
- (UIImage *)loadSquareThumbImageInOperationQueue:(NSOperationQueue *)operationQueue withHandler:(void(^)(UIImage *thumbImage))handler {
    if (_alAsset) {
        return [UIImage imageWithCGImage:_alAsset.thumbnail];
    }
    
    UIImage *thumbImage = nil;
    
    if (NSClassFromString(@"PHAsset")) {
        if (_phAsset) {
            if (operationQueue) {
                if (operationQueue.isSuspended) {
                    [operationQueue setSuspended:NO];
                }
                
                [operationQueue addOperationWithBlock:^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                    imageRequestOptions.synchronous = YES;
                    
                    [imageManager requestImageForAsset:_phAsset targetSize:CGSizeMake(150, 150) contentMode:PHImageContentModeAspectFit options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = [CCCAssetsModel createSquareImageFromImage:result];
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                            if (handler) {
                                handler(image);
                            }
                        }];
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                }];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                    imageRequestOptions.synchronous = YES;
                    
                    [imageManager requestImageForAsset:_phAsset targetSize:CGSizeMake(150, 150) contentMode:PHImageContentModeAspectFit options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = [CCCAssetsModel createSquareImageFromImage:result];
                        
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            if (handler) {
                                handler(image);
                            }
                        });
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                });
            }
        }
    }
    
    if (_mpMediaItem) {
        if (_aspectRatioThumbImage) {
            thumbImage = _aspectRatioThumbImage;
            thumbImage = [CCCAssetsModel createSquareImageFromImage:thumbImage];
        }
        else {
            NSURL *url = [_mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
            if (url && url.absoluteString.length > 0) {
                
                if (operationQueue) {
                    if (operationQueue.isSuspended) {
                        [operationQueue setSuspended:NO];
                    }
                    
                    [operationQueue addOperationWithBlock:^ {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                        AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                        imgGenerator.appliesPreferredTrackTransform = YES;
                        CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                        CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                        if (cgImage) {
                            UIImage *image = [UIImage imageWithCGImage:cgImage];
                            CGImageRelease(cgImage);
                            cgImage = NULL;
                            
                            image = [CCCAssetsModel resizeAspectFitImage:image maxSize:150];
#if !__has_feature(objc_arc)
                            if (_aspectRatioThumbImage) {
                                [_aspectRatioThumbImage release];
                            }
#endif
                            _aspectRatioThumbImage = [image retain];
                            image = [CCCAssetsModel createSquareImageFromImage:_aspectRatioThumbImage];
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                if (handler) {
                                    handler(image);
                                }
                            }];
                        }
                    }];
                }
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                        AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                        imgGenerator.appliesPreferredTrackTransform = YES;
                        CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                        CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                        if (cgImage) {
                            UIImage *image = [UIImage imageWithCGImage:cgImage];
                            CGImageRelease(cgImage);
                            cgImage = NULL;
                            
                            image = [CCCAssetsModel resizeAspectFitImage:image maxSize:150];
#if !__has_feature(objc_arc)
                            if (_aspectRatioThumbImage) {
                                [_aspectRatioThumbImage release];
                            }
#endif
                            _aspectRatioThumbImage = [image retain];
                            image = [CCCAssetsModel createSquareImageFromImage:_aspectRatioThumbImage];
                            
                            dispatch_async(dispatch_get_main_queue(), ^ {
                                if (handler) {
                                    handler(image);
                                }
                            });
                        }
                    });
                }
            }
        }
    }
    
    return thumbImage;
}

// 讀取等比例縮圖
- (UIImage *)loadAspectRatioThumbImageInOperationQueue:(NSOperationQueue *)operationQueue withHandler:(void(^)(UIImage *thumbImage))handler {
    if (_alAsset) {
        return [UIImage imageWithCGImage:_alAsset.aspectRatioThumbnail];
    }
    
    UIImage *thumbImage = nil;
    
    if (NSClassFromString(@"PHAsset")) {
        if (_phAsset) {
            if (operationQueue) {
                if (operationQueue.isSuspended) {
                    [operationQueue setSuspended:NO];
                }
                
                [operationQueue addOperationWithBlock:^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                    imageRequestOptions.synchronous = YES;
                    
                    [imageManager requestImageForAsset:_phAsset targetSize:CGSizeMake(150, 150) contentMode:PHImageContentModeAspectFit options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = result;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                            if (handler) {
                                handler(image);
                            }
                        }];
                        
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                }];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
                    imageRequestOptions.synchronous = YES;
                    
                    [imageManager requestImageForAsset:_phAsset targetSize:CGSizeMake(150, 150) contentMode:PHImageContentModeAspectFit options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = result;
                        
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            if (handler) {
                                handler(image);
                            }
                        });
                        
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                });
            }
            
        }
    }
    
    if (_mpMediaItem) {
        if (_aspectRatioThumbImage) {
            thumbImage = _aspectRatioThumbImage;
        }
        else {
            NSURL *url = [_mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
            if (url && url.absoluteString.length > 0) {
                
                if (operationQueue) {
                    if (operationQueue.isSuspended) {
                        [operationQueue setSuspended:NO];
                    }
                    
                    [operationQueue addOperationWithBlock:^ {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                        AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                        imgGenerator.appliesPreferredTrackTransform = YES;
                        CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                        CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                        if (cgImage) {
                            UIImage *image = [UIImage imageWithCGImage:cgImage];
                            CGImageRelease(cgImage);
                            cgImage = NULL;
                            
                            image = [CCCAssetsModel resizeAspectFitImage:image maxSize:150];
#if !__has_feature(objc_arc)
                            if (_aspectRatioThumbImage) {
                                [_aspectRatioThumbImage release];
                            }
#endif
                            _aspectRatioThumbImage = [image retain];
                            
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                if (handler) {
                                    handler(image);
                                }
                            }];
                        }
                    }];
                }
                else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                        AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                        imgGenerator.appliesPreferredTrackTransform = YES;
                        CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                        CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                        if (cgImage) {
                            UIImage *image = [UIImage imageWithCGImage:cgImage];
                            CGImageRelease(cgImage);
                            cgImage = NULL;
                            
                            image = [CCCAssetsModel resizeAspectFitImage:image maxSize:150];
#if !__has_feature(objc_arc)
                            if (_aspectRatioThumbImage) {
                                [_aspectRatioThumbImage release];
                            }
#endif
                            _aspectRatioThumbImage = [image retain];
                            
                            dispatch_async(dispatch_get_main_queue(), ^ {
                                if (handler) {
                                    handler(image);
                                }
                            });
                        }
                    });
                }
            }
        }
    }
    
    return thumbImage;
}

// 讀取原圖 (影片的話產生預覽圖)
- (UIImage *)loadLargeImageInOperationQueue:(NSOperationQueue *)operationQueue withHandler:(void(^)(UIImage *image))handler {
    if (_alAsset) {
        return [UIImage imageWithCGImage:_alAsset.defaultRepresentation.fullResolutionImage
                                   scale:_alAsset.defaultRepresentation.scale
                             orientation:(UIImageOrientation)_alAsset.defaultRepresentation.orientation];
    }
    
    UIImage *largeImage = nil;
    
    if (NSClassFromString(@"PHAsset")) {
        if (_phAsset) {
            if (operationQueue) {
                if (operationQueue.isSuspended) {
                    [operationQueue setSuspended:NO];
                }
                
                [operationQueue addOperationWithBlock:^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.version = PHImageRequestOptionsVersionOriginal;
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
                    imageRequestOptions.synchronous = YES;
                    
                    CGSize targetSize = PHImageManagerMaximumSize;
                    if (_assetType == CCCAssetTypeVideo) {
                        targetSize = CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
                    }
                    [imageManager requestImageForAsset:_phAsset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = result;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                            if (handler) {
                                handler(image);
                            }
                        }];
                        
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                }];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    PHImageManager *imageManager = [PHImageManager defaultManager];
                    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
                    imageRequestOptions.version = PHImageRequestOptionsVersionOriginal;
                    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
                    imageRequestOptions.synchronous = YES;
                    
                    CGSize targetSize = PHImageManagerMaximumSize;
                    if (_assetType == CCCAssetTypeVideo) {
                        targetSize = CGSizeMake(_phAsset.pixelWidth, _phAsset.pixelHeight);
                    }
                    [imageManager requestImageForAsset:_phAsset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:imageRequestOptions resultHandler:^(UIImage *result, NSDictionary *info) {
                        
                        UIImage *image = result;
                        
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            if (handler) {
                                handler(image);
                            }
                        });
                        
                    }];
                    
#if !__has_feature(objc_arc)
                    [imageRequestOptions release];
#endif
                });
            }
            
        }
    }
    
    if (_mpMediaItem) {
        NSURL *url = [_mpMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
        if (url && url.absoluteString.length > 0) {
            
            if (operationQueue) {
                if (operationQueue.isSuspended) {
                    [operationQueue setSuspended:NO];
                }
                
                [operationQueue addOperationWithBlock:^ {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                    imgGenerator.appliesPreferredTrackTransform = YES;
                    CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                    CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                    if (cgImage) {
                        UIImage *image = [UIImage imageWithCGImage:cgImage];
                        CGImageRelease(cgImage);
                        cgImage = NULL;
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                            if (handler) {
                                handler(image);
                            }
                        }];
                    }
                }];
            }
            else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
                    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                    imgGenerator.appliesPreferredTrackTransform = YES;
                    CMTime time = CMTimeMake(asset.duration.value*0.1, asset.duration.timescale); //kCMTimeZero
                    CGImageRef cgImage = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:nil];
                    if (cgImage) {
                        UIImage *image = [UIImage imageWithCGImage:cgImage];
                        CGImageRelease(cgImage);
                        cgImage = NULL;
                        
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            if (handler) {
                                handler(image);
                            }
                        });
                    }
                });
            }
        }
    }
    
    return largeImage;
}

- (AVPlayerItem *)loadPlayerItemWithHandler:(void(^)(AVPlayerItem *playerItem))handler {
    if (_assetType != CCCAssetTypeVideo) {
        return nil;
    }
    
    if (_alAsset) {
        NSURL *url = [NSURL URLWithString:_identifier];
        if (!url) {
            url = [NSURL fileURLWithPath:_identifier];
        }
        return [AVPlayerItem playerItemWithURL:url];
    }
    
    if (NSClassFromString(@"PHAsset")) {
        if (_phAsset) {
            PHImageManager *imageManager = [PHImageManager defaultManager];
            [imageManager requestPlayerItemForVideo:_phAsset options:nil resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (handler) {
                        handler(playerItem);
                    }
                });
                
            }];
        }
    }
    
    if (_mpMediaItem) {
        NSURL *url = [NSURL URLWithString:_identifier];
        if (!url) {
            url = [NSURL fileURLWithPath:_identifier];
        }
        return [AVPlayerItem playerItemWithURL:url];
    }
    
    return nil;
}

#pragma mark - Photos

- (void)_fetchPhotoInfo:(PHAsset *)phAsset {
    if (!phAsset) {
        _title = nil;
        _assetType = CCCAssetTypeUnknown;
        return;
    }
    
    // get file name
    _title = [[phAsset valueForKey:@"filename"] copy];
    
    // get type
    if (phAsset.mediaType == PHAssetMediaTypeImage) {
        _assetType = CCCAssetTypeImage;
    }
    else if (phAsset.mediaType == PHAssetMediaTypeVideo) {
        _assetType = CCCAssetTypeVideo;
    }
    else {
        _assetType = CCCAssetTypeUnknown;
    }
}

@end
