//
//  FCCapture.h


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, FCRecordManagerResult)
{
    FCRecordManager_NoError = 0,
    FCRecordManager_OpenSDKError,
};

@protocol FCRecordManagerDelegate;

@interface FCRecordManager : NSObject
/**
 *  委托
 */
@property (assign, nonatomic) id<FCRecordManagerDelegate> delegate;

/**
 *  打开sdk
 *
 *  @return 错误码，类型为FCRecordManagerResult
 */
- (NSUInteger)openSDK;

/**
 *  关闭sdk，如果正在录制视频，则会调用stopRecord
 */
- (void)closeSDK;

/**
 *  获取相机拍摄预览图层，需要先调用openSDK并且成功，否则返回nil
 *
 *  @return 相机拍摄预览图层
 */
- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer;

/**
 *  开始运行
 */
- (void)startRunning;

/**
 *  停止运行
 */
- (void)stopRunning;

/**
 *  开始录制视频，需要先调用openSDK并且成功，否则返回NO
 *
 *  @param fileURL 视频文件保存录制
 *
 *  @return YES - 开始录制成功  NO - 开始录制失败
 */
- (BOOL)startRecord:(NSURL *)fileURL;

/**
 *  停止录制视频
 */
- (void)stopRecord;

/**
 *  切换摄像头
 */
- (void)toggleCamera;

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point;

@end

@protocol FCRecordManagerDelegate <NSObject>

/**
 *  开始录制视频
 *
 *  @param recordManager 录制视频管理器
 *  @param outputFileURL 视频保存路径
 */
- (void)recordManager:(FCRecordManager *)recordManager didStartRecordingToOutputFileAtURL:(NSURL *)outputFileURL;

/**
 *  结束录制视频
 *
 *  @param recordManager 录制视频管理器
 *  @param outputFileURL 视频保存路径
 *  @param error         错误码
 */
- (void)recordManager:(FCRecordManager *)recordManager didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error;

@end
