//
//  CCCAssetPreviewView.h
//
//  Created by realtouchapp on 2016/1/30.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class CCCAsset;
@class CCCAssetVideoPlayerView;

@interface CCCAssetPreviewView : UIView <UIScrollViewDelegate>

@property (retain, nonatomic) UIImage *backgroundImage;

@property (retain, nonatomic) UIImage *assetLargeImage;
@property (retain, nonatomic) AVPlayerItem *playerItem;

@property (retain, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (retain, nonatomic) IBOutlet UIScrollView *contentImageScrollView;
@property (retain, nonatomic) IBOutlet CCCAssetVideoPlayerView *videoPlayerView;
@property (retain, nonatomic) IBOutlet UIButton *closeButton;

@property (retain, nonatomic) UIImageView *contentImageView;

- (IBAction)closeViewAction:(id)sender;

@end


@interface CCCAssetVideoPlayerView : UIView

@property (retain, nonatomic) AVPlayerItem *playerItem;
@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) NSTimeInterval currentDuration;

@property (readonly, retain, nonatomic) AVPlayer *player;
@property (readonly, nonatomic) BOOL isPlaying;

- (void)play;
- (void)pause;

// -- 控制欄
@property (retain, nonatomic) UIView *controlBarView;
@property (retain, nonatomic) UIButton *playPauseButton;
@property (retain, nonatomic) UISlider *timeSeekSlider;

@property (retain, nonatomic) UILabel *currentDurationLabel;
@property (retain, nonatomic) UILabel *leftDurationLabel;

@property (retain, nonatomic) NSTimer *playTimeChangedTimer;

@end
