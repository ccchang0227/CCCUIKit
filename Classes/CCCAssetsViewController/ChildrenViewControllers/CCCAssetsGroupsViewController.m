//
//  CCCAssetsGroupsViewController.m
//
//  Created by realtouchapp on 2016/1/27.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAssetsGroupsViewController.h"
#import "CCCAssetsGroup.h"


CGFloat const kAssetsGroupCellHeight = 88.0f;

@interface CCCAssetsGroupsViewController ()

- (UIImage *)blankImage;

@end

@implementation CCCAssetsGroupsViewController
@synthesize operationQueue = _operationQueue;

- (void)_setup {
}

- (instancetype)init {
    self = [super initWithNibName:@"CCCAssetsGroupsViewController" bundle:[NSBundle bundleForClass:[CCCAssetsGroupsViewController class]]];
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
    
    self.assetsGroupsTableView.delegate = self;
    self.assetsGroupsTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_operationQueue cancelAllOperations];
    [_operationQueue setSuspended:YES];
    
#if !__has_feature(objc_arc)
    [_assetsgGroupsArray release];
    [_operationQueue release];
    [_assetsGroupsTableView release];
    [super dealloc];
#endif
    
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
    self.assetsGroupsTableView.contentOffset = CGPointZero;
    [self.assetsGroupsTableView reloadData];
}

#pragma mark - Override Methods

- (void)didSelectGroup:(CCCAssetsGroup *)assetsGroup {
}

#pragma mark -

- (UIImage *)blankImage {
    static dispatch_once_t pred;
    static UIImage *blankImage = nil;
    
    dispatch_once(&pred, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(200, 200), NO, 1.0);
        [[UIColor lightGrayColor] set];
        UIRectFill(CGRectMake(0, 0, 200, 200));
        blankImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
        UIGraphicsEndImageContext();
    });
    
    return blankImage;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 5.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5.0f;
}

//為了隱藏空Cell的分隔線，沒加的話空Cell會有分隔線
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[[UIView alloc] init] autorelease];
    [view setBackgroundColor:[UIColor clearColor]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.assetsgGroupsArray.count) {
        return 0.0f;
    }
    
    return kAssetsGroupCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.assetsgGroupsArray.count && self.assetsgGroupsArray.count > 0) {
        return 0.0f;
    }
    
    return kAssetsGroupCellHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.backgroundColor = [UIColor clearColor];
    
    if (indexPath.row >= self.assetsgGroupsArray.count) {
        cell.selectedBackgroundView = nil;
        return;
    }
    
    UIView *selectView = [[UIView alloc] init];
    cell.selectedBackgroundView = selectView;
    cell.selectedBackgroundView.backgroundColor = [UIColor lightGrayColor];
    [selectView release];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.imageView.image = nil;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row >= self.assetsgGroupsArray.count) {
        return;
    }
    
    CCCAssetsGroup *assetsGroup = [self.assetsgGroupsArray objectAtIndex:indexPath.row];
    
    [self didSelectGroup:assetsGroup];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cccAssetsGroupsViewController:didSelectGroup:)]) {
        [self.delegate cccAssetsGroupsViewController:self didSelectGroup:assetsGroup];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.assetsgGroupsArray.count > 0? self.assetsgGroupsArray.count+1: 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"DefaultCellSubtitle";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.imageView.clipsToBounds = YES;
    }
    
    if (self.assetsgGroupsArray.count == 0) {
        cell.imageView.image = nil;
        cell.textLabel.text = NSLocalizedString(@"無資料", nil);
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    if (indexPath.row >= self.assetsgGroupsArray.count) {
        cell.imageView.image = nil;
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    CCCAssetsGroup *assetsGroup = [self.assetsgGroupsArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = assetsGroup.groupName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@, %ld %@", (unsigned long)assetsGroup.numberOfPhotoAssets, NSLocalizedString(@"Photos", nil), (unsigned long)assetsGroup.numberOfVideoAssets, NSLocalizedString(@"Videos", nil)];
    
    cell.imageView.image = [assetsGroup loadGroupPosterImageInOperationQueue:self.operationQueue withHandler:^(UIImage *posterImage) {
        cell.imageView.image = posterImage;
        
        if (!cell.imageView.image) {
            cell.imageView.image = self.blankImage;
        }
    }];
    
    if (!cell.imageView.image) {
        cell.imageView.image = self.blankImage;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

@end
