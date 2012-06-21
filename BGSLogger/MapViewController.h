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
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>


@interface MapViewController : UIViewController<CLLocationManagerDelegate,MKMapViewDelegate,UIAlertViewDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate> {
    CLLocationManager *locationManager;
    MKMapView *mapView;
    
    AVAudioRecorder *myRecorder;
    AVAudioPlayer *myPlayer;
    NSTimer *timer;
    NSURL *recordingURL;
    UIButton *accessoryBtn;
            
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)nextPlace:(id)sender;


-(void) onResume;
-(void) onPause;
- (void) startTimer;
- (void) stopTimer;
- (void) displayCurrentRecordingTime;

@end



