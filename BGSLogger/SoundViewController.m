//
//  SoundViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/30.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "SoundViewController.h"
#import "UserLogData.h"

@interface SoundViewController ()

@end

@implementation SoundViewController
@synthesize soundTable;

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
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 8;

    
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
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
    
    //選択の解除
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 
    
    //UserLogData *userLogData = [UserLogData sharedCenter];
    
}

//アクセサリボタンタップ時に呼ばれる
-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
}


@end
