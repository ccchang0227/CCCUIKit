//
//  AssetsViewController.m
//  CCCUIKit
//
//  Created by realtouchapp on 2017/4/26.
//  Copyright © 2017年 realtouchapp. All rights reserved.
//

#import "AssetsViewController.h"
#import <CCCUIKit/CCCAssetsViewController.h>
#import "DisplayImageViewController.h"

@interface AssetsViewController () <CCCAssetsViewControllerDelegate>

@end

@implementation AssetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Assets";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark -

- (IBAction)showAssetsPicker:(UIButton*)sender {
    CCCAssetsViewController *viewCtrlAssets = [[CCCAssetsViewController alloc] initWithNibName:@"CCCAssetsViewController" bundle:nil];
    viewCtrlAssets.delegate = self;
    switch (sender.tag) {
        case 1:
            viewCtrlAssets.assetsFetchType = CCCAssetsFetchTypeImage;
            break;
        case 2:
            viewCtrlAssets.assetsFetchType = CCCAssetsFetchTypeVideo;
            break;
        case 3:
            viewCtrlAssets.assetsFetchType = CCCAssetsFetchTypeBoth;
            break;
        default:
            break;
    }
    
    viewCtrlAssets.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:viewCtrlAssets animated:YES completion:nil];
}

#pragma mark - CCCAssetsViewControllerDelegate

- (void)cccAssetsViewController:(CCCAssetsViewController *)viewController didPickAsset:(CCCAsset *)asset {
    [viewController dismissViewControllerAnimated:NO completion:nil];
    
    if (asset.assetType != CCCAssetTypeImage) {
        return;
    }
    
    __weak typeof(self) tempSelf = self;
    [asset loadLargeImageInOperationQueue:nil withHandler:^(UIImage *image) {
        if (image) {
            __strong typeof(tempSelf) strongSelf = tempSelf;
            
            DisplayImageViewController *imageViewController = [strongSelf.storyboard instantiateViewControllerWithIdentifier:@"DisplayImageViewController2"];
            imageViewController.image = image;
            [strongSelf.navigationController pushViewController:imageViewController animated:YES];
            
        }
        
    }];
    
}

@end
