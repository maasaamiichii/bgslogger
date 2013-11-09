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
#import <MessageUI/MessageUI.h>
#import "FMDB/FMDatabase.h"
#import "FMDB/FMDatabaseAdditions.h"

@interface MapViewController ()

@end



@implementation MapViewController
@synthesize mapView;
@synthesize locationManager;
@synthesize timer;
@synthesize accessoryBtn;

static const NSInteger kTagAlert1 = 1; //録音開始アラート
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
        
    //locationManager初期化
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    //mapviewのデリゲート設定、現在地表示設定
    [mapView setDelegate: self];
    mapView.showsUserLocation = YES;
    [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    mapView.mapType = MKMapTypeSatellite;

    //ナビゲーションバーのタイトルをセット
    self.navigationItem.title = @"BGSLogger";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0. green:0.7 blue:1.0 alpha:1.0]];
    
    
    //アノテーションのアクセサリーボタンの画像を初期化
    accessoryBtn = [[UIButton alloc] 
                     initWithFrame:CGRectMake(0, 0, 30, 30)];  // ボタンのサイズを指定する
    
}


- (void) viewWillAppear:(BOOL)animated{
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

    
    //ユーザ位置をリロード
    [self reloadUserLocation];

}


- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (void)dealloc {
    [mapView release];
    [locationManager release];
    [myRecorder release];
    [timer release];
    //[appSettingsViewController release];
    //appSettingsViewController = nil; 
    [accessoryBtn release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	//self.appSettingsViewController = nil;
}

-(void)beginInterruption{
    [myRecorder pause];
}

-(void)endInterruption{
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [myRecorder record];
}



// 位置情報更新時に呼ばれるデリゲートメソッド
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    //データを格納するシングルトンの作成
    LocationData *locationData = [LocationData sharedCenter];
    
    //ユーザの緯度経度をセット
    [locationData setCurrent_lat:[newLocation coordinate].latitude];
    [locationData setCurrent_lon:[newLocation coordinate].longitude];

    
    //mapviewの表示設定
    MKCoordinateRegion region = MKCoordinateRegionMake([newLocation coordinate], MKCoordinateSpanMake(0.02, 0.02));
    [mapView setCenterCoordinate:[newLocation coordinate]];
    [mapView setRegion:region];
    
    //現在地の近くの駅を取得
    [self getNearStationsFromDB:newLocation];
    
        
    //更新をやめる
    [locationManager stopUpdatingLocation];
    
    //現在地の住所を取得
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation: locationManager.location completionHandler: 
     ^(NSArray *placemarks, NSError *error) {
         
         //Get nearby address
         CLPlacemark *placemark = [placemarks objectAtIndex:0];
         
         //String to hold address
         NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
         [locationData setCurrent_name:locatedAt];
     }];
    
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation 
{
    MKAnnotationView* annotationView = [self.mapView viewForAnnotation:userLocation];
    
    //UIImageを指定した生成例
    UIImage *image = [[UIImage alloc] init];
    
    if(!myRecorder.isRecording){
        image = [UIImage imageNamed:@"rec.png"];
    }
    else if(myRecorder.isRecording){
        image = [UIImage imageNamed:@"stop.png"];
    }

    [accessoryBtn setBackgroundImage:image forState:UIControlStateNormal];  // 画像をセットする
    annotationView.rightCalloutAccessoryView = accessoryBtn;
    
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
        MKUserLocation *user_annotation = self.mapView.userLocation;
        user_annotation.title = @"現在地";
        
        //現在地の住所を取得
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation: locationManager.location completionHandler: 
         ^(NSArray *placemarks, NSError *error) {
             
             //Get nearby address
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             
             //String to hold address
             NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
             user_annotation.subtitle = locatedAt;
         }];
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
        
            //rec.pngをアクセサリーボタンの画像にセット
            UIImage *image = [[UIImage alloc] init];
            if(!myRecorder.isRecording){
                image = [UIImage imageNamed:@"rec.png"];
            }
            else if(myRecorder.isRecording){
                image = [UIImage imageNamed:@"stop.png"];
            }
            [accessoryBtn setBackgroundImage:image forState:UIControlStateNormal];  // 画像をセットする
            pav.rightCalloutAccessoryView = accessoryBtn;
        }
        return pav;
    }
    
}



//アノテーションのアクセサリーボタンをタップしたときに呼ばれるデリゲートメソッド
- (void) mapView:(MKMapView*)_mapView annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control { 

    //アカウント名が入力されていない場合、リターン
    LocationData *locationData = [LocationData sharedCenter];
    /*if([locationData.account_name isEqualToString:@""]){
        UIAlertView *nonaccountalert = [[UIAlertView alloc] initWithTitle:nil message:@"設定画面でアカウント名を入力してください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        nonaccountalert.tag = kTagAlert4;
        [nonaccountalert show];
        [nonaccountalert release];
        return;
    }*/
    
    
    
    
    //録音中でないとき、レコーダを生成する
    if(myRecorder == nil && !myRecorder.isRecording){
        
        //日付を取得
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat  = @"yyyyMMddHHmmss";
        NSString *dateString = [df stringFromDate:[NSDate date]];
        
        //録音先のパスを決定する
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [filePaths objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@.aac",dateString];
        NSString *path = [documentDir stringByAppendingPathComponent:filePath];
        recordingURL = [NSURL fileURLWithPath:path];
        
        //サーバーに送るファイル名をセット
        fileName = [[NSString alloc]initWithString:filePath];
                        
        
        NSError *recordError = nil;
        
        // 録音の設定 AVNumberOfChannelsKey チャンネル数1
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                                  [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                  [NSNumber numberWithUnsignedInt:128000], AVEncoderBitRateKey,
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
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat  = @"yyyy-MM-dd HH:mm:ss";
        NSString *dateString = [df stringFromDate:[NSDate date]];

        [locationData setFrom_lat:annotationView.annotation.coordinate.latitude];
        [locationData setFrom_lon:annotationView.annotation.coordinate.longitude];
        [locationData setFrom_date:dateString];
        
        if(annotationView.annotation == mapView.userLocation)
            [locationData setFrom_name:locationData.current_name];
        else
            [locationData setFrom_name:annotationView.annotation.title];

        
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.delegate = self;
        if(annotationView.annotation == mapView.userLocation)
            alert.title = [NSString stringWithFormat:@"現在地:%@",locationData.current_name];
        else 
        alert.title = [NSString stringWithFormat:@"現在地：%@",annotationView.annotation.title];
        alert.message = @"録音を開始します。";
        [alert addButtonWithTitle:@"いいえ"];
        [alert addButtonWithTitle:@"はい"];
        alert.tag = kTagAlert1;
        [alert show];
    }
    
    //録音中のとき、録音停止確認のアラートビューを表示
    else if(myRecorder.isRecording){
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat  = @"yyyy-MM-dd HH:mm:ss";
        NSString *dateString = [df stringFromDate:[NSDate date]];

        [locationData setTo_lat:annotationView.annotation.coordinate.latitude];
        [locationData setTo_lon:annotationView.annotation.coordinate.longitude];
        [locationData setTo_date:dateString];
        
        if(annotationView.annotation == mapView.userLocation)
            [locationData setTo_name:locationData.current_name];
        else
            [locationData setTo_name:annotationView.annotation.title];
        
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.delegate = self;
        if(annotationView.annotation == mapView.userLocation)
            alert.title = [NSString stringWithFormat:@"現在地:%@",locationData.current_name];
        else 
            alert.title = [NSString stringWithFormat:@"現在地：%@",annotationView.annotation.title];
        alert.message = @"録音を停止します。";
        [alert addButtonWithTitle:@"いいえ"];
        [alert addButtonWithTitle:@"はい"];
        alert.tag = kTagAlert2;
        [alert show];
    }
    
    
}


// アラートのボタンが押された時に呼ばれるデリゲートメソッド
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //録音開始アラート
    if(kTagAlert1 == alertView.tag){
        switch (buttonIndex) {
            case 0:
                //いいえボタン
                break;
                
            case 1:
                //はいボタン
                //録音スタート
                [myRecorder record];
                
                //アノテーションのアクセサリーボタンの画像をstop.pngに変更
                [accessoryBtn setBackgroundImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
                [self startTimer];
            
                //ステータスバーの色を変える
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
            
                //ナビゲーションバーの色を変える
                [self.navigationController.navigationBar setTintColor:[UIColor redColor]];
                break;
                
            default:
                break;
        }
    }
    //録音停止アラート
    else if(kTagAlert2 == alertView.tag){
        switch (buttonIndex) {
            case 0:
                //いいえボタン
                break;
                
            case 1:
                //録音中のとき、録音ストップ
                [self stopTimer];
                [myRecorder stop];
                [locationManager stopUpdatingLocation];
                self.navigationItem.title = @"BGSLogger";
                
                //ステータスバーの色を変える
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                
                //ナビゲーションバーの色を変える
                [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0. green:0.7 blue:1.0 alpha:1.0]];
                break;
                
            default:
                break;
        }
    }
    //駅取得失敗アラート
    else if(kTagAlert3 == alertView.tag){
        switch (buttonIndex) {
            case 0:
                //いいえボタン
                break;
            case 1:
                //はいボタン
                //リロード
                [self reloadUserLocation];
                break;
                
            default:
                break;
        
        }
    }
    //サーバーポスト成功アラート
    else if(kTagAlert4 == alertView.tag){
        switch (buttonIndex) {
            case 0:
                //OKボタン
                break;
            default:
                break;
                
        }
    }
    //サーバーポスト失敗アラート
    else if(kTagAlert5 == alertView.tag){
        switch (buttonIndex) {
            case 0:
                //OKボタン
                break;
            case 1:
                //サーバーを使うときはコメントアウト
                //[self postUserLocation];
                break;
            default:
                break;
        }
    }

    
}


//現在地、アノテーションのリロードアクション
- (IBAction)reloadUserLocation:(id)sender {
    
    [self reloadUserLocation];
}


//現在地、アノテーションのリロードメソッド
-(void) reloadUserLocation{
    if ([CLLocationManager locationServicesEnabled]) {
        
        // 測位開始
        [locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
    for (id annotation in mapView.annotations) {
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
        int seconds = (int)myRecorder.currentTime % 60;
        int minutes = (int)myRecorder.currentTime / 60;
        self.navigationItem.title = [NSString stringWithFormat:@"録音中:%d:%02d", minutes, seconds];
    }
}


//録音終了時に呼ばれるデリゲートメソッド
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    myRecorder = nil;
    [self stopTimer];
    
    //アノテーションのアクセサリーボタンの画像をrec.pngに変更
    [accessoryBtn setBackgroundImage:[UIImage imageNamed:@"rec.png"] forState:UIControlStateNormal];
    
    
    //サーバーを使うときはコメントアウト
    //[self postUserLocation];
    
    //DBに入力
    [self insertDB];
    
}

-(void) getNearStationsFromDB:(CLLocation*) location{
    FMDatabase* db  = [self dbConnect];
    
    NSString  *low_lat = [NSString stringWithFormat:@"%f",location.coordinate.latitude - 0.01] ;
    NSString  *high_lat = [NSString stringWithFormat:@"%f",location.coordinate.latitude + 0.01] ;
    NSString  *low_lon = [NSString stringWithFormat:@"%f",location.coordinate.longitude - 0.01] ;
    NSString  *high_lon = [NSString stringWithFormat:@"%f",location.coordinate.longitude + 0.01] ;
    
    
    if ([db open]) {
        [db setShouldCacheStatements:YES];
        
        // SELECT
        NSString *sql = @"SELECT station_name, GROUP_CONCAT(line_name) as line_name, lat, lon FROM station WHERE lat between ? and ? and lon between ? and ? group by station_name";
        FMResultSet *rs = [db executeQuery:sql, low_lat, high_lat, low_lon, high_lon];
        
        //データを格納するシングルトン
        LocationData *locationData = [LocationData sharedCenter];
        locationData.nearStations = [[[NSMutableArray alloc]init] autorelease];
        
        while ([rs next]) {
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setObject:[rs stringForColumn:@"station_name"] forKey:@"station_name"];
            [dic setObject:[rs stringForColumn:@"line_name"] forKey:@"line_name"];
            [dic setObject:[rs stringForColumn:@"lat"] forKey:@"lat"];
            [dic setObject:[rs stringForColumn:@"lon"] forKey:@"lon"];
            
            [locationData.nearStations addObject:dic];
            
        }
        [rs close];
        [db close];
        
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
        
        
    }else{
        NSLog(@"Could not open db.");
    }

        
}


//DBへ接続する
-(id) dbConnect{
    BOOL success;
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"BGSLogger.db"];
    NSLog(@"%@",writableDBPath);
    success = [fm fileExistsAtPath:writableDBPath];
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BGSLogger.db"];
        success = [fm copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        if(!success){
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
    FMDatabase* db = [FMDatabase databaseWithPath:writableDBPath];
    return db;
    
}


//DBへ入力
-(void)insertDB{

    LocationData *locationData = [LocationData sharedCenter];
    
    FMDatabase* db  = [self dbConnect];
    NSString*   sql = @"INSERT INTO record_information (from_lat,from_lon,to_lat,to_lon,from_name,to_name,from_date,to_date,file_name,date) VALUES (?,?,?,?,?,?,?,?,?,?)";
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd HH:mm:ss";
    NSString *str = [df stringFromDate:[NSDate date]];
    [db open];
    [db executeUpdate:sql, [NSString stringWithFormat:@"%f", locationData.from_lat],[NSString stringWithFormat:@"%f", locationData.from_lon],[NSString stringWithFormat:@"%f", locationData.to_lat],[NSString stringWithFormat:@"%f", locationData.to_lon],locationData.from_name,locationData.to_name,locationData.from_date,locationData.to_date,fileName,str];
    [db close];
}



@end
