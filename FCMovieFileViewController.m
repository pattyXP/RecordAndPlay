//
//  FCMovieFileViewController.m
//  RecordVideo
//
//  Created by patty on 16/5/20.
//  Copyright © 2016年 patty. All rights reserved.
//

#import "FCMovieFileViewController.h"
#import "FCRecordManager.h"
#import "FCPlayerManager.h"
@interface FCMovieFileViewController ()<FCRecordManagerDelegate,FCPlayerManagerDelegate>
@property (strong, nonatomic) FCRecordManager *recordManager; // 录制视频管理器
@property (strong, nonatomic) FCPlayerManager *playerManager; // 视频播放管理器

@property (nonatomic) dispatch_source_t recordTimer; // 录制视频定时器
@property (assign, nonatomic) NSUInteger recordSeconds; // 录制视频秒数
@property (strong, nonatomic) NSURL *outputFileUrl;
@property (copy, nonatomic) NSString *outputFileName;


@end

@implementation FCMovieFileViewController

- (void)dealloc
{
    //关闭视频录制SDK
    [self.recordManager closeSDK];
    self.recordManager.delegate = nil;
    self.recordManager = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordManager = [[FCRecordManager alloc] init];
    self.recordManager.delegate = self;
    FCRecordManagerResult result = [self.recordManager openSDK];
    if (result != FCRecordManager_NoError) {
        return;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [self addPreviewLayer];
    [self addPlayerLayer];

}
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self.recordManager startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.recordManager stopRunning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark UI方法

// 视频录制
- (IBAction)recordButtonClick:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    if (button.selected) {
        NSString *outputFielPath = [self filePath];
//        NSlog(@"save path is :%@", outputFielPath);
        NSURL *fileUrl = [NSURL fileURLWithPath:outputFielPath];
//        NSlog(@"fileUrl:%@", fileUrl);
        
        if (self.playerManager) {
            // 关闭视频播放器
            [self.playerManager closeSDK];
            self.playerManager = nil;
            
            // 开始视频采集
            [self.recordManager startRunning];
            
            self.timeLabel.text = @"00:00";
        }else
        
        [self.recordManager startRecord:fileUrl];
        
    } else {
        // 停止录制
        [self.recordManager stopRecord];
    }
}

//取消录制
- (IBAction)cancelRecordButtonClick:(id)sender
{
    [self.recordManager stopRecord];
}

- (IBAction)playRecordVideo:(id)sender
{
    [self.playerManager play];
}
//// 添加相机拍摄预览图层
- (void)addPreviewLayer
{
    CALayer *layer = self.previewContainer.layer;
    layer.masksToBounds = YES;
    self.recordManager.captureVideoPreviewLayer.frame = layer.bounds;
    self.recordManager.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;// 填充模式
    // 将视频预览层添加到界面中
    [layer addSublayer:self.recordManager.captureVideoPreviewLayer];
}

// 添加录像播放图层
- (void)addPlayerLayer
{
    AVPlayerLayer *playerLayer = self.playerManager.playerLayer;
    playerLayer.frame = self.playerContainer.frame;
    [self.playerContainer.layer insertSublayer:playerLayer below:self.playerButton.layer];
}

#pragma mark 视频播放代理
- (void)playerManager:(FCPlayerManager *)playerManager currentProgress:(float)progress currentSecond:(float)second
{
    NSString *date = [[self class] msDateForSeconds:second];
    self.timeLabel.text = date;
}

#pragma mark -视频录制代理

- (void)recordManager:(FCRecordManager *)recordManager didStartRecordingToOutputFileAtURL:(NSURL *)outputFileURL
{
    [self startRecordTimer];
}
- (void)recordManager:(FCRecordManager *)recordManager didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error
{
    // 停止录像计时
    [self stopRecordTimer];
    
    // 停止录制视频
    [self.recordManager stopRunning];
    
    // 重新设置录像按钮
    if (self.recordButton.selected) {
        self.recordButton.selected = NO;
    }
    self.playerManager = [[FCPlayerManager alloc] init];
    [self.playerManager openSDKForFileUrl:outputFileURL];
    self.playerManager.delegate = self;
    [self addPlayerLayer];


    // 设置title
    self.timeLabel.text = @"00:00";
    
    self.outputFileUrl = outputFileURL;
    
    if (error) {
        NSLog(@"error:%@", error.localizedDescription);
    }

}
#pragma mark -定时器
// 开启定时器
- (void)startRecordTimer
{
    [self stopRecordTimer];
    
    WEAKSELF
    
    _recordTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_recordTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_recordTimer, ^{
        NSString *date = [[weakSelf class] msDateForSeconds:weakSelf.recordSeconds];
        weakSelf.timeLabel.text = date;
        weakSelf.recordSeconds++;

        if (weakSelf.recordSeconds == 120) {
            //最长支持录制2分钟
            [weakSelf.recordManager stopRecord];
        }
    });
    dispatch_source_set_cancel_handler(_recordTimer, ^{
        weakSelf.recordSeconds = 0;
        weakSelf.recordTimer = nil;
    });
    dispatch_resume(_recordTimer);//启动
}


// 停止定时器
- (void)stopRecordTimer
{
    if (_recordTimer) {
        dispatch_source_cancel(_recordTimer);
    }
}

#pragma mark -文件
- (NSString *)filePath
{
    NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingString:[self fileName]];
    return outputFilePath;
}

- (NSString *)fileName
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd_hhmmss";
    NSString *stringDate = [dateFormatter stringFromDate:[NSDate date]];
    self.outputFileName = [NSString stringWithFormat:@"%@_t%@_video.mp4", stringDate, @"YXP"];
    return self.outputFileName;
}

+ (NSString *)msDateForSeconds:(NSUInteger)seconds
{
    NSUInteger minute = seconds / 60;
    NSUInteger second = seconds % 60;
    
    NSString *time = nil;
    time = [NSString stringWithFormat:@"%02ld:%02ld", (unsigned long)minute, (unsigned long)second];
    
    return time;
}
@end
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */