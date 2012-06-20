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

@protocol MapViewControllerDelegate;

@interface MapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate> {
    CLLocationManager *locationManager;
    MKMapView *mapView;
    
    id<MapViewControllerDelegate> delegate;
    
            
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (retain, nonatomic) id<MapViewControllerDelegate> delegate;
- (IBAction)nextPlace:(id)sender;


-(void) onResume;
-(void) onPause;

@end

@protocol MapViewControllerDelegate <NSObject>

-(void)setStationName:(NSString *)stationName;

@end

