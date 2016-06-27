//
//  ViewController.m
//  H264PlayDemo
//
//  Created by 王爽 on 16/6/27.
//  Copyright © 2016年 王爽. All rights reserved.
//

#import "ViewController.h"
#import "VideoFileParser.h"
#import "FFMPEGH264Decoder.h"
#import "OpenGLView20.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat ratio = 9.0 / 16.0;
    OpenGLView20 *glView = [[OpenGLView20 alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenWidth *ratio)];
    glView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:glView];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"demo.h264" ofType:nil];
    NSLog(@"%@",filePath);
    VideoFileParser *parser = [VideoFileParser alloc];
    [parser open:filePath];
    
    
    
    CFFMPEGH264Decoder *decoder = new CFFMPEGH264Decoder(0);
    decoder->Init();
    decoder->Start();
    dispatch_queue_t decodeQueue = dispatch_queue_create("abc", NULL);
    dispatch_async(decodeQueue, ^{
        VideoPacket *vp = nil;
        while(true) {
            vp = [parser nextPacket];
            if(vp == nil) {
                break;
            }
            decoder->Decode(vp.buffer, vp.size);
            unsigned char *result = decoder->GetResultData();
            if (result != 0) {
              //  NSLog(@"%d, %d",decoder->GetResultWidth(), decoder->GetResultHeight());
                dispatch_async(dispatch_get_main_queue(), ^{
                     [glView displayYUV420pData:result width:decoder->GetResultWidth() height:decoder->GetResultHeight()];
                });
               
                decoder->ReleaseResultData();
            }
        }
    });
    
   
    
}



@end
