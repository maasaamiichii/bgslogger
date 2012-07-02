//
//  LogMapViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "CustomAnnotation.h"
#import <AudioToolbox/AudioToolbox.h>

@interface LogMapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate,UIAlertViewDelegate,AVAudioPlayerDelegate>{
    
    AVAudioPlayer *myPlayer; //プレイヤー
    int playLogNumber; //再生中のログの番号
    MKPolyline *line; //マップ上に描画するライン
    NSString *accountName; //ユーザアカウント名
    NSTimer *playTimer; //プレイ時のタイマー
    NSURL *playURL; //再生ファイルのパス
    UISlider *sl; //再生ファイルの再生位置を表すスライダー
    CustomAnnotation *userLogAnnotation; //ユーザ位置を表すカスタムアノテーション
    double initial_lat; //ユーザ位置アノテーションの初期位置　経度
    double initial_lon; //ユーザ位置アノテーションの初期位置　緯度
    double lat_gap_step; //アノテーションを一回のタイマーで移動させる量 経度
    double lon_gap_step; //アノテーションを一回のタイマーで移動させる量 緯度
    NSString *dbRes;
    Boolean isPlaying;
    
}

@property (retain, nonatomic) IBOutlet MKMapView *logMapView;
@property (retain, nonatomic) MKPolyline *line;
@property (retain, nonatomic) NSTimer *playTimer;
@property (retain, nonatomic) CustomAnnotation *userLogAnnotation;
@property (retain, nonatomic) UISlider *sl;
@property (retain, nonatomic) AVAudioPlayer *myPlayer;
@property (readwrite) Boolean isPlaying;

- (IBAction)playLog:(id)sender;


//-(void)getUserLog; //ユーザのログを取得
-(double)range1:(double)gap1 range2:(double)gap2; //ラインを描画したときの地図の表示範囲を取得
-(void) startTimer; //プレイ時のタイマーをスタート
-(void) stopTimer; //プレイ時のタイマーをストップ
-(void)stopPlay; //再生停止
-(void)reloadLogData; //ログデータをリロード
-(void)setCurrentPlayTime; //スライダーの値が変更されたときに呼ばれるメソッド、再生ファイルの位置を変更する

@end
