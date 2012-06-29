//
//  LogMapViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "LogMapViewController.h"
#import "ASIFormDataRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "UserLogData.h"
#import "SVProgressHUD.h"
#import "LocationData.h"
#import "CustomAnnotationView.h"

@interface LogMapViewController ()


-(double) getMaxLat:(UserLogData *)userlogdata;
-(double) getMinLat:(UserLogData *)userlogdata;
-(double) getMaxLon:(UserLogData *)userlogdata;
-(double) getMinLon:(UserLogData *)userlogdata;

@end

@implementation LogMapViewController
@synthesize logMapView;
@synthesize line;
@synthesize playTimer;
@synthesize userLogAnnotation;
@synthesize sl;

static const NSInteger kTagAlert1 = 1; //再生開始アラート
static const NSInteger kTagAlert2 = 2; //録音停止アラート
static const NSInteger kTagAlert3 = 3; //駅取得失敗アラート
static const NSInteger kTagAlert4 = 4; //ポスト成功アラート
static const NSInteger kTagAlert5 = 5; //ポスト失敗アラート

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
    playLogNumber = 0;
    
    //mapviewのデリゲート設定、現在地表示設定
    [logMapView setDelegate: self];
    logMapView.mapType = MKMapTypeSatellite;

    //ナビゲーションバーのタイトルをセット
    self.navigationItem.title = @"BGSLogViewer";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1.0 green:0.7 blue:0.0 alpha:1.0]];
    
    line = nil;
    
    userLogAnnotation = [[CustomAnnotation alloc] initWithLocationCoordinate:CLLocationCoordinate2DMake(0,0) title:@"移動中なう♪" subtitle:nil];

}

- (void) viewWillAppear:(BOOL)animated{
    // 使用している機種が録音に対応しているか
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }
    // 録音機能をアクティブにする
    [audioSession setActive:YES error:&error];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }

    
    [self reloadLogData];
}

- (void)viewDidUnload
{
    [self setLogMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (void)dealloc {
    [logMapView release];
    [line release];
    [myPlayer release];
    [playTimer release];
    [userLogAnnotation release];
    [sl release];
    [super dealloc];
}


//ログデータをリロード
-(void) reloadLogData{
    //ログの更新
    for (id annotation in logMapView.annotations) {
        if (![annotation isKindOfClass:[MKUserLocation class]]){
            
            [logMapView removeAnnotation:annotation];
        }
    }
    
    [self getUserLog];
}



//直線を描画するデリゲートメソッド
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    MKPolylineView *view = [[[MKPolylineView alloc] initWithOverlay:overlay]
                            autorelease];
    view.strokeColor = [UIColor blueColor];
    view.lineWidth = 5.0;
    return view;
}


//アノテーションの設定
-(MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id)annotation{
    
    if(annotation == userLogAnnotation){
        CustomAnnotationView *annotationView;
        NSString* identifier = @"currentUser"; // 再利用時の識別子
        
        // 再利用可能な MKAnnotationView を取得
        annotationView = (CustomAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if(nil == annotationView) {
            //再利用可能な MKAnnotationView がなければ新規作成
            annotationView = [[[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier] autorelease];
        }
        //アノテーションを動かすためのおまじない
        [annotation willChangeValueForKey:@"coordinate"];
        [annotation didChangeValueForKey:@"coordinate"];
        
        
        annotationView.annotation = annotation;
        annotationView.canShowCallout = YES;
        return annotationView;
    }
        
    
    static NSString *PinIdentifier = @"Pin";
    MKPinAnnotationView *pav = (MKPinAnnotationView*) [self.logMapView dequeueReusableAnnotationViewWithIdentifier:PinIdentifier];
    
    if(pav == nil){
        pav = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinIdentifier] autorelease];
        pav.animatesDrop = YES;  // アニメーションをする
        pav.pinColor = MKPinAnnotationColorRed;  // ピンの色を赤にする
        pav.canShowCallout = YES;  // ピンタップ時にコールアウトを表示する
        }
    return pav;
    
}


//アノテーションのアクセサリーボタンをタップしたときに呼ばれるデリゲートメソッド
- (void) mapView:(MKMapView*)_mapView annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control { 
    
    
}


//ユーザのログの再生アクション
- (IBAction)playLog:(id)sender {
    
    UserLogData *userLogData = [UserLogData sharedCenter];
    
    //開始点と終了点を結ぶ線を描画
    if(playLogNumber < [[userLogData stations] count]){
        
        CLLocationCoordinate2D coors[[[userLogData stations] count]][2];
    
        //開始点の座標をセット
        coors[playLogNumber][0] = CLLocationCoordinate2DMake([[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lat"] doubleValue], [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lon"] doubleValue]);
        
        //終了点の座標をセット
        coors[playLogNumber][1] = CLLocationCoordinate2DMake([[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_lat"] doubleValue], [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_lon"] doubleValue]);
        
        //直線に座標をセット
        line = [MKPolyline polylineWithCoordinates:coors[playLogNumber] count:2];
        
        //描画
        [logMapView addOverlay:line];
        
    
        double from_lat = [[[userLogData.stations objectAtIndex:playLogNumber] 
                        objectForKey:@"from_lat"] doubleValue];
        double to_lat =[[[userLogData.stations objectAtIndex:playLogNumber]
                     objectForKey:@"to_lat"] doubleValue];
        double from_lon = [[[userLogData.stations objectAtIndex:playLogNumber] 
                        objectForKey:@"from_lon"] doubleValue];
        double to_lon = [[[userLogData.stations objectAtIndex:playLogNumber] 
                      objectForKey:@"to_lon"] doubleValue];
    
        //座標の中心をセット
        CLLocationCoordinate2D average_coordinate = CLLocationCoordinate2DMake((from_lat + to_lat) / 2.0, (from_lon + to_lon) / 2.0);
    
        //表示範囲を取得
        double range = [self range1:fabs(from_lat - to_lat) range2:fabs(from_lon - to_lon)];
    
        //logMapviewの表示設定
        [logMapView setCenterCoordinate:average_coordinate];
        MKCoordinateRegion region = MKCoordinateRegionMake(average_coordinate, MKCoordinateSpanMake(range, range));
        [logMapView setCenterCoordinate:average_coordinate];
        [logMapView setRegion:region];
        
        
        //再生先のパスを決定する
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [filePaths objectAtIndex:0];
        NSString *path = [documentDir stringByAppendingPathComponent:[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"file_name"]];
        playURL = [NSURL fileURLWithPath:path];
        
        
        //playerを用意
        NSError *playError = nil;
        myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:playURL error: &playError];
        
        if( playError ){
            NSLog(@"playError = %@",playError);
            return;
        }
        myPlayer.delegate = self;
        
        //再生中でない時
        if(!myPlayer.isPlaying){
            //再生スタート
            [myPlayer play];
            [self startTimer];
            
            //ステータスバーの色を変える
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
            //ナビゲーションバーの色を変える
            [self.navigationController.navigationBar setTintColor:[UIColor greenColor]];
            //ナビゲーションバーのボタンを変更
             UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stopPlay)];
             self.navigationItem.rightBarButtonItem = btn;
           
            //現在の向きを取得
            UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
            
            if( orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft ){
                //スライダーを追加
                sl = [[UISlider alloc] initWithFrame:CGRectMake(20, 190, 440, 10)];
            }
            else{
                //スライダーを追加
                sl = [[UISlider alloc] initWithFrame:CGRectMake(10, 330, 300, 10)];
                
            }
            sl.minimumValue = 0.0;  // 最小値を0に設定
            sl.maximumValue = myPlayer.duration;  // 最大値をファイルの長さに設定
            sl.value = 0.0; //初期値を0にセット
            
            //値が変更されたときに呼ばれるメソッドを設定
            [sl addTarget:self action:@selector(setCurrentPlayTime) forControlEvents:UIControlEventValueChanged];
            //スライダーを追加
            [self.logMapView addSubview:sl];
            
            //ユーザの位置を表示するアノテーションを追加
            initial_lat = [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lat"] doubleValue];
            initial_lon = [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lon"] doubleValue];
            CLLocationCoordinate2D co;
            co.latitude = initial_lat;
            co.longitude = initial_lon;
            [userLogAnnotation changeCoordinate:co];
            [logMapView addAnnotation:userLogAnnotation];
            
            //移動の差分を求める
            double lat_gap = [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_lat"] doubleValue] -
                        [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lat"] doubleValue];
            double lon_gap = [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_lon"] doubleValue] -
                        [[[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_lon"] doubleValue];
            //ステップを計算
            lat_gap_step = lat_gap / myPlayer.duration * (1.0/5.0);
            lon_gap_step = lon_gap / myPlayer.duration * (1.0/5.0);

            
            //アラートビューの表示
            NSString *from_date = [[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_date"];
            NSString *to_date = [[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_date"];
            NSString *from_name = [[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"from_name"];
            NSString *to_name = [[userLogData.stations objectAtIndex:playLogNumber] objectForKey:@"to_name"];
            NSString *alertString = [NSString stringWithFormat:@"%@ %@から %@ %@へ移動中...",from_date,from_name,to_date,to_name];            
            UIAlertView *playalert = [[UIAlertView alloc] initWithTitle:nil message:alertString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [playalert show];
            [playalert release];
            

            
        }
        playLogNumber++;
    }
    else if(playLogNumber == [[userLogData stations] count]){
        double max_lat = [self getMaxLat:userLogData];
        double min_lat = [self getMinLat:userLogData];
        double max_lon = [self getMaxLon:userLogData];
        double min_lon = [self getMinLon:userLogData];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake((max_lat + min_lat) / 2.0, (max_lon + min_lon) / 2.0);
        
        double range = [self range1:fabs(max_lat - min_lat) range2:fabs(max_lon - min_lon)];
        
        [logMapView setCenterCoordinate:coordinate];
        //mapviewの表示設定
        MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(range,range));
        [logMapView setCenterCoordinate:coordinate];
        [logMapView setRegion:region];
        
        
        UIAlertView *alllogalert = [[UIAlertView alloc] initWithTitle:nil message:@"これまでの行動範囲はこんな感じです" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alllogalert show];
        [alllogalert release];
        playLogNumber++;
    }
    else {
        for (id overlay in logMapView.overlays) {
            [logMapView removeOverlay:overlay];
        }
        playLogNumber = 0;
    }
}


//再生終了時に呼ばれるデリゲートメソッド ナビゲーションバーをもとに戻す
-(void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self stopTimer];
    myPlayer.currentTime = 0;
    myPlayer = nil;
    
    //ナビゲーションバーボタンを変更
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playLog:)];
    self.navigationItem.rightBarButtonItem = btn;
    self.navigationItem.title = @"BGSLogViewer";
    self.navigationItem.leftBarButtonItem = nil;
    [sl removeFromSuperview];
    sl = nil;
    
    
    //ステータスバーの色を変える
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    //ナビゲーションバーの色を変える
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1.0 green:0.7 blue:0.0 alpha:1.0]];
    
    [logMapView removeAnnotation:userLogAnnotation];
}


//レコード、プレイ時のタイマースタート
-(void)startTimer{
    self.playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0
                                                  target:self
                                                selector:@selector(displayCurrentPlayingTime)
                                                userInfo:nil
                                                 repeats:YES];
    
}


//レコード、プレイ時のタイマーストップ
-(void)stopTimer{
    if(self.playTimer){
        [self.playTimer invalidate];
    }
}

//現在のレコード、プレイ時間を表示
- (void) displayCurrentPlayingTime{
    if(myPlayer && myPlayer.isPlaying){
        sl.value = myPlayer.currentTime;
        self.navigationItem.title = [NSString stringWithFormat:@"再生中 %f / %f", myPlayer.currentTime, myPlayer.duration];
        
        //アノテーションを動かす
        double curentUserLat = userLogAnnotation.coordinate.latitude + lat_gap_step;
        double currentUserLon = userLogAnnotation.coordinate.longitude + lon_gap_step;
        CLLocationCoordinate2D co;
        co.latitude = curentUserLat;
        co.longitude = currentUserLon;
        [userLogAnnotation changeCoordinate:co]; 
        [logMapView addAnnotation:userLogAnnotation];
        
        //現在の向きを取得
        UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
        
        //画面の向きに応じてスライダーの位置を変更する
        if( orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft ){
            sl.frame = CGRectMake(20, 190, 440, 10);
        }
        else{
            sl.frame = CGRectMake(10, 330, 300, 10);
            
        }

        
    }
}

//ストップボタンを押されたときに呼ばれるメソッド
-(void)stopPlay{
    
    if(myPlayer.isPlaying){ 
        //再生ストップ
        [myPlayer stop];
        [self stopTimer];
        myPlayer.currentTime = 0;
        myPlayer = nil;
        
        //ナビゲーションバーボタンを変更
        UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playLog:)];
        self.navigationItem.rightBarButtonItem = btn;
        self.navigationItem.title = @"BGSLogViewer";
        self.navigationItem.leftBarButtonItem = nil;
        [sl removeFromSuperview];
        sl = nil;
        
        //ステータスバーの色を変える
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        //ナビゲーションバーの色を変える
        [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1.0 green:0.7 blue:0.0 alpha:1.0]];
        
        //アノテーションを削除
        [logMapView removeAnnotation:userLogAnnotation];
    }
}

//スライダーの値が変更されたときに呼ばれるメソッド　ファイル再生位置を変更する
-(void)setCurrentPlayTime{

    [self stopTimer];
    
    //再生位置をスライダーの値にセット
    if(myPlayer)  myPlayer.currentTime = sl.value;
    
    //アノテーションを動かす
    double curentUserLat = initial_lat + lat_gap_step * myPlayer.currentTime * 5.0;
    double currentUserLon = initial_lon + lon_gap_step * myPlayer.currentTime * 5.0;
    CLLocationCoordinate2D co;
    co.latitude = curentUserLat;
    co.longitude = currentUserLon;
    [userLogAnnotation changeCoordinate:co]; 
    [logMapView addAnnotation:userLogAnnotation];

    
    [self startTimer];
}




//ユーザのログデータを取得
-(void)getUserLog{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    LocationData *locationData = [LocationData sharedCenter];
    
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/SetLog.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
    [request setPostValue:[NSString stringWithFormat:@"%@",locationData.account_name] forKey:@"account_name"];
    [request setTimeOutSeconds:30];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(stationGetSucceeded:)];
    [request setDidFailSelector:@selector(stationGetFailed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
    [SVProgressHUD showWithStatus:@"ログを取得しています。"];

}

//リクエスト成功時
- (void)stationGetSucceeded:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    //帰ってきた文字列
    NSString *resString = [request responseString];
    if([resString length] == 0){
        UIAlertView *notdataalert = [[UIAlertView alloc] initWithTitle:nil message:@"このアカウントのログデータはありません。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [notdataalert show];
        [notdataalert release];
        return;
        
    }
    
    //データを格納するシングルトン
    UserLogData *userLogData = [UserLogData sharedCenter];
    userLogData.stations = [[[NSMutableArray alloc]init] autorelease];
    
    //帰ってきたデータを';'でセパレート、アレイに格納
   // NSMutableArray *gotStations = [[[NSMutableArray  alloc] init] autorelease];
    NSMutableArray *gotStations = (NSMutableArray*)[resString componentsSeparatedByString:@";"];
    
    NSMutableDictionary *dict[[gotStations count]-1];
    
    //各データをkeyごとにディクショナリに追加
    for(int i = 0; i < [gotStations count] - 1; i++){
        dict[i] = [[[NSMutableDictionary alloc]init ]autorelease];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:0] forKey:@"from_lat"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:1] forKey:@"from_lon"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:2] forKey:@"from_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:3] forKey:@"from_date"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:4] forKey:@"to_lat"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:5] forKey:@"to_lon"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:6] forKey:@"to_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:7] forKey:@"to_date"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:8] forKey:@"file_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:9] forKey:@"date"];
        [userLogData.stations addObject:dict[i]];
    }
    
    NSLog(@"getUserLogSucceeded");
    
    
    //取得した駅のアノテーションを追加
    for(int i = 0; i < [userLogData.stations count]; i++){
        [logMapView addAnnotation:
         [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake
           ([[[userLogData.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue],
            [[[userLogData.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue])
                                                        title:[[userLogData.stations objectAtIndex:i] objectForKey:@"from_name"]
                                                     subtitle:[[userLogData.stations objectAtIndex:i] objectForKey:@"from_date"]]
           autorelease]];
        [logMapView addAnnotation:
         [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake
           ([[[userLogData.stations objectAtIndex:i] objectForKey:@"to_lat"] doubleValue],
            [[[userLogData.stations objectAtIndex:i] objectForKey:@"to_lon"] doubleValue])
                                                        title:[[userLogData.stations objectAtIndex:i] objectForKey:@"to_name"]
                                                     subtitle:[[userLogData.stations objectAtIndex:i] objectForKey:@"to_date"]]
          autorelease]];
    }
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[[userLogData.stations objectAtIndex:0] objectForKey:@"from_lat"] doubleValue] , [[[userLogData.stations objectAtIndex:0] objectForKey:@"from_lon"] doubleValue]);
    
    [logMapView setCenterCoordinate:coordinate];
    //mapviewの表示設定
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.01));
    [logMapView setCenterCoordinate:coordinate];
    [logMapView setRegion:region];

}


//リクエスト失敗時
- (void)stationGetFailed:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:nil message:@"取得できませんでした。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [notgetalert show];
    [notgetalert release];
    NSLog(@"getUserLogFailed");
}


//レンジを設定
-(double)range1:(double)gap1 range2:(double)gap2{
    if(gap1 > gap2) return gap1;
    else return gap2;
    
}


//緯度の最大値を取得
-(double) getMaxLat:(UserLogData *)userlogdata{
    double temp_from_lat = [[[userlogdata.stations objectAtIndex:0] 
                             objectForKey:@"from_lat"] doubleValue];
    
    double temp_to_lat = [[[userlogdata.stations objectAtIndex:0] 
                           objectForKey:@"to_lat"] doubleValue];
    
    for(int i=0; i<[[userlogdata stations] count]; i++){
        if([[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue] > temp_from_lat){
            temp_from_lat = [[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue];
        }
    }
    
    for(int j=0;j<[[userlogdata stations] count]; j++){
        if([[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lat"] doubleValue] > temp_to_lat){
            temp_to_lat = [[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lat"] doubleValue];
        }
    }
    
    if(temp_from_lat >= temp_to_lat) return temp_from_lat;
    else return temp_to_lat;
}


//緯度の最小値を取得
-(double) getMinLat:(UserLogData *)userlogdata{
    double temp_from_lat = [[[userlogdata.stations objectAtIndex:0] 
                             objectForKey:@"from_lat"] doubleValue];
    
    double temp_to_lat = [[[userlogdata.stations objectAtIndex:0] 
                           objectForKey:@"to_lat"] doubleValue];
    
    for(int i=0; i<[[userlogdata stations] count]; i++){
        if([[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue] < temp_from_lat){
            temp_from_lat = [[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue];
        }
    }
    
    for(int j=0;j<[[userlogdata stations] count]; j++){
        if([[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lat"] doubleValue] < temp_to_lat){
            temp_to_lat = [[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lat"] doubleValue];
        }
    }
    
    if(temp_from_lat <= temp_to_lat) return temp_from_lat;
    else return temp_to_lat;

    
}

//経度の最大値を取得
-(double) getMaxLon:(UserLogData *)userlogdata{
    double temp_from_lon = [[[userlogdata.stations objectAtIndex:0] 
                        objectForKey:@"from_lon"] doubleValue];
    double temp_to_lon = [[[userlogdata.stations objectAtIndex:0] 
                      objectForKey:@"to_lon"] doubleValue];
    
    for(int i=0; i<[[userlogdata stations] count]; i++){
        if([[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue] > temp_from_lon){
            temp_from_lon = [[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue];
        }
    }
    for(int j=0;j<[[userlogdata stations] count]; j++){
        if([[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lon"] doubleValue] > temp_to_lon){
            temp_to_lon = [[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lon"] doubleValue];
        }
    }
    
    if(temp_from_lon >= temp_to_lon) return temp_from_lon;
    else return temp_to_lon;
    
    
}

//経度の最小値を取得
-(double) getMinLon:(UserLogData *)userlogdata{
    double temp_from_lon = [[[userlogdata.stations objectAtIndex:0] 
                            objectForKey:@"from_lon"] doubleValue];
    double temp_to_lon = [[[userlogdata.stations objectAtIndex:0] 
                           objectForKey:@"to_lon"] doubleValue];
    
    for(int i=0; i<[[userlogdata stations] count]; i++){
        if([[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue] < temp_from_lon){
            temp_from_lon = [[[userlogdata.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue];
        }
    }
    for(int j=0;j<[[userlogdata stations] count]; j++){
        if([[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lon"] doubleValue] < temp_to_lon){
            temp_to_lon = [[[userlogdata.stations objectAtIndex:j] objectForKey:@"to_lon"] doubleValue];
        }
    }
    
    if(temp_from_lon <= temp_to_lon) return temp_from_lon;
    else return temp_to_lon;
}






@end
