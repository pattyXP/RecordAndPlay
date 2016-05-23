//
//  FCCapture.m


#import "FCRecordManager.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface FCRecordManager ()<AVCaptureFileOutputRecordingDelegate> // 视频文件输出代理
@property (strong, nonatomic) AVCaptureSession *captureSession; // 负责输入和输出设置之间的数据传递
@property (strong, nonatomic) AVCaptureDeviceInput *videoCaptureDeviceInput; // 负责从AVCaptureDevice获得输入视频数据
@property (strong, nonatomic) AVCaptureMovieFileOutput *captureMovieFileOutput; // 视频输出流
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (assign, nonatomic) BOOL isOpenSuccessed; // 是否打开成功
@property (assign, nonatomic) BOOL isRunning;
@end

@implementation FCRecordManager
@synthesize captureVideoPreviewLayer = _captureVideoPreviewLayer;

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

- (NSUInteger)openSDK
{
    if (self.isOpenSuccessed) {
        return FCRecordManager_NoError;
    }
    
    // 初始化会话
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.automaticallyConfiguresApplicationAudioSession = YES;
    _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // 获取视频采集设备
    AVCaptureDevice *videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];// 取得前置摄像头
    
    // 获取音频采集设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    // 根据输入设备初始化设备输入对象，用于获得输入数据
    NSError *error = nil;
    _videoCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    if (error) {
        NSLog(@"获取视频设备输入对象时出错，错误原因：%@", error.localizedDescription);
        return FCRecordManager_OpenSDKError;
    }
    AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"获取音频设备输入对象时出错，错误原因：%@", error.localizedDescription);
        return FCRecordManager_OpenSDKError;
    }
    
    // 初始化设备输出对象，用于获得输出数据
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    _captureMovieFileOutput.movieFragmentInterval = kCMTimeInvalid;
    
    // 将设备输入添加到会话中
    if ([_captureSession canAddInput:_videoCaptureDeviceInput]) {
        [_captureSession addInput:_videoCaptureDeviceInput];
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            if ([captureConnection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)]) {
                [captureConnection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
            }
        }
    } else {
        NSLog(@"添加视频输入设备失败");
    }
    
    if ([_captureSession canAddInput:audioCaptureDeviceInput]) {
        [_captureSession addInput:audioCaptureDeviceInput];
    } else {
        NSLog(@"添加音频输入设备失败");
    }
    
    // 将设备输出添加到会话中
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
    } else {
        NSLog(@"添加视频文件输出设备失败");
    }
    
    // 添加视频采集通知
    [self addNotificationToCaptureDevice:videoCaptureDevice];
    // 添加视频采集会话
    [self addNotificationToCaptureSession:_captureSession];
    
    _isOpenSuccessed = YES;
    
    return FCRecordManager_NoError;
}

- (void)closeSDK
{
    if (!self.isOpenSuccessed) {
        return;
    }
    [self stopRecord];
    [self removeNotification];
    
    _isOpenSuccessed = NO;
}

- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer
{
    if (!self.isOpenSuccessed) {
        return nil;
    }
    // 创建视频预览层，用于实时展示摄像头状态
    if (!_captureVideoPreviewLayer) {
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // 填充模式
    }
    return _captureVideoPreviewLayer;
}

- (void)startRunning;
{
    if (!self.isOpenSuccessed) {
        return;
    }
    self.isRunning = YES;
    [self.captureSession startRunning];
}

- (void)stopRunning
{
    if (!self.isOpenSuccessed) {
        return;
    }
    self.isRunning = NO;
    [self.captureSession stopRunning];
}

- (BOOL)startRecord:(NSURL *)fileURL
{
    if (!fileURL) {
        return NO;
    }
    
    if (!self.isOpenSuccessed) {
        return NO;
    }
    
    // 根据设备输出获得连接
    AVCaptureConnection *captureConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    // 预览图层和视频方向保持一致
    captureConnection.videoOrientation = [self.captureVideoPreviewLayer connection].videoOrientation;
    // 开始录制
    [self.captureMovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
    
    return YES;
}

- (void)stopRecord
{
    if (!self.isOpenSuccessed) {
        return;
    }
    
    if ([self.captureMovieFileOutput isRecording]) {
        // 停止录制
        [self.captureMovieFileOutput stopRecording];
    }
}

- (void)toggleCamera
{
    AVCaptureDevice *currentDevice = [self.videoCaptureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    [self removeNotificationFromCaptureDevice:currentDevice];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    [self addNotificationToCaptureDevice:toChangeDevice];
    
    // 获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    // 改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    // 移除原有输入对象
    [self.captureSession removeInput:self.videoCaptureDeviceInput];
    // 添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.videoCaptureDeviceInput = toChangeDeviceInput;
    }
    // 提交会话配置
    [self.captureSession commitConfiguration];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

#pragma mark -
#pragma mark 视频输出代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"开始录制");
    if ([self.delegate respondsToSelector:@selector(recordManager:didStartRecordingToOutputFileAtURL:)]) {
        [self.delegate recordManager:self didStartRecordingToOutputFileAtURL:fileURL];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"视频录制完成");
    
    if ([self.delegate respondsToSelector:@selector(recordManager:didFinishRecordingToOutputFileAtURL:error:)]) {
        [self.delegate recordManager:self didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

#pragma mark -
#pragma mark 输入设备通知
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice
{
    // 注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    // 设备连接成功
    [notificationCenter addObserver:self selector:@selector(deviceConnected:) name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    // 设备连接断开
    [notificationCenter addObserver:self selector:@selector(deviceDisconnected:) name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}

- (void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}

- (void)areaChange:(NSNotification *)notification
{
//    NSLog(@"捕获区域改变...");
}

- (void)deviceConnected:(NSNotification *)notification
{
    NSLog(@"设备已连接...");
}

- (void)deviceDisconnected:(NSNotification *)notification
{
    NSLog(@"设备已断开.");
}

#pragma mark -
#pragma mark 采集会话通知
- (void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // 会话出错
    [notificationCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
    // 会话开始运行
    [notificationCenter addObserver:self selector:@selector(sessionDidStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:captureSession];
    // 会话停止运行
    [notificationCenter addObserver:self selector:@selector(sessionDidStopRunning:) name:AVCaptureSessionDidStopRunningNotification object:captureSession];
    // 会话被中断
    [notificationCenter addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:captureSession];
    // 会话中断结束
    [notificationCenter addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:captureSession];
}

- (void)removeNotification
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSLog(@"会话发生错误.");
}

- (void)sessionDidStartRunning:(NSNotification *)notification
{
    NSLog(@"会话开始运行.");
//    if (!self.isRunning) {
//        [self stopRunning];
//    }
}

- (void)sessionDidStopRunning:(NSNotification *)notification
{
    NSLog(@"会话停止运行.");
//    if (self.isRunning) {
//        [self startRunning];
//    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    NSLog(@"会话被中断.");
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog(@"会话中断结束.");
}

#pragma mark - 设备辅助方法
#pragma mark 取得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark 改变设备属性的统一操作方法
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    AVCaptureDevice *captureDevice = [self.videoCaptureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    } else {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@", error.localizedDescription);
    }
}

#pragma mark 设置闪光灯模式
- (void)setFlashMode:(AVCaptureFlashMode)flashMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}

#pragma mark 设置聚焦模式
- (void)setFocusMode:(AVCaptureFocusMode)focusMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
    }];
}

#pragma mark 设置曝光模式
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
    }];
}

@end
