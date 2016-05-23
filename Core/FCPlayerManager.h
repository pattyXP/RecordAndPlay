//
//  FCPlayerManager.h


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, FCPlayerManagerResult)
{
    FCPlayerManager_NoError = 0,
    FCPlayerManager_FileUrlIsNil,
    FCPlayerManager_FileUrlIsInvalid,
};

@protocol FCPlayerManagerDelegate;

@interface FCPlayerManager : NSObject
/**
 *  委托
 */
@property (assign, nonatomic) id<FCPlayerManagerDelegate> delegate;

/**
 *  打开sdk
 *
 *  @param fileUrl 视频文件地址
 *
 *  @return 错误码，详见FCPlayerManagerResult
 */
- (NSUInteger)openSDKForFileUrl:(NSURL *)fileUrl;

/**
 *  关闭sdk
 */
- (void)closeSDK;

/**
 *  获取视频播放图层
 *
 *  @return 视频播放图层
 */
- (AVPlayerLayer *)playerLayer;

/**
 *  播放
 */
- (void)play;

/**
 *  播放完成后重新播放
 */
- (void)replay;

/**
 *  暂停
 */
- (void)pause;

/**
 *  继续
 */
- (void)resume;

@end

@protocol FCPlayerManagerDelegate <NSObject>

/**
 *  返回当前播放进度
 *
 *  @param playerManager 播放管理器
 *  @param progress      当前进度，为百分比
 @  @param second        当前播放到第几秒
 */
- (void)playerManager:(FCPlayerManager *)playerManager currentProgress:(float)progress currentSecond:(float)second;

/**
 *  播放结束
 */
- (void)didPlayToEndTime;

@end
