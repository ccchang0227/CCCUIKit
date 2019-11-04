//
//  CCCAssetPreviewView.m
//
//  Created by realtouchapp on 2016/1/30.
//  Copyright © 2016年 CHIEN-HSU WU. All rights reserved.
//

#import "CCCAssetPreviewView.h"
#import "CCCAsset.h"


@interface CCCAssetPreviewView () <UIGestureRecognizerDelegate> {
    CGRect _bounds;
}

@property (retain, nonatomic) UITapGestureRecognizer *doubleTapGesture;
@property (retain, nonatomic) UITapGestureRecognizer *singleTapGesture;

@end
@implementation CCCAssetPreviewView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _bounds = CGRectZero;
    
    self.contentImageScrollView.delegate = self;
    
    _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapScrollView:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    _doubleTapGesture.delegate = self;
    [self.contentImageScrollView addGestureRecognizer:_doubleTapGesture];
    
    self.closeButton.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.800];
    self.closeButton.layer.cornerRadius = 27.0;
    self.closeButton.layer.borderWidth = 1.0f;
    self.closeButton.layer.borderColor = [UIColor redColor].CGColor;
    
    _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideoView:)];
    _singleTapGesture.numberOfTapsRequired = 1;
    _singleTapGesture.delegate = self;
    [self.videoPlayerView addGestureRecognizer:_singleTapGesture];
}

- (void)dealloc {
    
#if !__has_feature(objc_arc)
    [_backgroundImage release];
    [_assetLargeImage release];
    [_playerItem release];
    [_backgroundImageView release];
    [_contentImageScrollView release];
    [_videoPlayerView release];
    [_closeButton release];
    [_contentImageView release];
    [_doubleTapGesture release];
    [_singleTapGesture release];
    [super dealloc];
#endif
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, _bounds)) {
        [self _setupZoomScale];
        
        _bounds = self.bounds;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview) {
        if (self.backgroundImage) {
            self.backgroundImageView.image = self.backgroundImage;
        }
        else {
            self.backgroundImageView.image = nil;
        }
        self.alpha = 0.0;
        [self.contentImageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.contentImageView = nil;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    if (!self.superview) {
        self.backgroundImage = nil;
        self.backgroundImageView.image = nil;
        self.assetLargeImage = nil;
        self.playerItem = nil;
        
        [self.contentImageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.contentImageView = nil;
        
        self.contentImageScrollView.maximumZoomScale = 1.0;
        self.contentImageScrollView.minimumZoomScale = 1.0;
        self.contentImageScrollView.zoomScale = 1.0;
        
        [self.videoPlayerView pause];
        self.videoPlayerView.playerItem = nil;
        
        self.videoPlayerView.controlBarView.alpha = 1.0;
        self.closeButton.alpha = 1.0;
    }
    else {
        if (self.assetLargeImage) {
            self.contentImageScrollView.hidden = NO;
            self.videoPlayerView.hidden = YES;
            [self _loadContentImage];
        }
        else if (self.playerItem) {
            self.contentImageScrollView.hidden = YES;
            self.videoPlayerView.hidden = NO;
            [self _loadPlayer];
        }
        
        [UIView animateWithDuration:0.3 animations:^ {
            self.alpha = 1.0;
        }completion:^(BOOL finished) {
            if (finished) {
                if (self.playerItem) {
                    [self.videoPlayerView play];
                    
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self performSelector:@selector(_hideVideoControlBar) withObject:nil afterDelay:5.0];
                    });
                }
            }
        }];
    }
}

#pragma mark -

- (void)_loadContentImage {
    [self.contentImageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.contentImageView = nil;
    
    self.contentImageScrollView.maximumZoomScale = 1.0;
    self.contentImageScrollView.minimumZoomScale = 1.0;
    self.contentImageScrollView.zoomScale = 1.0;
    
    if (self.assetLargeImage) {
        _contentImageView = [[UIImageView alloc] init];
        _contentImageView.backgroundColor = [UIColor clearColor];
        _contentImageView.contentMode = UIViewContentModeScaleAspectFit;
        _contentImageView.image = self.assetLargeImage;
        _contentImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentImageScrollView addSubview:_contentImageView];
        
        [self.contentImageScrollView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentImageView(w)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"w":@(_assetLargeImage.size.width)} views:NSDictionaryOfVariableBindings(_contentImageView)]];
        [self.contentImageScrollView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentImageView(h)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:@{@"h":@(_assetLargeImage.size.height)} views:NSDictionaryOfVariableBindings(_contentImageView)]];
        
        [self _setupZoomScale];
    }
}

- (void)_setupZoomScale {
    UIImage *image = self.contentImageView.image;
    if (!image) {
        self.contentImageScrollView.minimumZoomScale = 1.0;
        self.contentImageScrollView.maximumZoomScale = 1.0;
        self.contentImageScrollView.zoomScale = 1.0;
        return;
    }
    
    CGFloat scaleWidth = CGRectGetWidth(self.bounds)/image.size.width;
    CGFloat scaleHeight = CGRectGetHeight(self.bounds)/image.size.height;
    
    self.contentImageScrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
    self.contentImageScrollView.maximumZoomScale = MAX(scaleWidth, scaleHeight);
    self.contentImageScrollView.maximumZoomScale = MAX(self.contentImageScrollView.maximumZoomScale, 1.0);
    
    self.contentImageScrollView.zoomScale = 0.01f;
    
    if (self.contentImageScrollView.minimumZoomScale == self.contentImageScrollView.maximumZoomScale) {
        if (self.contentImageScrollView.maximumZoomScale > 1.0) {
            self.contentImageScrollView.minimumZoomScale = 1.0f;
        }
        else {
            self.contentImageScrollView.minimumZoomScale = 0.5f;
        }
    }
    
    //初始化縮放比例
    [self.contentImageScrollView setZoomScale:self.contentImageScrollView.minimumZoomScale animated:NO];
}

- (void)_loadPlayer {
    [self.contentImageScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.contentImageView = nil;
    
    self.contentImageScrollView.maximumZoomScale = 1.0;
    self.contentImageScrollView.minimumZoomScale = 1.0;
    self.contentImageScrollView.zoomScale = 1.0;
    
    self.videoPlayerView.playerItem = self.playerItem;
}

- (void)_hideVideoControlBar {
    if (self.videoPlayerView.controlBarView.alpha == 1.0) {
        [UIView animateWithDuration:0.5 animations:^ {
            self.videoPlayerView.controlBarView.alpha = 0.0;
            self.closeButton.alpha = 0.0;
        }];
    }
}

#pragma mark - Button Actions

- (IBAction)closeViewAction:(id)sender {
    [UIView animateWithDuration:0.3 animations:^ {
        self.alpha = 0.0;
    }completion:^(BOOL finished) {
        if (finished) {
            self.alpha = 1.0;
            [self removeFromSuperview];
        }
    }];
    
}

#pragma mark - GestureRecognizer

- (void)doubleTapScrollView:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.contentImageScrollView.zoomScale == self.contentImageScrollView.maximumZoomScale) {
            [self.contentImageScrollView setZoomScale:self.contentImageScrollView.minimumZoomScale animated:YES];
        }
        else if (self.contentImageScrollView.zoomScale == self.contentImageScrollView.minimumZoomScale) {
            CGFloat mediumZoomScale = (self.contentImageScrollView.minimumZoomScale+self.contentImageScrollView.maximumZoomScale)/3.0;
            [self.contentImageScrollView setZoomScale:mediumZoomScale animated:YES];
        }
        else {
            [self.contentImageScrollView setZoomScale:self.contentImageScrollView.maximumZoomScale animated:YES];
        }
    }
}

- (void)tapVideoView:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.videoPlayerView.controlBarView.alpha == 0.0) {
            [UIView animateWithDuration:0.5 animations:^ {
                self.videoPlayerView.controlBarView.alpha = 1.0;
                self.closeButton.alpha = 1.0;
            }completion:^(BOOL finished) {
                if (finished) {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self performSelector:@selector(_hideVideoControlBar) withObject:nil afterDelay:5.0];
                    });
                }
            }];
        }
        else {
            [UIView animateWithDuration:0.5 animations:^ {
                self.videoPlayerView.controlBarView.alpha = 0.0;
                self.closeButton.alpha = 0.0;
            }];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.contentImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (CGRectEqualToRect(scrollView.bounds, CGRectZero)) {
        return;
    }
    
    UIImageView *imageView = self.contentImageView;
    UIImage *image = imageView.image;
    if (!image) return;
    
    CGSize imageSize = CGSizeMake(image.size.width*scrollView.zoomScale, image.size.height*scrollView.zoomScale);
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    if (imageSize.width < CGRectGetWidth(self.bounds)) {
        contentInset.left = (CGRectGetWidth(self.bounds)-imageSize.width)/2.0;
        contentInset.right = contentInset.left;
    }
    
    if (imageSize.height < CGRectGetHeight(self.bounds)) {
        contentInset.top = (CGRectGetHeight(self.bounds)-imageSize.height)/2.0;
        contentInset.bottom = contentInset.top;
    }
    
    scrollView.contentInset = contentInset;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _doubleTapGesture) {
        if (_assetLargeImage) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else if (gestureRecognizer == _singleTapGesture) {
        if (_playerItem) {
            return YES;
        }
        else {
            return NO;
        }
    }
    
    return YES;
}

@end


@implementation CCCAssetVideoPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)_setup {
    ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspect;
    
    // 加上控制欄
    _controlBarView = [[UIView alloc] init];
    _controlBarView.backgroundColor = [UIColor colorWithWhite:0.498 alpha:0.700];
    _controlBarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_controlBarView];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_controlBarView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_controlBarView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_controlBarView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_controlBarView)]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_controlBarView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0.15 constant:0.0]];
    
    _timeSeekSlider = [[UISlider alloc] init];
    _timeSeekSlider.backgroundColor = [UIColor clearColor];
    _timeSeekSlider.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _timeSeekSlider.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _timeSeekSlider.minimumValue = 0.0;
    _timeSeekSlider.maximumValue = 1.0;
    _timeSeekSlider.minimumTrackTintColor = [UIColor whiteColor];
    _timeSeekSlider.maximumTrackTintColor = [UIColor blackColor];
    [_timeSeekSlider addTarget:self action:@selector(timeSeekTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_timeSeekSlider addTarget:self action:@selector(timeSeekValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_timeSeekSlider addTarget:self action:@selector(timeSeekTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_timeSeekSlider addTarget:self action:@selector(timeSeekTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [_timeSeekSlider addTarget:self action:@selector(timeSeekTouchUp:) forControlEvents:UIControlEventTouchCancel];
    _timeSeekSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [_controlBarView addSubview:_timeSeekSlider];
    
    [_controlBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(15)-[_timeSeekSlider]-(15)-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_timeSeekSlider)]];
    [_controlBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_timeSeekSlider]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_timeSeekSlider)]];
    [_controlBarView addConstraint:[NSLayoutConstraint constraintWithItem:_timeSeekSlider attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_controlBarView attribute:NSLayoutAttributeHeight multiplier:0.4 constant:0.0]];
    
    _playPauseButton = [[UIButton alloc] init];
    _playPauseButton.backgroundColor = [UIColor clearColor];
    _playPauseButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_playPauseButton setImage:[UIImage imageNamed:@"CCCAssets_Play" inBundle:[NSBundle bundleForClass:[CCCAssetPreviewView class]] compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    [_playPauseButton setImage:[UIImage imageNamed:@"CCCAssets_Pause" inBundle:[NSBundle bundleForClass:[CCCAssetPreviewView class]] compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
    [_playPauseButton addTarget:self action:@selector(playPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_controlBarView addSubview:_playPauseButton];
    
    [_controlBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_playPauseButton][_timeSeekSlider]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_playPauseButton, _timeSeekSlider)]];
    [_controlBarView addConstraint:[NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_controlBarView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [_controlBarView addConstraint:[NSLayoutConstraint constraintWithItem:_playPauseButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_playPauseButton attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    
    _currentDurationLabel = [[UILabel alloc] init];
    _currentDurationLabel.backgroundColor = [UIColor clearColor];
    _currentDurationLabel.textColor = [UIColor whiteColor];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        _currentDurationLabel.font = [UIFont boldSystemFontOfSize:16.0];
    }
    else {
        _currentDurationLabel.font = [UIFont boldSystemFontOfSize:13.0];
    }
    _currentDurationLabel.textAlignment = NSTextAlignmentLeft;
    _currentDurationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_controlBarView addSubview:_currentDurationLabel];
    
    [_controlBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(5)-[_currentDurationLabel][_playPauseButton]" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_currentDurationLabel, _playPauseButton)]];
    
    _leftDurationLabel = [[UILabel alloc] init];
    _leftDurationLabel.backgroundColor = [UIColor clearColor];
    _leftDurationLabel.textColor = [UIColor whiteColor];
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        _leftDurationLabel.font = [UIFont boldSystemFontOfSize:16.0];
    }
    else {
        _leftDurationLabel.font = [UIFont boldSystemFontOfSize:13.0];
    }
    _leftDurationLabel.textAlignment = NSTextAlignmentRight;
    _leftDurationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_controlBarView addSubview:_leftDurationLabel];
    
    [_controlBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_playPauseButton][_leftDurationLabel]-(5)-|" options:NSLayoutFormatDirectionLeadingToTrailing|NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom metrics:nil views:NSDictionaryOfVariableBindings(_leftDurationLabel, _playPauseButton)]];
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self _setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self _setup];
}

- (void)dealloc {
    [_player pause];
    [_playTimeChangedTimer invalidate];
    
#if !__has_feature(objc_arc)
    [_playerItem release];
    [_player release];
    [_controlBarView release];
    [_playPauseButton release];
    [_timeSeekSlider release];
    [_currentDurationLabel release];
    [_leftDurationLabel release];
    [_playTimeChangedTimer release];
    [super dealloc];
#endif
    
}

#pragma mark - Setter

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
#if !__has_feature(objc_arc)
    if (_playerItem) {
        [_playerItem release];
    }
#endif
    _playerItem = [playerItem retain];
    
    if (playerItem) {
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
        _duration = playerItem.duration.value/playerItem.duration.timescale;
    }
    else {
        self.player = nil;
        _duration = 0;
    }
}

- (void)setPlayer:(AVPlayer *)player {
#if !__has_feature(objc_arc)
    if (_player) {
        [self pause];
        
        [_player release];
    }
#endif
    _player = [player retain];
    ((AVPlayerLayer*)self.layer).player = _player;
    
    _currentDuration = 0;
    [self _setupPlayingValues];
    if (player) {
        [_player seekToTime:kCMTimeZero];
    }
    
}

#pragma mark - Getter

- (BOOL)isPlaying {
    if (_player) {
        return (_player.rate != 0.0);
    }
    
    return NO;
}

#pragma mark -

- (void)_setupPlayingValues {
    if (_duration > 0.0) {
        _timeSeekSlider.value = _currentDuration/_duration;
    }
    else {
        _timeSeekSlider.value = 0.0;
    }
    
    NSTimeInterval leftDuration = _duration-_currentDuration;
    
    if (_duration >= 3600.0) {
        NSString *timeFormatString = @"%ld:%02ld:%02ld";
        
        NSInteger hr = _currentDuration/3600;
        NSInteger min = (_currentDuration-hr*3600)/60;
        NSInteger sec = ((NSInteger)_currentDuration)%60;
        _currentDurationLabel.text = [NSString stringWithFormat:timeFormatString, (long)hr, (long)min, (long)sec];
        
        hr = leftDuration/3600;
        min = (leftDuration-hr*3600)/60;
        sec = ((NSInteger)leftDuration)%60;
        _leftDurationLabel.text = [NSString stringWithFormat:[NSString stringWithFormat:@"-%@", timeFormatString], (long)hr, (long)min, (long)sec];
    }
    else {
        NSString *timeFormatString = @"%02ld:%02ld";
        
        NSInteger min = _currentDuration/60;
        NSInteger sec = ((NSInteger)_currentDuration)%60;
        _currentDurationLabel.text = [NSString stringWithFormat:timeFormatString, (long)min, (long)sec];
        
        min = leftDuration/60;
        sec = ((NSInteger)leftDuration)%60;
        _leftDurationLabel.text = [NSString stringWithFormat:[NSString stringWithFormat:@"-%@", timeFormatString], (long)min, (long)sec];
    }
}

- (void)play {
    if (_player) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:nil];
        
        self.playTimeChangedTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(durationChanged:) userInfo:nil repeats:YES];
        
        [_player play];
        _playPauseButton.selected = YES;
        [_playPauseButton setImage:[_playPauseButton imageForState:UIControlStateSelected] forState:UIControlStateHighlighted];
    }
}

- (void)pause {
    if (_player) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
        
        [_player pause];
        _playPauseButton.selected = NO;
        [_playPauseButton setImage:[_playPauseButton imageForState:UIControlStateNormal] forState:UIControlStateHighlighted];
        
        [_playTimeChangedTimer invalidate];
        self.playTimeChangedTimer = nil;
    }
}

#pragma mark - Control Events

- (void)timeSeekTouchDown:(UISlider *)sender {
    if ([self.superview respondsToSelector:NSSelectorFromString(@"_hideVideoControlBar")]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.superview selector:NSSelectorFromString(@"_hideVideoControlBar") object:nil];
    }
}

- (void)timeSeekValueChanged:(UISlider *)sender {
    _currentDuration = sender.value*_duration;
    
    [self _setupPlayingValues];
    if (_duration > 0.0) {
        [_player seekToTime:CMTimeMake(_currentDuration*_playerItem.duration.timescale, _playerItem.duration.timescale)];
    }
    
}

- (void)timeSeekTouchUp:(UISlider *)sender {
    if ([self.superview respondsToSelector:NSSelectorFromString(@"_hideVideoControlBar")]) {
        [self.superview performSelector:NSSelectorFromString(@"_hideVideoControlBar") withObject:nil afterDelay:5.0];
    }
}

- (void)playPauseAction:(UIButton *)sender {
    if ([self.superview respondsToSelector:NSSelectorFromString(@"_hideVideoControlBar")]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.superview selector:NSSelectorFromString(@"_hideVideoControlBar") object:nil];
    }
    
    if (self.isPlaying) {
        [self pause];
    }
    else {
        if (_currentDuration == _duration) {
            _currentDuration = 0;
            [_player seekToTime:kCMTimeZero];
            [self _setupPlayingValues];
        }
        [self play];
    }
    
    if ([self.superview respondsToSelector:NSSelectorFromString(@"_hideVideoControlBar")]) {
        [self.superview performSelector:NSSelectorFromString(@"_hideVideoControlBar") withObject:nil afterDelay:5.0];
    }
}

#pragma mark - Timer

- (void)durationChanged:(NSTimer *)theTimer {
    if (self.isPlaying) {
        if (_duration == 0.0) {
            _duration = _playerItem.duration.value/_playerItem.duration.timescale;
        }
        if (_duration > 0.0) {
            _currentDuration = _player.currentTime.value/_player.currentTime.timescale;
            
            [self _setupPlayingValues];
        }
        else {
            [self pause];
        }
    }
    else {
        [self pause];
    }
}

#pragma mark - Notifications

- (void)playerItemPlayToEnd:(NSNotification *)notification {
    _currentDuration = 1.0*_duration;
    [self _setupPlayingValues];
    
    [self pause];
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [self pause];
}

- (void)playerItemPlaybackStalled:(NSNotification *)notification {
    [self pause];
}

@end
