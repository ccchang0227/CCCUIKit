//
//  CCCAssetsGroupsViewController.h
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCCAssetsModel.h"


@protocol CCCAssetsGroupsViewControllerDelegate;
@interface CCCAssetsGroupsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (assign, nonatomic) id<CCCAssetsGroupsViewControllerDelegate> delegate;

@property (assign, nonatomic) CCCAssetsFetchType assetsFetchType;

@property (retain, nonatomic) NSArray<CCCAssetsGroup *> *assetsgGroupsArray;

@property (readonly, retain, nonatomic) NSOperationQueue *operationQueue;

@property (retain, nonatomic) IBOutlet UITableView *assetsGroupsTableView;

- (void)reloadData;

// Override method
- (void)didSelectGroup:(CCCAssetsGroup *)assetsGroup;

@end

@protocol CCCAssetsGroupsViewControllerDelegate <NSObject>
@optional

- (void)cccAssetsGroupsViewController:(CCCAssetsGroupsViewController *)viewController didSelectGroup:(CCCAssetsGroup *)assetsGroup;

@end
