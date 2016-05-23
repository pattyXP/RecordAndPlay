//
//  FCPlayerManager.m


#import "FCPlayerManager.h"
#import <AVFoundation/AVFoundation.h>

@interface FCPlayerManager ()
@property (strong, nonatomic) AVPlayer *player; // 播放器对象
@property (strong, nonatomic) AVPlayerLayer *playerLayer; // 视频播放图层
@property (assign, nonatomic) BOOL isOpenSuccessed; // 是否打开成功
@property (nonatomic) CMTime beginTime;

@end

@implementation FCPlayerManager
@synthesize playerLayer = _playerLayer;

- (void)dealloc
{
    self.delegate = nil;
    [self closeSDK];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isOpenSuccessed = NO;
    }
    return self;
}

- (NSUInteger)openSDKForFileUrl:(NSURL *)fileUrl
{
    if (self.isOpenSuccessed) {
        return FCPlayerManager_NoError;
    }
    
    if (!fileUrl) {
        return FCPlayerManager_FileUrlIsNil;
    }
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:fileUrl];
    if (!playerItem) {
        return FCPlayerManager_FileUrlIsInvalid;
    }
    
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    self.beginTime = self.player.currentTime;
    
    [self addProgressObserver];
    [self addNotification];
    
    _isOpenSuccessed = YES;
    
    return FCPlayerManager_NoError;
}

- (void)closeSDK
{
    if (!self.isOpenSuccessed) {
        return;
    }
    
    [self pause];
    [self removeNotification];
    
    _isOpenSuccessed = NO;
}

- (AVPlayerLayer *)playerLayer
{
    if (!self.isOpenSuccessed) {
        return nil;
    }
    
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // 视频填充模式
    }
    
    return _playerLayer;
}

- (void)play
{
    if (!self.isOpenSuccessed) {
        return;
    }
    
    [self.player play];
}

- (void)replay
{
    [self.player seekToTime:self.beginTime];
    [self.player play];
}

- (void)pause
{
    if (!self.isOpenSuccessed) {
        return;
    }
    
    [self.player pause];
}

- (void)resume
{
    if (!self.isOpenSuccessed) {
        return;
    }
    
    [self.player play];
}

#pragma mark - 监控
#pragma mark 给播放器添加进度更新
- (void)addProgressObserver
{
    AVPlayerItem *playerItem = self.player.currentItem;
    
    WEAKSELF
    
    // 这里设置每秒执行一次
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        NSLog(@"当前已经播放%.2fs.", current);
        if (current) {
            if ([weakSelf.delegate respondsToSelector:@selector(playerManager:currentProgress: currentSecond:)]) {
                [weakSelf.delegate playerManager:weakSelf currentProgress:(current/total) currentSecond:current];
            }
        }
    }];
}

#pragma mark
#pragma mark - 播放器通知
- (void)addNotification
{
    // 给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playbackFinished:(NSNotification *)notification
{
    NSLog(@"视频播放完成.");
    if ([self.delegate respondsToSelector:@selector(didPlayToEndTime)]) {
        [self.delegate didPlayToEndTime];
    }
}

@end
