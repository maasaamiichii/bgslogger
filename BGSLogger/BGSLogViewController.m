//
//  BGSLogViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/18.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "BGSLogViewController.h"

@interface BGSLogViewController ()

@end


@implementation BGSLogViewController
@synthesize currentRecordingTimeLabel;
@synthesize timer;

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
    
    //録音先のパスを決定する
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [filePaths objectAtIndex:0];
    NSString *path = [documentDir stringByAppendingPathComponent:@"recording.caf"];
    NSURL *recordingURL = [NSURL fileURLWithPath:path];
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
   //[myRecorder prepareToRecord];
    
    //playerを用意する
    NSError *playError = nil;
    myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordingURL error: &playError];
    
    if( playError ){
        NSLog(@"playError = %@",playError);
        return;
    }
    myPlayer.delegate = self;
    
}

- (void)viewDidUnload
{
    [self setCurrentRecordingTimeLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) dealloc{
    [currentRecordingTimeLabel release];
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
        [myRecorder prepareToRecord];
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
    
}


//再生スタートボタン
- (IBAction)startPlay:(id)sender {
    if(!myPlayer.isPlaying && !myRecorder.recording){
        NSLog(@"play start");
        [myPlayer play];
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
        [myPlayer stop];
        myPlayer.currentTime = 0;
        [myPlayer prepareToPlay];
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
   
}





@end
