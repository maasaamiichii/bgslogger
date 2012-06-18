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


@interface MapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate> {
    CLLocationManager *locationManager;
}
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;

-(void) onResume;
-(void) onPause;


@end
