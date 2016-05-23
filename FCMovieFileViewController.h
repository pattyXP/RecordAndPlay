//
//  FCMovieFileViewController.h
//  RecordVideo
//
//  Created by patty on 16/5/20.
//  Copyright © 2016年 patty. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCMovieFileViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIView *previewContainer; // 摄像头采集视频预览界面
@property (weak, nonatomic) IBOutlet UIView *playerContainer; // 视频播放界面
@property (weak, nonatomic) IBOutlet UILabel *timeLabel; //录制时间
@property (weak, nonatomic) IBOutlet UIButton *recordButton; //视频录制按钮
@property (weak, nonatomic) IBOutlet UIButton *cancelrecordButton; //取消视频录制按钮
@property (weak, nonatomic) IBOutlet UIButton *playerButton; // 播放按钮
@end
