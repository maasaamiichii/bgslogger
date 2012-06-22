//
//  MapViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "MapViewController.h"
#import "CustomAnnotation.h"
#import "LocationData.h"
#import "ASIFormDataRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"


@interface MapViewController ()

@end



@implementation MapViewController
@synthesize mapView;
@synthesize locationManager;
@synthesize timer;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // 使用している機種が録音に対応しているか
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if ([audioSession inputIsAvailable]) {
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    }
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }
    // 録音機能をアクティブにする
    [audioSession setActive:YES error:&error];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }

    
    
    //locationManager初期化
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    
    // 位置情報サービスが利用できるかどうかをチェック
    if ([CLLocationManager locationServicesEnabled]) {
        
        // 測位開始
        [locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
    
    
    //mapviewのデリゲート設定、現在地表示設定
    [mapView setDelegate: self];
    mapView.showsUserLocation = YES;
    [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    mapView.mapType = MKMapTypeSatellite;

    //ナビゲーションバーのタイトルをセット
    self.navigationItem.title = @"BGSLogger";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0. green:0.7 blue:1.0 alpha:1.0]];
    

}


- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [mapView release];
    [locationManager release];
    [myRecorder release];
    [myPlayer release];
    [timer release];
    [super dealloc];
}


//直線を描画するデリゲートメソッド
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    MKPolylineView *view = [[[MKPolylineView alloc] initWithOverlay:overlay]
                            autorelease];
    view.strokeColor = [UIColor blueColor];
    view.lineWidth = 5.0;
    return view;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    
}


// 位置情報更新時に呼ばれるデリゲートメソッド
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    //緯度・経度を出力
    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f",
          [newLocation coordinate].latitude,
          [newLocation coordinate].longitude);
    
    
    //データを格納するシングルトンの作成
    LocationData *locationData = [LocationData sharedCenter];
    
    //ユーザの緯度経度をセット
    [locationData setUserLatitude:[newLocation coordinate].latitude];
    [locationData setUserLongitude:[newLocation coordinate].longitude];
    
    
    
    //mapviewの表示設定
    MKCoordinateRegion region = MKCoordinateRegionMake([newLocation coordinate], MKCoordinateSpanMake(0.02, 0.02));
    [mapView setCenterCoordinate:[newLocation coordinate]];
    [mapView setRegion:region];
    
    //現在地の近くの駅を取得
    [self getNearStations:newLocation];
    
        
    //更新をやめる
    [locationManager stopUpdatingLocation];
    
}



// 測位失敗時や、5位置情報の利用をユーザーが「不許可」とした場合などに呼ばれる
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError");
}





//測位機能オン
-(void) onResume {
    if (nil == locationManager && [CLLocationManager locationServicesEnabled])
        [locationManager startUpdatingLocation]; //測位再開
    
}

//測位機能オフ
-(void) onPause {
    if (nil == locationManager && [CLLocationManager locationServicesEnabled])
        [locationManager stopUpdatingLocation]; //測位停止
}



//アノテーションの設定
-(MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id)annotation{
    
    //現在地にはデフォルトの青色のピンを使う
    if(annotation == self.mapView.userLocation){
        return nil;
    }
    
    //他のピンの設定
    else {
        static NSString *PinIdentifier = @"Pin";
        MKPinAnnotationView *pav = (MKPinAnnotationView*) [self.mapView dequeueReusableAnnotationViewWithIdentifier:PinIdentifier];
        
        if(pav == nil){
            pav = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinIdentifier] autorelease];
            pav.animatesDrop = YES;  // アニメーションをする
            pav.pinColor = MKPinAnnotationColorRed;  // ピンの色を赤にする
            pav.canShowCallout = YES;  // ピンタップ時にコールアウトを表示する
        
            //UIImageを指定した生成例
            UIImage *image;
            if(!myRecorder.isRecording){
                image = [UIImage imageNamed:@"rec.png"];
            }
            else if(myRecorder.isRecording){
                image = [UIImage imageNamed:@"stop.png"];
            }
            accessoryBtn = [[[UIButton alloc] 
                            initWithFrame:CGRectMake(0, 0, 30, 30)] autorelease];  // ボタンのサイズを指定する
            [accessoryBtn setBackgroundImage:image forState:UIControlStateNormal];  // 画像をセットする
            pav.rightCalloutAccessoryView = accessoryBtn;
        }
        return pav;
    }
    
}

//アノテーションが選択された時に呼ばれるデリゲートメソッド
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    //UIImageを指定した生成例
    UIImage *image;
    
    //録音中でないときは録音画像をセット
    if(!myRecorder.isRecording){
        image = [UIImage imageNamed:@"rec.png"];
    }
    
    //録音中は停止画像をセット
    else if(myRecorder.isRecording){
        image = [UIImage imageNamed:@"stop.png"];
    }
    accessoryBtn = [[[UIButton alloc] 
                      initWithFrame:CGRectMake(0, 0, 30, 30)]autorelease];  // ボタンのサイズを指定する
    [accessoryBtn setBackgroundImage:image forState:UIControlStateNormal];  // 画像をセットする
    view.rightCalloutAccessoryView = accessoryBtn;
}


//アノテーションが選択解除された時に呼ばれるデリゲートメソッド
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    
    UIImage *image;
    
    //録音中でないときは録音画像をセット
    if(!myRecorder.isRecording){
        image = [UIImage imageNamed:@"rec.png"];
    }
    
    //録音中は停止画像をセット
    else if(myRecorder.isRecording){
        image = [UIImage imageNamed:@"stop.png"];
    }
    accessoryBtn = [[[UIButton alloc] 
                    initWithFrame:CGRectMake(0, 0, 30, 30)]autorelease];  // ボタンのサイズを指定する
    [accessoryBtn setBackgroundImage:image forState:UIControlStateNormal];  // 画像をセットする
    view.rightCalloutAccessoryView = accessoryBtn;
}



//アノテーションのアクセサリーボタンをタップしたときに呼ばれるデリゲートメソッド
- (void) mapView:(MKMapView*)_mapView annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control { 
    
    
    NSLog(@"annotationView annotation is %@", annotationView.annotation); 
    NSLog(@"annotationView title is %@", annotationView.annotation.title); // アノテーションバルーンのtitle
    NSLog(@" annotationView subtitle is %@", annotationView.annotation.subtitle); // アノテーションバルーンのsubtitle
      
    LocationData *locationData = [LocationData sharedCenter];
    
    
    //録音中でないとき、レコーダを生成する
    if(myRecorder == nil && !myRecorder.isRecording){
        
        //日付を取得
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat  = @"yyyyMMddHHmmss";
        NSString *dateString = [df stringFromDate:[NSDate date]];
        
        //録音先のパスを決定する
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [filePaths objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@.caf",dateString];
        NSString *path = [documentDir stringByAppendingPathComponent:filePath];
        recordingURL = [NSURL fileURLWithPath:path];
        
        //サーバーに送るファイル名をセット
        fileName = [[NSString alloc]initWithString:filePath];
                        
        
        NSError *recordError = nil;
        
        // 録音の設定 AVNumberOfChannelsKey チャンネル数1
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                                  [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                  [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                  [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                  nil];
        
        //recorderを用意する
        myRecorder = [[AVAudioRecorder alloc] initWithURL:recordingURL settings:settings error: &recordError];
    
        if( recordError ){
            NSLog(@"recordError = %@",recordError);
            return;
        }
    
        myRecorder.delegate = self;
        [myRecorder prepareToRecord];
    }
    
    //録音中でないとき、録音確認のアラートビューを表示
    if(!myRecorder.isRecording){
        
        [locationData setFromLat:annotationView.annotation.coordinate.latitude];
        [locationData setFromLon:annotationView.annotation.coordinate.longitude];
        [locationData setFromName:annotationView.annotation.title];

        
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.delegate = self;
        if(annotationView.annotation == mapView.userLocation)
            alert.title = [NSString stringWithFormat:@"現在地:緯度%f,経度%f",annotationView.annotation.coordinate.latitude,annotationView.annotation.coordinate.longitude];
        else 
        alert.title = [NSString stringWithFormat:@"現在地：%@",annotationView.annotation.title];
        alert.message = @"録音を開始します。";
        [alert addButtonWithTitle:@"いいえ"];
        [alert addButtonWithTitle:@"はい"];
        [alert show];
    }
    
    //録音中のとき、録音停止確認のアラートビューを表示
    else if(myRecorder.isRecording){
        [locationData setToLat:annotationView.annotation.coordinate.latitude];
        [locationData setToLon:annotationView.annotation.coordinate.longitude];
        [locationData setToName:annotationView.annotation.title];
        
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.delegate = self;
        alert.title = [NSString stringWithFormat:@"現在地：%@",annotationView.annotation.title];
        alert.message = @"録音を停止します。";
        [alert addButtonWithTitle:@"いいえ"];
        [alert addButtonWithTitle:@"はい"];
        [alert show];
    }
    
    
}


// アラートのボタンが押された時に呼ばれるデリゲートメソッド
-(void)alertView:(UIAlertView*)alertView    clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            //いいえボタン
            
            break;
            
        case 1:
            //はいボタン
            //録音中でないとき、録音スタート
            if(!myRecorder.recording && !myPlayer.isPlaying){
                NSLog(@"record start");
                [myRecorder record];
                
                [self startTimer];
                
                //ステータスバーの色を変える
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
                
                //ナビゲーションバーの色を変える
                [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
            }
            
            //録音中のとき、録音ストップ
            else if(myRecorder.recording && !myPlayer.isPlaying){
                [self stopTimer];
                [myRecorder stop];
                [locationManager stopUpdatingLocation];
                self.navigationItem.title = @"BGSLogger";
                
                //ステータスバーの色を変える
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                
                 //ナビゲーションバーの色を変える
                [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0. green:0.7 blue:1.0 alpha:1.0]];
                
            }
            break;
    }
    
}


//現在地のリロード
- (IBAction)reloadUserLocation:(id)sender {
    if ([CLLocationManager locationServicesEnabled]) {
        
        // 測位開始
        [locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
    for (id annotation in mapView.annotations) {
        NSLog(@"annotation %@", annotation);
        
        if (![annotation isKindOfClass:[MKUserLocation class]]){
            
            [mapView removeAnnotation:annotation];
        }
    }
    
}


//レコード、プレイ時のタイマースタート
-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0
                                                  target:self
                                                selector:@selector(displayCurrentRecordingTime)
                                                userInfo:nil
                                                 repeats:YES];
}


//レコード、プレイ時のタイマーストップ
-(void)stopTimer{
    if(self.timer){
        [self.timer invalidate];
    }
}


//現在のレコード、プレイ時間を表示
- (void) displayCurrentRecordingTime{
    if(myRecorder && myRecorder.recording){
        self.navigationItem.title = [NSString stringWithFormat:@"録音中:%f",myRecorder.currentTime];
    }
    else if(myPlayer && myPlayer.isPlaying){
        self.navigationItem.title = [NSString stringWithFormat:@"再生中:%f",myPlayer.currentTime];
    }
    
}


//録音終了時に呼ばれるデリゲートメソッド
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"record stop");
    myRecorder = nil;
    [self stopTimer];
    [self postUserLocation];
    
}

//再生終了時に呼ばれるデリゲートメソッド
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"play stop");
    [self stopTimer];
    myPlayer = nil;
}




//現在地の近くの駅を取得
-(void)getNearStations:(CLLocation*) location{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/SetStations.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
    [request setPostValue:[NSString stringWithFormat:@"%f", location.coordinate.latitude] forKey:@"user_lat"];
    [request setPostValue:[NSString stringWithFormat:@"%f", location.coordinate.longitude] forKey:@"user_lon"];
    
    [request setTimeOutSeconds:30];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(stationGetSucceeded:)];
    [request setDidFailSelector:@selector(stationGetFailed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
}



//リクエスト成功時
- (void)stationGetSucceeded:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    //帰ってきた文字列
    NSString *resString = [request responseString];
    NSLog(@"%@\n", resString);
    
    //データを格納するシングルトン
    LocationData *locationData = [LocationData sharedCenter];
    locationData.nearStations = [[[NSMutableArray alloc]init] autorelease];
    
    //帰ってきたデータを';'でセパレート、アレイに格納
    NSMutableArray*gotStations = (NSMutableArray*)[resString componentsSeparatedByString:@";"];
    
    NSMutableDictionary *dict[[gotStations count]-1];
    
    //各データをkeyごとにディクショナリに追加
    for(int i = 0; i < [gotStations count] - 1; i++){
        dict[i] = [[[NSMutableDictionary alloc]init ]autorelease];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:0] forKey:@"station_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:1] forKey:@"line_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:2] forKey:@"lat"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:3] forKey:@"lon"];
        [locationData.nearStations addObject:dict[i]];
    }
    
    NSLog(@"%@",[locationData.nearStations description]);
    
    NSLog(@"stationgetsuceeded");
    
    
    //取得した駅のアノテーションを追加
    for(int i = 0; i < [locationData.nearStations count]; i++){
         [mapView addAnnotation:
            [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake
                                                ([[[locationData.nearStations objectAtIndex:i] objectForKey:@"lat"] doubleValue],
                                                 [[[locationData.nearStations objectAtIndex:i] objectForKey:@"lon"] doubleValue])
                                                 title:[[locationData.nearStations objectAtIndex:i] objectForKey:@"station_name"]
                                                 subtitle:[[locationData.nearStations objectAtIndex:i] objectForKey:@"line_name"]
                                                 ]autorelease]];
    }

}


//リクエスト失敗時
- (void)stationGetFailed:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:nil message:@"取得できませんでした。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [notgetalert show];
    [notgetalert release];
    NSString *resString = [request responseString];
    NSLog(@"%@", resString);
    NSLog(@"stationgetfailed");
}



-(void)postUserLocation{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    LocationData *locationData = [LocationData sharedCenter];
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/InsertRecordInformation.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
    [request setPostValue:[NSString stringWithFormat:@"%f", [locationData getFromLat]] forKey:@"from_lat"];
    [request setPostValue:[NSString stringWithFormat:@"%f", [locationData getFromLon]] forKey:@"from_lon"];
    [request setPostValue:[NSString stringWithFormat:@"%f", [locationData getToLat]] forKey:@"to_lat"];
    [request setPostValue:[NSString stringWithFormat:@"%f", [locationData getToLon]] forKey:@"to_lon"];
    [request setPostValue:[locationData getFromName] forKey:@"from_name"];
    [request setPostValue:[locationData getToName] forKey:@"to_name"];
    [request setPostValue:fileName forKey:@"file_name"];
    
    [request setTimeOutSeconds:30];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(postUserLocationSucceeded:)];
    [request setDidFailSelector:@selector(postUserLocationFailed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
}


//リクエスト成功時
- (void)postUserLocationSucceeded:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:nil message:@"アップロード成功" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [notgetalert show];
    [notgetalert release];
    NSString *resString = [request responseString];
    NSLog(@"%@", resString);
    NSLog(@"postUserLocationSuceeded");
    
}

//リクエスト失敗時
- (void)postUserLocationFailed:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:nil message:@"サーバーへのアップロードに失敗しました。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [notgetalert show];
    [notgetalert release];
    NSString *resString = [request responseString];
    NSLog(@"%@", resString);
    NSLog(@"postUserLocationFailed");
}


//再生メソッドメモ
/*
//再生スタートボタン
- (IBAction)startPlay:(id)sender {
    
    if(myPlayer == nil){
        //playerを用意
        NSError *playError = nil;
        myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordingURL error: &playError];
        
        if( playError ){
            NSLog(@"playError = %@",playError);
            return;
        }
        myPlayer.delegate = self;
    }
    
    if(!myPlayer.isPlaying && !myRecorder.recording){
        NSLog(@"play start");
        [myPlayer play];
        [self startTimer];
    }
}

//一時停止ボタン
- (IBAction)pausePlay:(id)sender {
    if(myPlayer.isPlaying && !myRecorder.recording){
        NSLog(@"play pause");
        [myPlayer pause];
    }
}

//再生停止ボタン
- (IBAction)stopPlay:(id)sender {
    if(myPlayer.isPlaying && !myRecorder.recording){ 
        NSLog(@"play stop");
        [myPlayer stop];
        [self stopTimer];
        myPlayer.currentTime = 0;
        myPlayer = nil;
    }
}*/



@end
