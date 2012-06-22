//
//  LogMapViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface LogMapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate,UIAlertViewDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate>{
    
}

@property (retain, nonatomic) IBOutlet MKMapView *logMapView;

-(void)getUserLog;


@end
