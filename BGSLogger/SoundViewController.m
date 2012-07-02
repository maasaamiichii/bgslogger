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
#import "FMDB/FMDatabase.h"
#import "FMDB/FMDatabaseAdditions.h"

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
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(editAlert)] autorelease];
    
    
    
    soundTable.delegate = self;
    soundTable.dataSource = self;
    
    //ナビゲーションバーのタイトルをセット
    self.navigationItem.title = @"Sound Files";
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.7 green:0.0 blue:1.0 alpha:1.0]];
    
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
    [self dbGetStation];

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
        //ラベル追加
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
        int all_seconds = (int)myPlayer.duration % 60;
        int all_minutes = (int)myPlayer.duration / 60;
        int res_seconds = all_seconds - seconds;
        int res_minutes = all_minutes - minutes;
        if(res_seconds < 0){
            res_seconds += 60;
            res_minutes -= 1;
        }
        
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


//アクションシートのボタンが押された時の処理
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


//編集時にログも消えるアラートを表示
-(void)editAlert{
    
    UserLogData *userLogData = [UserLogData sharedCenter];
    NSLog(@"%d",[userLogData.stations count]);
    if([userLogData.stations count] == 0){
        return;
    }
    
    NSLog(@"%d",[userLogData.stations count]);
    
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


//編集モードスタート
-(void)startEditing{
    
    UserLogData *userLogData = [UserLogData sharedCenter];
    NSLog(@"%d",[userLogData.stations count]);
    if([userLogData.stations count] == 0){
        return;
    }
    

	[self.soundTable setEditing:YES animated:YES];
	
    // navigation Barの右側に[Done]ボタンを表示する。
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(stopEditing)] autorelease];
}


// 編集モードストップ
-(void)stopEditing{
    
	[self.soundTable setEditing:NO animated:YES];
    
	// navigation Barの右側に[Edit]ボタンを表示する。
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(startEditing)] autorelease];
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
        
        //ファイル、ログ削除
        [self deleteDB];
        
        
        [userLogData.stations removeObjectAtIndex:indexPath.row]; // 削除ボタンが押された行のデータを配列から削除します。
        [soundTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	
	}
}

//DBへ接続する
-(id) dbConnect{
    BOOL success;
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"BGSLogger.db"];
    NSLog(@"%@",writableDBPath);
    success = [fm fileExistsAtPath:writableDBPath];
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"BGSLogger.db"];
        success = [fm copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        if(!success){
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
    FMDatabase* db = [FMDatabase databaseWithPath:writableDBPath];
    return db;
    
}


//DBから音声ファイル、ログデータ削除
-(void)deleteDB{
    
    FMDatabase* db  = [self dbConnect];
    NSString*   sql = @"delete from record_information where file_name = ?";
    
    
    
    if ([db open]) {
        [db setShouldCacheStatements:YES];
        
        [db executeUpdate:sql, deleteFile];
        [db close];
    }else{
        NSLog(@"Could not open db.");
    }

}


//DBからログ情報を取得
-(void)dbGetStation{
    
    
    //データを格納するシングルトン
    UserLogData *userLogData = [UserLogData sharedCenter];
    userLogData.stations = [[[NSMutableArray alloc]init] autorelease];
    
    FMDatabase* db  = [self dbConnect];
    
    if ([db open]) {
        [db setShouldCacheStatements:YES];
        
        // SELECT
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM record_information"];
        while ([rs next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:[rs stringForColumn:@"from_lat"] forKey:@"from_lat"];
            [dict setObject:[rs stringForColumn:@"from_lon"] forKey:@"from_lon"];
            [dict setObject:[rs stringForColumn:@"to_lat"] forKey:@"to_lat"];
            [dict setObject:[rs stringForColumn:@"to_lon"] forKey:@"to_lon"];
            [dict setObject:[rs stringForColumn:@"from_name"] forKey:@"from_name"];
            [dict setObject:[rs stringForColumn:@"to_name"] forKey:@"to_name"];
            [dict setObject:[rs stringForColumn:@"file_name"] forKey:@"file_name"];
            [dict setObject:[rs stringForColumn:@"from_date"] forKey:@"from_date"];
            [dict setObject:[rs stringForColumn:@"to_date"] forKey:@"to_date"];
            [dict setObject:[rs stringForColumn:@"date"] forKey:@"date"];
            [userLogData.stations addObject:dict];
        }
        [rs close];
        [db close];
    }else{
        NSLog(@"Could not open db.");
    }
    
    if([userLogData.stations count] == 0) {
        UIAlertView *notdataalert = [[UIAlertView alloc] initWithTitle:nil message:@"ログデータはありません。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [notdataalert show];
        [notdataalert release];
        return ;
    }
}




/*
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
 */



@end
