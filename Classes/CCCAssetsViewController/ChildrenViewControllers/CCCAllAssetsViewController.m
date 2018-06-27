//
//  CCCAllAssetsViewController.m
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAllAssetsViewController.h"
#import "CCCAssetPreviewView.h"

//#import "UIImageEffects.h"

#import <objc/NSObject.h>

#if TARGET_IPHONE_SIMULATOR
@import ObjectiveC.objc;
#endif

CGFloat const allAssetsCollectionViewFooterHeight = 80.0;

@interface CCCAllAssetsViewController () <UIViewControllerPreviewingDelegate, CCCAssetCollectionViewCellDelegate> {
    CGSize _itemSize;
}
+ (UIViewController *)topViewController;
@end

@implementation CCCAllAssetsViewController
@synthesize operationQueue = _operationQueue;

- (void)_setup {
    _collectionViewFooterHidden = NO;
    
    _numberOfPhotos = 0;
    _numberOfVideos = 0;
    
    _showPreviewOnLongPress = YES;
    _longPressDuration = 0.8;
}

- (instancetype)init {
    self = [super initWithNibName:@"CCCAllAssetsViewController" bundle:[NSBundle bundleForClass:[CCCAllAssetsViewController class]]];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.assetsCollectionView.delegate = self;
    self.assetsCollectionView.dataSource = self;
    [self.assetsCollectionView registerClass:[CCCAssetCollectionViewCell class] forCellWithReuseIdentifier:@"CCCAssetCollectionViewCell"];
    [self.assetsCollectionView registerClass:[CCCAllAssetsCollectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"CCCAllAssetsCollectionFooterView"];
    
    if ([self respondsToSelector:@selector(traitCollection)]) {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                [self registerForPreviewingWithDelegate:self sourceView:self.assetsCollectionView];
            }
        }
    }
    
    
    _itemSize = CGSizeZero;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_operationQueue cancelAllOperations];
    [_operationQueue setSuspended:YES];
    
#if !__has_feature(objc_arc)
    [_allAssetsArray release];
    [_operationQueue release];
    [_assetsCollectionView release];
    [super dealloc];
#endif
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGSize itemSize = CGSizeZero;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        itemSize = CGSizeMake(120, 120);
    }
    else {
        CGFloat padding = 5.0;
        CGFloat collectionViewWidth = CGRectGetWidth(self.assetsCollectionView.bounds);
        if (collectionViewWidth > 0.0) {
            CGFloat maximumSize = 70.0;
            NSInteger itemCount = (collectionViewWidth-20+padding)/(padding+maximumSize);
            CGFloat size = (collectionViewWidth-20-(itemCount-1)*padding)/itemCount;
            
            itemSize = CGSizeMake(size, size);
        }
    }
    
    if (!CGSizeEqualToSize(itemSize, _itemSize) && !CGSizeEqualToSize(itemSize, CGSizeZero)) {
        _itemSize = itemSize;
        [self.assetsCollectionView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_operationQueue) {
        [_operationQueue setSuspended:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_operationQueue) {
        [_operationQueue cancelAllOperations];
        [_operationQueue setSuspended:YES];
    }
}

#pragma mark - Setter

- (void)setAllAssetsArray:(NSArray<CCCAsset *> *)allAssetsArray {
    if (_allAssetsArray != allAssetsArray) {
#if !__has_feature(objc_arc)
        if (_allAssetsArray) {
            [_allAssetsArray release];
        }
        _allAssetsArray = [allAssetsArray retain];
#else
        _allAssetsArray = allAssetsArray;
#endif
        
        NSArray *filteredPhotosArray = [allAssetsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"assetType=%ld", (long)CCCAssetTypeImage]];
        _numberOfPhotos = filteredPhotosArray.count;
        
        NSArray *filteredVideosArray = [allAssetsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"assetType=%ld", (long)CCCAssetTypeVideo]];
        _numberOfVideos = filteredVideosArray.count;
    }
}

- (void)setCollectionViewFooterHidden:(BOOL)collectionViewFooterHidden {
    if (_collectionViewFooterHidden != collectionViewFooterHidden) {
        _collectionViewFooterHidden = collectionViewFooterHidden;
        
        [self.assetsCollectionView reloadData];
    }
}

#pragma mark - Getter

- (NSOperationQueue *)operationQueue {
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 4;
        [_operationQueue setSuspended:NO];
    }
    
    return _operationQueue;
}

#pragma mark -

- (void)reloadData {
    [self.assetsCollectionView reloadData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.allAssetsArray.count > 0) {
            CGFloat offsetY = self.assetsCollectionView.contentSize.height-CGRectGetHeight(self.assetsCollectionView.frame);
            offsetY = MAX(offsetY, 0);
            [self.assetsCollectionView setContentOffset:CGPointMake(0, offsetY) animated:NO];
        }
        else {
            self.assetsCollectionView.contentOffset = CGPointZero;
        }
    });
}

- (UIImage *)_loadThumbImageWithAsset:(CCCAsset *)asset atIndexPath:(NSIndexPath *)indexPath {
    if (!asset || !indexPath) {
        return nil;
    }
    
    UIImage *thumbImage = nil;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        thumbImage = [asset loadAspectRatioThumbImageInOperationQueue:self.operationQueue withHandler:^(UIImage *image) {
            
            if (indexPath.item < self.allAssetsArray.count) {
                CCCAssetCollectionViewCell *cell = (CCCAssetCollectionViewCell *)[self.assetsCollectionView cellForItemAtIndexPath:indexPath];
                if (cell && [cell isKindOfClass:[CCCAssetCollectionViewCell class]]) {
                    cell.assetThumbImageView.image = image;
                    [cell adjustVideoSymbolPosition];
                }
                else {
                    [self.assetsCollectionView performBatchUpdates:^ {
                        [self.assetsCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }completion:nil];
                }
            }
            
        }];
    }
    else {
        thumbImage = [asset loadSquareThumbImageInOperationQueue:self.operationQueue withHandler:^(UIImage *image) {
            
            if (indexPath.item < self.allAssetsArray.count) {
                CCCAssetCollectionViewCell *cell = (CCCAssetCollectionViewCell *)[self.assetsCollectionView cellForItemAtIndexPath:indexPath];
                if (cell && [cell isKindOfClass:[CCCAssetCollectionViewCell class]]) {
                    cell.assetThumbImageView.image = image;
                    [cell adjustVideoSymbolPosition];
                }
                else {
                    [self.assetsCollectionView performBatchUpdates:^ {
                        [self.assetsCollectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }completion:nil];
                }
            }
            
        }];
    }
    
    return thumbImage;
}

- (UIImage *)_createBlurScreenImage {
    return nil;
    /*
    UIWindow *applicationWindow = [[UIApplication sharedApplication].delegate window];
    CGSize size = applicationWindow.bounds.size;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            size.width = CGRectGetHeight(applicationWindow.bounds);
            size.height = CGRectGetWidth(applicationWindow.bounds);
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(size, applicationWindow.opaque, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (orientation) {
            case UIInterfaceOrientationLandscapeLeft: {
                CGContextRotateCTM(context, M_PI_2);
                CGContextTranslateCTM(context, 0, -size.width);
                break;
            }
            case UIInterfaceOrientationLandscapeRight: {
                CGContextRotateCTM(context, -M_PI_2);
                CGContextTranslateCTM(context, -size.height, 0);
                break;
            }
            default:
                break;
        }
        
        size = applicationWindow.bounds.size;
    }
    
    if ([applicationWindow respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [applicationWindow drawViewHierarchyInRect:CGRectMake(0, 0, size.width, size.height) afterScreenUpdates:NO];
    }
    else {
        [applicationWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = [image applyBlurWithRadius:15.0
                             tintColor:[UIColor colorWithWhite:1.000 alpha:0.300]
                 saturationDeltaFactor:1.0
                             maskImage:nil];
    
    return image;
    */
}

- (void)_showPreviewWithAsset:(CCCAsset *)asset {
    if (!_showPreviewOnLongPress) {
        return;
    }
    if (!asset) {
        return;
    }
    
    if (asset.assetType == CCCAssetTypeVideo) {
        AVPlayerItem *playerItem = [asset loadPlayerItemWithHandler:^(AVPlayerItem *playerItem) {
            
            if (playerItem && !self.assetPreviewView.superview) {
                self.assetPreviewView.playerItem = playerItem;
                
                UIImage *backgroundImage = [self _createBlurScreenImage];
                self.assetPreviewView.backgroundImage = backgroundImage;
                
                UIView *topView = [CCCAllAssetsViewController topViewController].view;
                self.assetPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
                [topView addSubview:self.assetPreviewView];
                [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
                [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
            }
            
        }];
        
        if (playerItem) {
            self.assetPreviewView.playerItem = playerItem;
            
            UIImage *backgroundImage = [self _createBlurScreenImage];
            self.assetPreviewView.backgroundImage = backgroundImage;
            
            UIView *topView = [CCCAllAssetsViewController topViewController].view;
            self.assetPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
            [topView addSubview:self.assetPreviewView];
            [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
            [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
        }
    }
    else {
        UIImage *largeImage = [asset loadLargeImageInOperationQueue:self.operationQueue withHandler:^(UIImage *image) {
            
            if (image && !self.assetPreviewView.superview) {
                self.assetPreviewView.assetLargeImage = image;
                
                UIImage *backgroundImage = [self _createBlurScreenImage];
                self.assetPreviewView.backgroundImage = backgroundImage;
                
                UIView *topView = [CCCAllAssetsViewController topViewController].view;
                self.assetPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
                [topView addSubview:self.assetPreviewView];
                [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
                [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
            }
            
        }];
        
        if (largeImage) {
            self.assetPreviewView.assetLargeImage = largeImage;
            
            UIImage *backgroundImage = [self _createBlurScreenImage];
            self.assetPreviewView.backgroundImage = backgroundImage;
            
            UIView *topView = [CCCAllAssetsViewController topViewController].view;
            self.assetPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
            [topView addSubview:self.assetPreviewView];
            [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
            [topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_assetPreviewView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetPreviewView)]];
        }
    }
    
}

#pragma mark - Override Methods

- (void)didPickAsset:(CCCAsset *)asset {
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allAssetsArray.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"CCCAssetCollectionViewCell";
    CCCAssetCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.item >= self.allAssetsArray.count) {
        cell.assetThumbImageView.image = nil;
        return cell;
    }
    
    if (![NSProtocolFromString(@"UICollectionViewDelegate") respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
        
        cell.delegate = self;
        cell.indexPath = indexPath;
        
        cell.longPressGestureRecognizer.minimumPressDuration = _longPressDuration;
        
        CCCAsset *asset = [self.allAssetsArray objectAtIndex:indexPath.item];
        cell.videoSymbolImageView.hidden = !(asset.assetType == CCCAssetTypeVideo);
        
        cell.assetThumbImageView.image = [self _loadThumbImageWithAsset:asset atIndexPath:indexPath];
        [cell adjustVideoSymbolPosition];
        
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (indexPath.item >= self.allAssetsArray.count) {
        return;
    }
    
    CCCAsset *asset = [self.allAssetsArray objectAtIndex:indexPath.item];
    
    [self didPickAsset:asset];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAllAssetsViewController:didPickAsset:)]) {
        [self.delegate cccAllAssetsViewController:self didPickAsset:asset];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[CCCAssetCollectionViewCell class]]) {
        CCCAssetCollectionViewCell *assetCell = (CCCAssetCollectionViewCell*)cell;
        assetCell.delegate = self;
        assetCell.indexPath = indexPath;
        
        assetCell.longPressGestureRecognizer.minimumPressDuration = _longPressDuration;
        
        if (indexPath.item >= self.allAssetsArray.count) {
            assetCell.assetThumbImageView.image = nil;
            return;
        }
        
        CCCAsset *asset = [self.allAssetsArray objectAtIndex:indexPath.item];
        assetCell.videoSymbolImageView.hidden = !(asset.assetType == CCCAssetTypeVideo);
        
        assetCell.assetThumbImageView.image = [self _loadThumbImageWithAsset:asset atIndexPath:indexPath];
        [assetCell adjustVideoSymbolPosition];
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([cell isKindOfClass:[CCCAssetCollectionViewCell class]]) {
        ((CCCAssetCollectionViewCell*)cell).indexPath = nil;
        ((CCCAssetCollectionViewCell*)cell).assetThumbImageView.image = nil;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        CCCAllAssetsCollectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"CCCAllAssetsCollectionFooterView" forIndexPath:indexPath];
        
        switch (_assetsFetchType) {
            case CCCAssetsFetchTypeImage: {
                footerView.allAssetsInfoLabel.text = [NSString stringWithFormat:@"%ld %@", (unsigned long)_numberOfPhotos, NSLocalizedString(@"Photos", nil)];
                break;
            }
            case CCCAssetsFetchTypeVideo: {
                footerView.allAssetsInfoLabel.text = [NSString stringWithFormat:@"%ld %@", (unsigned long)_numberOfVideos, NSLocalizedString(@"Videos", nil)];
                break;
            }
            case CCCAssetsFetchTypeBoth: {
                footerView.allAssetsInfoLabel.text = [NSString stringWithFormat:@"%ld %@, %ld %@", (unsigned long)_numberOfPhotos, NSLocalizedString(@"Photos", nil), (unsigned long)_numberOfVideos, NSLocalizedString(@"Videos", nil)];
                break;
            }
            default:
                break;
        }
        
        return footerView;
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    CCCAssetCollectionViewCell *cell = (CCCAssetCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setHighlighted:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    CCCAssetCollectionViewCell *cell = (CCCAssetCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    [cell setHighlighted:NO];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _itemSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    
    if (_collectionViewFooterHidden) {
        return CGSizeZero;
    }
    
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), allAssetsCollectionViewFooterHeight);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma mark - CCCAssetCollectionViewCellDelegate

- (BOOL)cccAssetCollectionViewCellShouldBeginLongPress:(CCCAssetCollectionViewCell *)cell {
    return _showPreviewOnLongPress;
}

- (void)cccAssetCollectionViewCellDidBeginLongPress:(CCCAssetCollectionViewCell *)cell {
    NSIndexPath *indexPath = cell.indexPath;
    if (indexPath) {
        if (indexPath.item < self.allAssetsArray.count) {
            CCCAsset *asset = [self.allAssetsArray objectAtIndex:indexPath.item];
            
            [self _showPreviewWithAsset:asset];
        }
    }
}

- (void)cccAssetCollectionViewCellDidEndLongPress:(CCCAssetCollectionViewCell *)cell {
    
}

#pragma mark - UIViewControllerPreviewingDelegate (3D-Touch)

- (UIViewController*)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    
}

#pragma mark - Find TopViewController

+ (UIViewController *)topViewController {
    return [self topViewController:[[UIApplication sharedApplication].delegate window].rootViewController];
}

+ (UIViewController *)topViewController:(UIViewController *)rootViewController {
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end


@interface CCCAssetCollectionViewCell () <UIGestureRecognizerDelegate>

@property (retain, nonatomic) UIView *highlightedMaskView;

@property (retain, nonatomic) NSLayoutConstraint *videoSymbolTrailingConstraint;
@property (retain, nonatomic) NSLayoutConstraint *videoSymbolBottomConstraint;

@end
@implementation CCCAssetCollectionViewCell
@synthesize longPressGestureRecognizer = _longPressGestureRecognizer;

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 縮圖
    _assetThumbImageView = [[UIImageView alloc] init];
    _assetThumbImageView.backgroundColor = [UIColor clearColor];
    _assetThumbImageView.clipsToBounds = YES;
    _assetThumbImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_assetThumbImageView];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        _assetThumbImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_assetThumbImageView]-(>=0)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetThumbImageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[_assetThumbImageView]-(>=0)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetThumbImageView)]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_assetThumbImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_assetThumbImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    }
    else {
        _assetThumbImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_assetThumbImageView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetThumbImageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_assetThumbImageView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_assetThumbImageView)]];
    }
    
    // 影片表示圖
    _videoSymbolImageView = [[UIImageView alloc] init];
    _videoSymbolImageView.backgroundColor = [UIColor clearColor];
    _videoSymbolImageView.contentMode = UIViewContentModeScaleAspectFit;
    _videoSymbolImageView.image = [UIImage imageNamed:@"CCCAssets_VideoIcon.png"];
    _videoSymbolImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_videoSymbolImageView];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_videoSymbolImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_videoSymbolImageView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_videoSymbolImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:24.0]];
    
    self.videoSymbolTrailingConstraint = [NSLayoutConstraint constraintWithItem:_videoSymbolImageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    self.videoSymbolBottomConstraint = [NSLayoutConstraint constraintWithItem:_videoSymbolImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.contentView addConstraints:@[self.videoSymbolTrailingConstraint, self.videoSymbolBottomConstraint]];
    
    // 點擊效果view
    _highlightedMaskView = [[UIView alloc] init];
    _highlightedMaskView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500];
    _highlightedMaskView.userInteractionEnabled = NO;
    _highlightedMaskView.alpha = 0.0;
    _highlightedMaskView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_highlightedMaskView];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_highlightedMaskView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_assetThumbImageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_highlightedMaskView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_assetThumbImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_highlightedMaskView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_assetThumbImageView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_highlightedMaskView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_assetThumbImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnCell:)];
    _longPressGestureRecognizer.minimumPressDuration = 0.5;
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_indexPath release];
    [_assetThumbImageView release];
    [_videoSymbolImageView release];
    [_highlightedMaskView release];
    [_videoSymbolTrailingConstraint release];
    [_videoSymbolBottomConstraint release];
    [_longPressGestureRecognizer release];
    [super dealloc];
#endif
    
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        _highlightedMaskView.alpha = 1.0;
    }
    else {
        [UIView animateWithDuration:0.25 animations:^ {
            _highlightedMaskView.alpha = 0.0;
        }];
    }
}

- (void)adjustVideoSymbolPosition {
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        if (self.assetThumbImageView.image) {
            CGRect fitRect = AVMakeRectWithAspectRatioInsideRect(self.assetThumbImageView.image.size, self.contentView.bounds);
            if (!CGRectEqualToRect(fitRect, CGRectZero)) {
                self.videoSymbolTrailingConstraint.constant = (CGRectGetWidth(fitRect)-CGRectGetWidth(self.contentView.bounds))/2.0;
                self.videoSymbolBottomConstraint.constant = (CGRectGetHeight(fitRect)-CGRectGetHeight(self.contentView.bounds))/2.0;
            }
            else {
                self.videoSymbolTrailingConstraint.constant = 0.0;
                self.videoSymbolBottomConstraint.constant = 0.0;
            }
        }
        else {
            self.videoSymbolTrailingConstraint.constant = 0.0;
            self.videoSymbolBottomConstraint.constant = 0.0;
        }
    }
    else {
        self.videoSymbolTrailingConstraint.constant = 0.0;
        self.videoSymbolBottomConstraint.constant = 0.0;
    }
}

#pragma mark - LongPress

- (void)longPressOnCell:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetCollectionViewCellDidBeginLongPress:)]) {
                [self.delegate cccAssetCollectionViewCellDidBeginLongPress:self];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetCollectionViewCellDidEndLongPress:)]) {
                [self.delegate cccAssetCollectionViewCellDidEndLongPress:self];
            }
            break;
        }
        default:
            break;
    }
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetCollectionViewCellShouldBeginLongPress:)]) {
        return [self.delegate cccAssetCollectionViewCellShouldBeginLongPress:self];
    }
    
    return YES;
}

@end


@implementation CCCAllAssetsCollectionFooterView

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];
    
    _allAssetsInfoLabel = [[UILabel alloc] init];
    _allAssetsInfoLabel.backgroundColor = [UIColor clearColor];
    _allAssetsInfoLabel.textColor = [UIColor blackColor];
    _allAssetsInfoLabel.textAlignment = NSTextAlignmentCenter;
    _allAssetsInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_allAssetsInfoLabel];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(10)-[_allAssetsInfoLabel]-(10)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_allAssetsInfoLabel)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_allAssetsInfoLabel]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_allAssetsInfoLabel)]];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        _allAssetsInfoLabel.font = [UIFont boldSystemFontOfSize:25.0];
    }
    else {
        _allAssetsInfoLabel.font = [UIFont boldSystemFontOfSize:20.0];
    }
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_allAssetsInfoLabel release];
    [super dealloc];
#endif
    
}

@end
