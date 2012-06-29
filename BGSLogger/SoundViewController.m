//
//  SoundViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/30.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "SoundViewController.h"
#import "UserLogData.h"
#import "ASIFormDataRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "SVProgressHUD.h"

@interface SoundViewController ()

@end

@implementation SoundViewController
@synthesize soundTable;
@synthesize playTimer;
@synthesize sl;

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
    
    // navigation Barの右側に[Edit]ボタンを表示する。
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAlert)] autorelease];
    
    
    
    soundTable.delegate = self;
    soundTable.dataSource = self;
    
    UserLogData *userLogData = [UserLogData sharedCenter];
    if([userLogData.stations count] == 0){
        UIAlertView *nonalert = [[UIAlertView alloc] initWithTitle:nil message:@"LogViewerでログデータをロードしてください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [nonalert show];
        [nonalert release];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    // 使用している機種が録音に対応しているか
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }
    // 録音機能をアクティブにする
    [audioSession setActive:YES error:&error];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }

    [soundTable reloadData];
}

- (void)viewDidUnload
{
    [self setSoundTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (void)dealloc {
    [soundTable release];
    [playTimer release];
    [sl release];
    [super dealloc];
}


//セクションの数
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//セクションに含まれるセルの数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    UserLogData *userLogData = [UserLogData sharedCenter];
    return [userLogData.stations count];
}

//セクションヘッダーのタイトル
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"録音ファイル一覧";
}


//セルの高さ
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

//セルの内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    UserLogData *userLogData = [UserLogData sharedCenter];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 8;
    
    if(indexPath.section == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@\n%@から%@への移動", 
                               [[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"file_name"],
                               [[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"from_name"],
                               [[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"to_name"]];
    }
    return cell;
}


//セルタップ時に呼ばれる
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    
    UserLogData *userLogData = [UserLogData sharedCenter];
    
    NSLog(@"%d",soundTable.indexPathForSelectedRow.row);
    
    //再生先のパスを決定する
    NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [filePaths objectAtIndex:0];
    NSString *path = [documentDir stringByAppendingPathComponent:[[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"file_name"]];
    playURL = [NSURL fileURLWithPath:path];
    
    
    //playerを用意
    NSError *playError = nil;
    myPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:playURL error: &playError];
    
    if( playError ){
        NSLog(@"playError = %@",playError);
        return;
    }
    myPlayer.delegate = self;
    [myPlayer play];
    [self startTimer];

    actionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n" delegate:self cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    //現在の向きを取得
    UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if( orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft ){
        //スライダーを追加
        sl = [[UISlider alloc] initWithFrame:CGRectMake(60, 20, 350, 10)];
    }
    else{
        //スライダーを追加
        sl = [[UISlider alloc] initWithFrame:CGRectMake(60.0f, 20.0f, 200.0f, 10.0f)];
    }
    
    sl.minimumValue = 0.0;  // 最小値を0に設定
    sl.maximumValue = myPlayer.duration;  // 最大値をファイルの長さに設定
    sl.value = 0.0; //初期値を0にセット
    
    int seconds = (int)myPlayer.duration % 60;
    int minutes = (int)myPlayer.duration / 60;

    
    //値が変更されたときに呼ばれるメソッドを設定
    [sl addTarget:self action:@selector(setCurrentPlayTime) forControlEvents:UIControlEventValueChanged];
    
    [actionSheet addSubview:sl];
    
    if( orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft ){
        //スライダーを追加
        leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 20.0f, 45.0f, 20.0f)];

    }
    else{
        //ラベルを追加
        leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 20.0f, 45.0f, 20.0f)];
    }
    
	leftLabel.backgroundColor = [UIColor clearColor];
	leftLabel.textColor = [UIColor whiteColor];
	leftLabel.font = [UIFont systemFontOfSize:14];
    leftLabel.text = @"0:00";
    leftLabel.textAlignment = UITextAlignmentRight;
    
    if( orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft ){
        //スライダーを追加
        rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(420.0f, 20.0f, 45.0f, 20.0f)];
    }
    else{
        //ラベルを追加
        rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(265.0f, 20.0f, 45.0f, 20.0f)];
    }
    
	rightLabel.backgroundColor = [UIColor clearColor];
	rightLabel.textColor = [UIColor whiteColor];
	rightLabel.font = [UIFont systemFontOfSize:14];
    rightLabel.text = [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    rightLabel.textAlignment = UITextAlignmentLeft;
    
    [actionSheet addSubview:leftLabel];
    [actionSheet addSubview:rightLabel];
    
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    [actionSheet release];
    
    
}

//再生終了時に呼ばれるデリゲートメソッド ナビゲーションバーをもとに戻す
-(void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self stopTimer];
    myPlayer.currentTime = 0;
    myPlayer = nil;
    sl = nil;
    leftLabel = nil;
    rightLabel = nil;
    playURL = nil;
    //選択の解除
    [soundTable deselectRowAtIndexPath:soundTable.indexPathForSelectedRow animated:YES]; 
}


//レコード、プレイ時のタイマースタート
-(void)startTimer{
    self.playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/5.0
                                                      target:self
                                                    selector:@selector(displayCurrentPlayingTime)
                                                    userInfo:nil
                                                     repeats:YES];
    
}

//レコード、プレイ時のタイマーストップ
-(void)stopTimer{
    if(self.playTimer){
        [self.playTimer invalidate];
    }
}

//現在のレコード、プレイ時間を表示
- (void) displayCurrentPlayingTime{
    if(myPlayer && myPlayer.isPlaying){
        int seconds = (int)myPlayer.currentTime % 60;
        int minutes = (int)myPlayer.currentTime / 60;
        int res_seconds = (int)(myPlayer.duration - myPlayer.currentTime) % 60;
        int res_minutes = (int)(myPlayer.duration - myPlayer.currentTime) / 60;
        
        leftLabel.text = [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
        rightLabel.text = [NSString stringWithFormat:@"-%d:%02d", res_minutes,res_seconds];
        
        sl.value = myPlayer.currentTime;
    }
}

//スライダーの値が変更されたときに呼ばれるメソッド　ファイル再生位置を変更する
-(void)setCurrentPlayTime{
    
    [self stopTimer];
    
    //再生位置をスライダーの値にセット
    if(myPlayer)  myPlayer.currentTime = sl.value;
    
    [self startTimer];
}

-(void)actionSheet:(UIActionSheet*)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            [myPlayer stop];
            [self stopTimer];
            myPlayer.currentTime = 0;
            sl = nil;
            myPlayer = nil;
            leftLabel = nil;
            rightLabel = nil;
            playURL = nil;
            //選択の解除
            [soundTable deselectRowAtIndexPath:soundTable.indexPathForSelectedRow animated:YES]; 
            break;
        }
    
}

-(void)editAlert{
    UIAlertView *editalert = [[UIAlertView alloc] initWithTitle:nil message:@"音声ファイルを削除するとログデータも削除されます。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [editalert show];
    [editalert release];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            [self startEditing];
            break;
        case 1:
            break;
    }
    
}


-(void)startEditing{
    // 編集モードにする
	[self.soundTable setEditing:YES animated:YES];
	
    // navigation Barの右側に[Done]ボタンを表示する。
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(stopEditing)] autorelease];
}

-(void)stopEditing{
    // 編集モードをやめる
	[self.soundTable setEditing:NO animated:YES];
    
	// navigation Barの右側に[Edit]ボタンを表示する。
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)] autorelease];
}


// commitEditingStyleはEdit呼ばれた時に削除モードになるように呼ばれるメソッド
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	if(editingStyle == UITableViewCellEditingStyleDelete){
        
		NSLog(@"delete caled");
        UserLogData *userLogData = [UserLogData sharedCenter];
        deleteFile = [NSString stringWithFormat:@"%@",[[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"file_name"]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [filePaths objectAtIndex:0];
        NSString *path = [documentDir stringByAppendingPathComponent:[[userLogData.stations objectAtIndex:indexPath.row] objectForKey:@"file_name"]];
        [fileManager removeItemAtPath: path error:NULL];
        [self deleteUserLog];
        
        
        [userLogData.stations removeObjectAtIndex:indexPath.row]; // 削除ボタンが押された行のデータを配列から削除します。
        [soundTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	
	}
}


//ユーザのログデータを取得
-(void)deleteUserLog{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURL *url = [NSURL URLWithString:@"http://wired.cyber.t.u-tokyo.ac.jp/~ueta/DeleteLog.php"];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
    [request setPostValue:deleteFile forKey:@"file_name"];
    NSLog(@"%@",deleteFile);
    [request setTimeOutSeconds:30];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(deleteSucceeded:)];
    [request setDidFailSelector:@selector(deleteFailed:)];
    [request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [request startAsynchronous];
    [SVProgressHUD showWithStatus:@"ログを消去しています。"];
    
}


//リクエスト成功時
- (void)deleteSucceeded:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    //帰ってきた文字列
    NSString *resString = [request responseString];
    NSLog(@"%@",resString);
    UIAlertView *deletealert = [[UIAlertView alloc] initWithTitle:nil message:@"ログを削除しました。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [deletealert show];
    [deletealert release];
    NSLog(@"DeleteLogSucceeded");
}


//リクエスト失敗時
- (void)deleteFailed:(ASIFormDataRequest*)request
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    UIAlertView *notdeletealert = [[UIAlertView alloc] initWithTitle:nil message:@"削除できませんでした。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [notdeletealert show];
    [notdeletealert release];
    NSLog(@"DeleteLogFailed");
}



@end
