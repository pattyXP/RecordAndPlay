//
//  ViewController.m
//  RecordVideo
//
//  Created by patty on 16/5/20.
//  Copyright © 2016年 patty. All rights reserved.
// 视频录制

#import "ViewController.h"
#import "FCMovieFileViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)click
{
    FCMovieFileViewController *movieFileOutputViewController = [[FCMovieFileViewController alloc] init];
  
    [self.navigationController pushViewController:movieFileOutputViewController animated:YES];

}

@end
