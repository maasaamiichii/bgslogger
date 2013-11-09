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
#import <CoreLocation/CLGeocoder.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>




@interface MapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate,UIAlertViewDelegate,AVAudioRecorderDelegate,AVAudioSessionDelegate/*,IASKSettingsDelegate*/> {
    
    CLLocationManager *locationManager; //LocationManager
    MKMapView *mapView; //MapView
    AVAudioRecorder *myRecorder; //レコーダー
    NSTimer *timer; //レコード時のタイマー
    NSString *fileName; //サーバーに送るファイル名
    NSURL *recordingURL; //録音ファイルのパス
    UIButton *accessoryBtn; //アノテーションのボタン
   // IASKAppSettingsViewController *appSettingsViewController; //設定画面のビューコントローラ
            
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic,retain) UIButton *accessoryBtn;


-(void) onResume; //アプリケーションがアクティブの時に、位置情報更新
-(void) onPause; //アプリケーションがアクティブでないときは位置情報を更新しない
- (IBAction)reloadUserLocation:(id)sender; //更新ボタンを押されたときのアクション
-(void) reloadUserLocation;
//- (IBAction)showSettingView:(id)sender; //設定画面を表示するアクション
-(void) startTimer; //レコード時のタイマーをスタート
-(void) stopTimer; //レコード時のタイマーをストップ
-(void) displayCurrentRecordingTime; //現在のレコード、プレイ時間を表示
-(void) getNearStationsFromDB:(CLLocation*) location; //現在地の近くの駅情報を取得

@end



