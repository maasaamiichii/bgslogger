//
//  MapViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>


@interface MapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate,UIAlertViewDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate> {
    
    CLLocationManager *locationManager; //LocationManager
    MKMapView *mapView; //MapView
    
    AVAudioRecorder *myRecorder; //レコーダー
    AVAudioPlayer *myPlayer; //プレイヤー
    NSTimer *timer; //レコード、プレイ時のタイマー
    
    NSString *fileName; //サーバーに送るファイル名
    
    NSURL *recordingURL; //録音ファイルのパス
    UIButton *accessoryBtn; //アノテーションのボタン
            
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;



-(void) onResume; //アプリケーションがアクティブの時に、位置情報更新
-(void) onPause; //アプリケーションがアクティブでないときは位置情報を更新しない
- (IBAction)reloadUserLocation:(id)sender;
-(void) startTimer; //レコード、プレイ時のタイマーをスタート
-(void) stopTimer; //レコード、プレイ時のタイマーをストップ
-(void) displayCurrentRecordingTime; //現在のレコード、プレイ時間を表示
-(void) getNearStations:(CLLocation*) location; //現在地の近くの駅情報を取得
-(void) postUserLocation; //ユーザの位置情報、音声ファイル情報をサーバーにポスト

@end



