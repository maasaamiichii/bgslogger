//
//  BGSLogViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "BGSLogViewController.h"
#import "LocationData.h"
#import "MapViewController.h"



@interface BGSLogViewController()<MapViewControllerDelegate>


@end


@implementation BGSLogViewController
@synthesize currentRecordingTimeLabel;
@synthesize userLatitudeLabel;
@synthesize userLongitudeLabel;
@synthesize timer;
@synthesize stationNameLabel;


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
    //NSLog(@"%@",stationNameLabel.text);
    
    //MapViewController *mapViewController = [[MapViewController alloc] init];
    //mapViewController.delegate = self;
   
   
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    // 使用している機種が録音に対応しているか
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
    //録音先のパスを決定する
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [filePaths objectAtIndex:0];
    NSString *path = [documentDir stringByAppendingPathComponent:@"recording.caf"];
    recordingURL = [NSURL fileURLWithPath:path];
    NSLog(@"%@",recordingURL);
    NSError *recordError = nil;
    
    // 録音の設定 AVNumberOfChannelsKey チャンネル数1
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                              [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                              nil];
    
    //recorderを用意する
    myRecorder = [[AVAudioRecorder alloc] initWithURL:recordingURL settings:settings error: &recordError];
    
    if( recordError ){
        NSLog(@"recordError = %@",recordError);
        return;
    }
    
    myRecorder.delegate = self;
    
    
    LocationData *locationData = [LocationData sharedCenter];
    stationNameLabel.text = [NSString stringWithFormat:@"%@",[locationData getFromStationName]];
    
   
    
}

- (void)viewDidUnload
{
    [self setCurrentRecordingTimeLabel:nil];
    [self setUserLatitudeLabel:nil];
    [self setUserLongitudeLabel:nil];
    [self setStationNameLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated{
    LocationData *locationData = [LocationData sharedCenter];
    userLatitudeLabel.text = [NSString stringWithFormat:@"%f",[locationData getUserLatitude]];
    userLongitudeLabel.text = [NSString stringWithFormat:@"%f",[locationData getUserLongitude]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc{
    [currentRecordingTimeLabel release];
    [userLatitudeLabel release];
    [userLongitudeLabel release];
    [stationNameLabel release];
    [super dealloc];
    [myRecorder release];
    [myPlayer release];
    [timer release];
}


//録音スタートボタン
- (IBAction)startRecord:(id)sender {
    if(!myRecorder.recording && !myPlayer.isPlaying){
         NSLog(@"record start");
        [myRecorder record];
        [self startTimer];
        
    }
}

//録音停止ボタン
- (IBAction)stopRecord:(id)sender {
    if(myRecorder.recording && !myPlayer.isPlaying){
        [self stopTimer];
        [myRecorder stop];
    }
}


-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0
                                                  target:self
                                                selector:@selector(displayCurrentRecordingTime)
                                                userInfo:nil
                                                 repeats:YES];
}

-(void)stopTimer{
    if(self.timer){
        [self.timer invalidate];
    }
}

- (void) displayCurrentRecordingTime{
    if(myRecorder && myRecorder.recording){
        currentRecordingTimeLabel.text = [NSString stringWithFormat:@"%f",myRecorder.currentTime];
    }
    else if(myPlayer && myPlayer.isPlaying){
        currentRecordingTimeLabel.text = [NSString stringWithFormat:@"%f",myPlayer.currentTime];
    }
    
}


//再生スタートボタン
- (IBAction)startPlay:(id)sender {
    
    if(myPlayer == nil){
        //playerを用意
        NSError *playError = nil;
        myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordingURL error: &playError];
    
        if( playError ){
            NSLog(@"playError = %@",playError);
            return;
        }
        myPlayer.delegate = self;
    }
    
    if(!myPlayer.isPlaying && !myRecorder.recording){
        NSLog(@"play start");
        [myPlayer play];
        [self startTimer];
    }
}

//一時停止ボタン
- (IBAction)pausePlay:(id)sender {
    if(myPlayer.isPlaying && !myRecorder.recording){
        NSLog(@"play pause");
        [myPlayer pause];
    }
}

//再生停止ボタン
- (IBAction)stopPlay:(id)sender {
    if(myPlayer.isPlaying && !myRecorder.recording){ 
        NSLog(@"play stop");
        [myPlayer stop];
        [self stopTimer];
        myPlayer.currentTime = 0;
        myPlayer = nil;
    }
}




//録音終了時に呼ばれるデリゲートメソッド
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"record stop");
    [self stopTimer];
}

//再生終了時に呼ばれるデリゲートメソッド
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"play stop");
    [self stopTimer];
    myPlayer = nil;
}

/*- (void) setStationName:(NSString *)stationName{
    NSLog(@"delegatecalled");
    stationNameLabel.text = [NSString stringWithFormat:@"%@",stationName];
}*/


@end
