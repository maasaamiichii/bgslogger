//
//  LogMapViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "LogMapViewController.h"
#import "CustomAnnotation.h"
#import "ASIFormDataRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "UserLogData.h"

@interface LogMapViewController ()

@end

@implementation LogMapViewController
@synthesize logMapView;

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
    
    //mapviewのデリゲート設定、現在地表示設定
    [logMapView setDelegate: self];
    logMapView.showsUserLocation = YES;
    
    logMapView.mapType = MKMapTypeSatellite;

    //ナビゲーションバーのタイトルをセット
    self.navigationItem.title = @"BGSLogViewer";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1.0 green:0.7 blue:0.0 alpha:1.0]];
    
    /*[logMapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.765172,139.7359333)
                                                    title:@"王子神谷駅"
                                                 subtitle:@"南北線"]autorelease]];
    [logMapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.717633, 139.758025)
                                                    title:@"東大前駅"
                                                 subtitle:@"南北線"]autorelease]];
    [logMapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.6746177, 139.777705)
                                                    title:@"八丁堀駅"
                                                 subtitle:@"京葉線、日比谷線"]autorelease]];
    [logMapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.671989, 139.763965)
                                                    title:@"銀座駅"
                                                 subtitle:@"いっぱい"]autorelease]];
    
    CLLocationCoordinate2D coors[4];
    // 渋谷、原宿、代々木、新宿
    coors[0] = CLLocationCoordinate2DMake(35.765172,139.735933);
    coors[1] = CLLocationCoordinate2DMake(35.717633, 139.758025);
    coors[2] = CLLocationCoordinate2DMake(35.6746177, 139.777705);
    coors[3] = CLLocationCoordinate2DMake(35.671989, 139.763965);*/
    
    
    
    /*MKPolyline *line = [MKPolyline polylineWithCoordinates:coors
                                                     count:4];
    [logMapView addOverlay:line];*/
    
    [self getUserLog];
    

}

- (void)viewDidUnload
{
    [self setLogMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [logMapView release];
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


//アノテーションの設定
-(MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id)annotation{
        
    
    static NSString *PinIdentifier = @"Pin";
    MKPinAnnotationView *pav = (MKPinAnnotationView*) [self.logMapView dequeueReusableAnnotationViewWithIdentifier:PinIdentifier];
        
    if(pav == nil){
        pav = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:PinIdentifier] autorelease];
        pav.animatesDrop = YES;  // アニメーションをする
        pav.pinColor = MKPinAnnotationColorRed;  // ピンの色を赤にする
        pav.canShowCallout = YES;  // ピンタップ時にコールアウトを表示する
            
        /*//UIImageを指定した生成例
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
        pav.rightCalloutAccessoryView = accessoryBtn;*/
        }
    return pav;
    
}

//アノテーションが選択された時に呼ばれるデリゲートメソッド
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
}


//アノテーションが選択解除された時に呼ばれるデリゲートメソッド
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    

}



//アノテーションのアクセサリーボタンをタップしたときに呼ばれるデリゲートメソッド
- (void) mapView:(MKMapView*)_mapView annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control { 
    
    
}

-(void)getUserLog{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/SetLog.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
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
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:3] forKey:@"to_lat"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:4] forKey:@"to_lon"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:5] forKey:@"to_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:6] forKey:@"file_name"];
        [dict[i] setObject:[[[gotStations objectAtIndex:i] componentsSeparatedByString:@","] objectAtIndex:7] forKey:@"date"];
        [userLogData.stations addObject:dict[i]];
    }
    
    NSLog(@"%@",[userLogData.stations description]);
    
    NSLog(@"getUserLogSucceeded");
    
    
    //取得した駅のアノテーションを追加
    for(int i = 0; i < [userLogData.stations count]; i++){
        [logMapView addAnnotation:
         [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake
           ([[[userLogData.stations objectAtIndex:i] objectForKey:@"from_lat"] doubleValue],
            [[[userLogData.stations objectAtIndex:i] objectForKey:@"from_lon"] doubleValue])
                                                        title:[[userLogData.stations objectAtIndex:i] objectForKey:@"from_name"]
                                                     subtitle:@""]
           autorelease]];
        [logMapView addAnnotation:
         [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake
           ([[[userLogData.stations objectAtIndex:i] objectForKey:@"to_lat"] doubleValue],
            [[[userLogData.stations objectAtIndex:i] objectForKey:@"to_lon"] doubleValue])
                                                        title:[[userLogData.stations objectAtIndex:i] objectForKey:@"to_name"]
                                                     subtitle:@""]
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *notgetalert = [[UIAlertView alloc] initWithTitle:nil message:@"取得できませんでした。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    [notgetalert show];
    [notgetalert release];
    NSString *resString = [request responseString];
    NSLog(@"%@", resString);
    NSLog(@"getUserLogFailed");
}


@end
