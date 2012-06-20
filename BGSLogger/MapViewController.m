//
//  MapViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "MapViewController.h"
#import "BGSLogViewController.h"
#import "CustomAnnotation.h"
#import "LocationData.h"


@interface MapViewController ()

@end



@implementation MapViewController
@synthesize mapView;
@synthesize locationManager;
@synthesize delegate;


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
	// Do any additional setup after loading the view.
    
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

    
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.765172,139.7359333)
                                                    title:@"王子神谷駅"
                                                 subtitle:@"南北線"]autorelease]];
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.717633, 139.758025)
                                                    title:@"東大前駅"
                                                 subtitle:@"南北線"]autorelease]];
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.6746177, 139.777705)
                                                    title:@"八丁堀駅"
                                                 subtitle:@"京葉線、日比谷線"]autorelease]];
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.671989, 139.763965)
                                                    title:@"銀座駅"
                                                 subtitle:@"いっぱい"]autorelease]];
    
    CLLocationCoordinate2D coors[4];
    // 渋谷、原宿、代々木、新宿
    coors[0] = CLLocationCoordinate2DMake(35.765172,139.735933);
    coors[1] = CLLocationCoordinate2DMake(35.717633, 139.758025);
    coors[2] = CLLocationCoordinate2DMake(35.6746177, 139.777705);
    coors[3] = CLLocationCoordinate2DMake(35.671989, 139.763965);
    
    MKPolyline *line = [MKPolyline polylineWithCoordinates:coors
                                                     count:4];
    [mapView addOverlay:line];
    

}


-(void)viewWillAppear:(BOOL)animated
{
    //navigationbarを隠す
    //[self.navigationController setNavigationBarHidden:YES animated:NO];
    
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
    [super dealloc];
}


- (MKOverlayView *)mapView:(MKMapView *)mapView
            viewForOverlay:(id<MKOverlay>)overlay {
    MKPolylineView *view = [[[MKPolylineView alloc] initWithOverlay:overlay]
                            autorelease];
    view.strokeColor = [UIColor blueColor];
    view.lineWidth = 5.0;
    return view;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    
}

// 位置情報更新時
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
    
    //更新をやめる
    //[locationManager stopUpdatingLocation];
}

// 測位失敗時や、5位置情報の利用をユーザーが「不許可」とした場合などに呼ばれる
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError");
}

//測位機能オン
int i =0;
- (IBAction)nextPlace:(id)sender {
    //mapviewの表示設定
    CLLocationCoordinate2D coors[4];
    // 渋谷、原宿、代々木、新宿
    coors[0] = CLLocationCoordinate2DMake(35.765172,139.735933);
    coors[1] = CLLocationCoordinate2DMake(35.717633, 139.758025);
    coors[2] = CLLocationCoordinate2DMake(35.6746177, 139.777705);
    coors[3] = CLLocationCoordinate2DMake(35.671989, 139.763965);
    MKCoordinateRegion region;
    switch (i) {
        case 0:
            region = MKCoordinateRegionMake(coors[i], MKCoordinateSpanMake(0.01,0.01));
            [mapView setCenterCoordinate:coors[i] animated:YES];
            [mapView setRegion:region animated:YES];
            i++;
            break;
        case 1:
            region = MKCoordinateRegionMake(coors[i], MKCoordinateSpanMake(0.03,0.03));
            [mapView setCenterCoordinate:coors[i] animated:YES];
            [mapView setRegion:region animated:YES];
            i++;
            break;
        case 2:
            region = MKCoordinateRegionMake(coors[i], MKCoordinateSpanMake(0.07,0.07));
            [mapView setCenterCoordinate:coors[i] animated:YES];
            [mapView setRegion:region animated:YES];
            i++;
            break;
        case 3:
            region = MKCoordinateRegionMake(coors[i], MKCoordinateSpanMake(0.1,0.1));
            [mapView setCenterCoordinate:coors[i] animated:YES];
            [mapView setRegion:region animated:YES];
            i=0;
            break;
        default:
            break;
    }
    
}

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
            pav.animatesDrop = NO;  // アニメーションをする
            pav.pinColor = MKPinAnnotationColorRed;  // ピンの色を赤にする
            pav.canShowCallout = YES;  // ピンタップ時にコールアウトを表示する
        
            //UIImageを指定した生成例
            //UIImage *image = [UIImage imageNamed:@"Yuna_FFX_01.jpg"];
            //UIImageView *iv = [[UIImageView alloc] initWithImage:image];
            pav.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        return pav;
    }
    
}

//ボタンをタップしたときの処理
- (void) mapView:(MKMapView*)_mapView annotationView:(MKAnnotationView*)annotationView calloutAccessoryControlTapped:(UIControl*)control { 
    
    NSLog(@"annotationView annotation is %@", annotationView.annotation); 
    NSLog(@"annotationView title is %@", annotationView.annotation.title); // アノテーションバルーンのtitle
    NSLog(@" annotationView subtitle is %@", annotationView.annotation.subtitle); // アノテーションバルーンのsubtitle
      
    /*if(self.delegate != nil && [delegate respondsToSelector:@selector(setStationName:)]){
        [delegate setStationName:annotationView.annotation.title];
    }*/
    
    LocationData *locationData = [LocationData sharedCenter];
    [locationData setFromStationName:annotationView.annotation.title];
    
    //画面遷移
    BGSLogViewController *bgsLogView = [self.storyboard instantiateViewControllerWithIdentifier:@"bgsLogView"];
    [self.navigationController pushViewController:bgsLogView animated:YES];
    
}






@end
