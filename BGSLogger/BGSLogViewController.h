//
//  BGSLogViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>


@interface BGSLogViewController : UIViewController<AVAudioRecorderDelegate,AVAudioPlayerDelegate>{
    
    AVAudioRecorder *myRecorder;
    AVAudioPlayer *myPlayer;
    NSTimer *timer;
    
}

@property (retain, nonatomic) IBOutlet UILabel *currentRecordingTimeLabel;
@property (retain, nonatomic) NSTimer *timer;

- (IBAction)startRecord:(id)sender;
- (IBAction)startPlay:(id)sender;
- (IBAction)stopRecord:(id)sender;
- (IBAction)pausePlay:(id)sender;
- (IBAction)stopPlay:(id)sender;

- (void) startTimer;
- (void) stopTimer;
- (void) displayCurrentRecordingTime;

@end
