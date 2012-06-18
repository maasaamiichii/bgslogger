//
//  MapViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "MapViewController.h"
#import "MapDetailViewController.h"
#import "CustomAnnotation.h"

@interface MapViewController ()

@end

@implementation MapViewController
@synthesize mapView;
@synthesize locationManager;

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
    
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.685623,139.763153)
                                                    title:@"大手町駅"
                                                 subtitle:@"千代田線・半蔵門線・丸ノ内線・東西線・三田線"]autorelease]];
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.690747,139.756866)
                                                    title:@"竹橋駅"
                                                 subtitle:@"東西線"]autorelease]];
    [mapView addAnnotation:
     [[[CustomAnnotation alloc]initWithLocationCoordinate:CLLocationCoordinate2DMake(35.681666,139.764869)
                                                    title:@"東京駅"
                                                 subtitle:@"いっぱい"]autorelease]];
}


-(void)viewWillAppear:(BOOL)animated
{
    //navigationbarを隠す
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
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

// 位置情報更新時
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    //緯度・経度を出力
    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f",
          [newLocation coordinate].latitude,
          [newLocation coordinate].longitude);
    
    //mapviewの表示設定
    MKCoordinateRegion region = MKCoordinateRegionMake([newLocation coordinate], MKCoordinateSpanMake(0.05, 0.05));
    [mapView setCenterCoordinate:[newLocation coordinate]];
    [mapView setRegion:region];
    
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
    //画面遷移
    MapDetailViewController *mapDetailView = [self.storyboard instantiateViewControllerWithIdentifier:@"mapDetail"];
    [self.navigationController pushViewController:mapDetailView animated:YES];
    
}







@end
