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
#import <MessageUI/MessageUI.h>
#import "IASKSpecifier.h"
#import "IASKSettingsReader.h"
#import "SVProgressHUD.h"


@interface MapViewController ()

@end



@implementation MapViewController
@synthesize mapView;
@synthesize locationManager;
@synthesize timer;
@synthesize appSettingsViewController;
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
    
    
    //アカウント名取得
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    //[userDefaults removeObjectForKey:@"AccountName"];
    //[userDefaults synchronize];

    LocationData *locationData = [LocationData sharedCenter];
    locationData.account_name = [NSString stringWithFormat:@"%@",[userDefaults stringForKey: @"AccountName"]];
    
        
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
    [appSettingsViewController release];
	appSettingsViewController = nil; 
    [accessoryBtn release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	self.appSettingsViewController = nil;
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
    [self getNearStations:newLocation];
    
        
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
    UIImage *image;
    
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
            UIImage *image;
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
    if([locationData.account_name isEqualToString:@""]){
        UIAlertView *nonaccountalert = [[UIAlertView alloc] initWithTitle:nil message:@"設定画面でアカウント名を入力してください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        nonaccountalert.tag = kTagAlert4;
        [nonaccountalert show];
        [nonaccountalert release];
        return;
    }
    
    
    
    
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
                [self postUserLocation];
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
        self.navigationItem.title = [NSString stringWithFormat:@"録音中:%f",myRecorder.currentTime];
    }
}


//録音終了時に呼ばれるデリゲートメソッド
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    myRecorder = nil;
    [self stopTimer];
    
    //アノテーションのアクセサリーボタンの画像をrec.pngに変更
    [accessoryBtn setBackgroundImage:[UIImage imageNamed:@"rec.png"] forState:UIControlStateNormal];
    [self postUserLocation];
    
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
    [SVProgressHUD showWithStatus:@"近くの駅を取得しています。"];
    
}



//リクエスト成功時
- (void)stationGetSucceeded:(ASIFormDataRequest*)request
{
    [SVProgressHUD dismiss];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    //帰ってきた文字列
    NSString *resString = [request responseString];
    
    //データを格納するシングルトン
    LocationData *locationData = [LocationData sharedCenter];
    locationData.nearStations = [[[NSMutableArray alloc]init] autorelease];
    
    //帰ってきたデータを';'でセパレート、アレイに格納
    NSMutableArray*gotStations = (NSMutableArray*)[resString componentsSeparatedByString:@";"];
    
    NSMutableDictionary *dict[[gotStations count]-1];
    
    //各データをkeyごとにディクショナリに追加
    for(int i = 0; i < [gotStations count] - 1; i++){
        dict[i] = [[[NSMutableDictionary alloc]init ]autorelease];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@"_"] objectAtIndex:0] forKey:@"station_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@"_"] objectAtIndex:1] forKey:@"line_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@"_"] objectAtIndex:2] forKey:@"lat"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@"_"] objectAtIndex:3] forKey:@"lon"];
        [locationData.nearStations addObject:dict[i]];
    }    
    
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
    [SVProgressHUD dismiss];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:@"取得できませんでした。" message:@"もう一度取得しますか？" delegate:nil cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
    notgetalert.tag = kTagAlert3;
    [notgetalert show];
    [notgetalert release];
    NSLog(@"stationgetfailed");
}



//ユーザの位置情報、録音情報を送信
-(void)postUserLocation{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    LocationData *locationData = [LocationData sharedCenter];
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/InsertRecordInformation.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
    [request setPostValue:[NSString stringWithFormat:@"%f", locationData.from_lat] forKey:@"from_lat"];
    [request setPostValue:[NSString stringWithFormat:@"%f", locationData.from_lon] forKey:@"from_lon"];
    [request setPostValue:[NSString stringWithFormat:@"%f", locationData.to_lat] forKey:@"to_lat"];
    [request setPostValue:[NSString stringWithFormat:@"%f", locationData.to_lon] forKey:@"to_lon"];
    [request setPostValue:locationData.from_name forKey:@"from_name"];
    [request setPostValue:locationData.to_name forKey:@"to_name"];
    [request setPostValue:locationData.from_date forKey:@"from_date"];
    [request setPostValue:locationData.to_date forKey:@"to_date"];
    [request setPostValue:fileName forKey:@"file_name"];
    [request setPostValue:locationData.account_name forKey:@"account_name"];
    
    [request setTimeOutSeconds:30];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(postUserLocationSucceeded:)];
    [request setDidFailSelector:@selector(postUserLocationFailed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
    [SVProgressHUD showWithStatus:@"サーバにアップロード中..."];
}


//リクエスト成功時
- (void)postUserLocationSucceeded:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    UIAlertView *postdidalert = [[UIAlertView alloc] initWithTitle:nil message:@"アップロード成功" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    postdidalert.tag = kTagAlert4;
    [postdidalert show];
    [postdidalert release];
    NSLog(@"postUserLocationSuceeded");
    
}

//リクエスト失敗時
- (void)postUserLocationFailed:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    UIAlertView *postfailedalert = [[UIAlertView alloc] initWithTitle:@"サーバーへのアップロードに失敗しました。" message:@"もう一度アップロードに挑戦しますか？" delegate:nil cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
    postfailedalert.tag = kTagAlert5;
    
    [postfailedalert show];
    [postfailedalert release];
    NSLog(@"postUserLocationFailed");
}



//セッティングビューの設定
- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
		appSettingsViewController.delegate = self;
	}
	return appSettingsViewController;
}


//セッティングビューの表示
- (IBAction)showSettingView:(id)sender {
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
    //[viewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
    // But we encourage you not to uncomment. Thank you!
    self.appSettingsViewController.showDoneButton = YES;
    [self presentModalViewController:aNavController animated:YES];
    [aNavController release];
}


//セッティングビューを閉じたとき
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissModalViewControllerAnimated:YES];
    LocationData *locationData = [LocationData sharedCenter];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    locationData.account_name = [NSString stringWithFormat:@"%@",[userDefaults stringForKey: @"AccountName"]];
}


@end
