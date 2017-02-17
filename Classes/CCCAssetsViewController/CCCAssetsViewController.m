//
//  CCCAssetsViewController.m
//
//  Created by realtouchapp on 2016/1/16.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAssetsViewController.h"


@interface CCCAssetsViewController () {
    CGRect _bounds;
}

@property (retain, nonatomic) CCCAssetsGroup *selectedAssetsGroup;

@end

@implementation CCCAssetsViewController
@synthesize libraryNavigationController = _libraryNavigationController;
@synthesize assetsGroupsViewController = _assetsGroupsViewController;
@synthesize allAssetsViewController = _allAssetsViewController;

- (void)_setup {
    _assetsFetchType = CCCAssetsFetchTypeBoth;
}

- (instancetype)init {
    self = [super initWithNibName:@"CCCAssetsViewController" bundle:[NSBundle bundleForClass:[CCCAssetsViewController class]]];
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
    // Do any additional setup after loading the view.
    
    self.titleLabel.text = NSLocalizedString(@"相片/影片", nil);
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    
    self.titleLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapTitleLabelGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTitleLabelGesture:)];
    [self.titleLabel addGestureRecognizer:tapTitleLabelGesture];
#if !__has_feature(objc_arc)
    [tapTitleLabelGesture release];
#endif
    
    _bounds = CGRectZero;
    
    _model = [[CCCAssetsModel alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_model release];
    [_contentView release];
    [_titleView release];
    [_titleLabel release];
    [_closeButton release];
    [_backButton release];
    [_libraryContainerView release];
    [_libraryNavigationController release];
    [_assetsGroupsViewController release];
    [_allAssetsViewController release];
    [_titleViewHeightConstraint release];
    [_contentBottomSpaceConstraint release];
    [_selectedAssetsGroup release];
    [super dealloc];
#endif
    
}

- (void)viewWillLayoutSubviews {
    if (!CGRectEqualToRect(self.view.bounds, _bounds)) {
        self.titleViewHeightConstraint.constant = MIN(CGRectGetHeight(self.view.bounds)*0.09, 60.0);
        
        _bounds = self.view.bounds;
    }
    
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self _resetUI];
    [self _loadGroupData];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self _clearData];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark -

- (void)_loadGroupData {
    __block typeof(self) tempSelf = self;
    [tempSelf.model loadAssetsGroupsWithAssetFetchType:_assetsFetchType handler:^(NSArray<CCCAssetsGroup *> *assetsGroups) {
        
        if (tempSelf.isTopLibraryViewController) {
            if (assetsGroups && assetsGroups.count > 0) {
                tempSelf.assetsGroupsViewController.assetsgGroupsArray = assetsGroups;
                [tempSelf.assetsGroupsViewController reloadData];
            }
            else {
                [tempSelf _showNoData];
            }
        }
        
    }];
}

- (void)_loadAllAssetsDataInSelectedGroup {
    if (!_selectedAssetsGroup) {
        self.allAssetsViewController.allAssetsArray = nil;
        [self.allAssetsViewController reloadData];
        return;
    }
    
    __block typeof(self) tempSelf = self;
    [tempSelf.model loadAllAssetsFromGroup:tempSelf.selectedAssetsGroup withAssetFetchType:self.assetsFetchType handler:^(NSArray<CCCAsset *> *allAssets) {
        
        if (tempSelf.isTopLibraryViewController) {
            tempSelf.allAssetsViewController.allAssetsArray = allAssets;
            [tempSelf.libraryNavigationController pushViewController:tempSelf.allAssetsViewController animated:YES];
            
            [tempSelf.allAssetsViewController reloadData];
        }
        
    }];
}

- (void)_clearData {
    self.libraryNavigationController.delegate = nil;
    [self.libraryNavigationController popViewControllerAnimated:NO];
    
    self.assetsGroupsViewController.assetsgGroupsArray = nil;
    [self.assetsGroupsViewController reloadData];
    
    self.selectedAssetsGroup = nil;
    self.allAssetsViewController.allAssetsArray = nil;
    [self.allAssetsViewController reloadData];
    
    [self.libraryContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)_resetUI {
    self.libraryNavigationController.delegate = nil;
    
    [self.libraryNavigationController popViewControllerAnimated:NO];
    [self.libraryContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.backButton.hidden = YES;
    self.selectedAssetsGroup = nil;
    [self _setupTitle];
    
    if (self.model.isPhotoLibraryAuthorized) {
        self.assetsGroupsViewController.assetsgGroupsArray = nil;
        [self.assetsGroupsViewController reloadData];
        
        UIView *libraryView = self.libraryNavigationController.view;
        libraryView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.libraryContainerView addSubview:libraryView];
        
        [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[libraryView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(libraryView)]];
        [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[libraryView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(libraryView)]];
        
        self.libraryNavigationController.delegate = self;
    }
    else {
        [self _showNotAuthorizedInfo];
    }
}

- (void)_setupTitle {
    switch (_assetsFetchType) {
        case CCCAssetsFetchTypeImage:
            self.titleLabel.text = NSLocalizedString(@"相簿", nil);
            break;
        case CCCAssetsFetchTypeVideo:
            self.titleLabel.text = NSLocalizedString(@"影片", nil);
            break;
        case CCCAssetsFetchTypeBoth:
            self.titleLabel.text = NSLocalizedString(@"相片/影片", nil);
            break;
        default:
            break;
    }
}

- (void)_showNotAuthorizedInfo {
    [self.libraryContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (self.model.isPhotoLibraryAuthorized) {
        return;
    }
    
    UILabel *labelNotAuthorized = [[UILabel alloc] init];
    labelNotAuthorized.backgroundColor = [UIColor clearColor];
    labelNotAuthorized.font = [UIFont boldSystemFontOfSize:22.0];
    labelNotAuthorized.textColor = [UIColor blackColor];
    labelNotAuthorized.text = NSLocalizedString(@"App doesn't have permission to use Photos, please change privacy settings\n\nSettings->Privacy->Photos", nil);
    labelNotAuthorized.textAlignment = NSTextAlignmentCenter;
    labelNotAuthorized.numberOfLines = 0;
    labelNotAuthorized.lineBreakMode = NSLineBreakByWordWrapping;
    labelNotAuthorized.translatesAutoresizingMaskIntoConstraints = NO;
    [self.libraryContainerView addSubview:labelNotAuthorized];
    
    [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelNotAuthorized]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(labelNotAuthorized)]];
    [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelNotAuthorized]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(labelNotAuthorized)]];
    
    [labelNotAuthorized release];
}

- (void)_showNoData {
    [self.libraryContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (self.model.isPhotoLibraryAuthorized) {
        return;
    }
    
    UILabel *labelNoData = [[UILabel alloc] init];
    labelNoData.backgroundColor = [UIColor clearColor];
    labelNoData.font = [UIFont boldSystemFontOfSize:22.0];
    labelNoData.textColor = [UIColor blackColor];
    labelNoData.text = NSLocalizedString(@"無資料", nil);
    labelNoData.textAlignment = NSTextAlignmentCenter;
    labelNoData.numberOfLines = 0;
    labelNoData.lineBreakMode = NSLineBreakByWordWrapping;
    labelNoData.translatesAutoresizingMaskIntoConstraints = NO;
    [self.libraryContainerView addSubview:labelNoData];
    
    [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelNoData]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(labelNoData)]];
    [self.libraryContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelNoData]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(labelNoData)]];
    
    [labelNoData release];
}

#pragma mark - Override Methods

- (void)didSelectGroup:(CCCAssetsGroup *)assetsGroup {
    self.selectedAssetsGroup = assetsGroup;
    [self _loadAllAssetsDataInSelectedGroup];
}

- (void)didPickAsset:(CCCAsset *)asset {
}

#pragma mark - Setter

- (void)setAssetsFetchType:(CCCAssetsFetchType)assetsFetchType {
    if (_assetsFetchType != assetsFetchType) {
        _assetsFetchType = assetsFetchType;
        
        if (!self.isViewLoaded) {
            return;
        }
        
    }
}

#pragma mark - Getter

- (BOOL)isTopLibraryViewController {
    return (self.libraryNavigationController.viewControllers.count < 2);
}

- (UINavigationController *)libraryNavigationController {
    if (_libraryNavigationController == nil) {
        _libraryNavigationController = [[UINavigationController alloc] init];
        _libraryNavigationController.navigationBar.hidden = YES;
        [_libraryNavigationController setViewControllers:@[self.assetsGroupsViewController]];
        [self addChildViewController:_libraryNavigationController];
        
    }
    
    return _libraryNavigationController;
}

- (CCCAssetsGroupsViewController *)assetsGroupsViewController {
    if (_assetsGroupsViewController == nil) {
        _assetsGroupsViewController = [[CCCAssetsGroupsViewController alloc] initWithNibName:@"CCCAssetsGroupsViewController" bundle:[NSBundle bundleForClass:[CCCAssetsGroupsViewController class]]];
        _assetsGroupsViewController.delegate = self;
    }
    
    return _assetsGroupsViewController;
}

- (CCCAllAssetsViewController *)allAssetsViewController {
    if (_allAssetsViewController == nil) {
        _allAssetsViewController = [[CCCAllAssetsViewController alloc] initWithNibName:@"CCCAllAssetsViewController" bundle:[NSBundle bundleForClass:[CCCAllAssetsViewController class]]];
        _allAssetsViewController.delegate = self;
    }
    
    return _allAssetsViewController;
}

#pragma mark - Button Actions

- (IBAction)closeAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetsViewControllerDidCancel:)]) {
        [self.delegate cccAssetsViewControllerDidCancel:self];
    }
    else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)backAction:(id)sender {
    self.selectedAssetsGroup = nil;
    self.backButton.hidden = YES;
    
    [self.libraryNavigationController popViewControllerAnimated:YES];
}

#pragma mark - UIGestureRecognizer

- (void)tapTitleLabelGesture:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (!self.model.isPhotoLibraryAuthorized) {
            return;
        }
        
        if (self.isTopLibraryViewController) {
            [self.assetsGroupsViewController.assetsGroupsTableView setContentOffset:CGPointZero animated:YES];
        }
        else {
            CGFloat offsetY = self.allAssetsViewController.assetsCollectionView.contentSize.height-CGRectGetHeight(self.allAssetsViewController.assetsCollectionView.frame);
            offsetY = MAX(offsetY, 0);
            [self.allAssetsViewController.assetsCollectionView setContentOffset:CGPointMake(0, offsetY) animated:YES];
        }
    }
    
}

#pragma mark - UINavigationController

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (self.selectedAssetsGroup) {
        self.titleLabel.text = self.selectedAssetsGroup.groupName;
    }
    else {
        [self _setupTitle];
    }
    
    if (viewController == self.allAssetsViewController) {
        self.backButton.hidden = NO;
    }
    
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (self.isTopLibraryViewController) {
        self.backButton.hidden = YES;
        
        self.selectedAssetsGroup = nil;
        self.allAssetsViewController.allAssetsArray = nil;
        [self.allAssetsViewController reloadData];
        
        [self _setupTitle];
    }
    else {
        self.backButton.hidden = NO;
        
        if (self.selectedAssetsGroup) {
            self.titleLabel.text = self.selectedAssetsGroup.groupName;
        }
    }
    
}

#pragma mark - CCCAssetsGroupsViewControllerDelegate

- (void)cccAssetsGroupsViewController:(CCCAssetsGroupsViewController *)viewController didSelectGroup:(CCCAssetsGroup *)assetsGroup {
    
    [self didSelectGroup:assetsGroup];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetsViewController:didSelectGroup:)]) {
        [self.delegate cccAssetsViewController:self didSelectGroup:assetsGroup];
    }
}

#pragma mark - CCCAllAssetsViewControllerDelegate

- (void)cccAllAssetsViewController:(CCCAllAssetsViewController *)viewController didPickAsset:(CCCAsset *)asset {
    
    [self didPickAsset:asset];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetsViewController:didPickAsset:)]) {
        [self.delegate cccAssetsViewController:self didPickAsset:asset];
    }
}

#pragma mark - View controller rotation methods

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

@end
