//
//  SoundViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/30.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface SoundViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate,AVAudioPlayerDelegate,UIActionSheetDelegate>{
    
    AVAudioPlayer *myPlayer; //プレイヤー
    NSURL *playURL; //再生ファイルのパス
    UIActionSheet *actionSheet;
    NSTimer *playTimer; //プレイ時のタイマー
    UISlider *sl; //再生ファイルの再生位置を表すスライダー
    UILabel *leftLabel;
    UILabel *rightLabel;
    NSString *deleteFile;
    
}


@property (retain, nonatomic) IBOutlet UITableView *soundTable;
@property (retain, nonatomic) NSTimer *playTimer;
@property (retain, nonatomic) UISlider *sl;
-(void) startTimer; //プレイ時のタイマーをスタート
-(void) stopTimer; //プレイ時のタイマーをストップ
//-(void)deleteUserLog;

@end
