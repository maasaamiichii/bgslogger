//
//  InformationViewController.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/07/01.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "InformationViewController.h"
#import "DetailViewController.h"

@interface InformationViewController ()

@end

@implementation InformationViewController
@synthesize informationTable;

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
    informationTable.delegate = self;
    informationTable.dataSource = self;
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.0 alpha:1.0]];

	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setInformationTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)doneButton:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    
}
- (void)dealloc {
    [informationTable release];
    [super dealloc];
}


//セクションの数
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

//セクションに含まれるセルの数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 1;
        default:
            return 0;
            break;
    }
}

//セクションヘッダーのタイトル
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return @"アプリケーションについて";
            break;
        case 1:
            return @"開発者情報";
            break;
        default:
            return 0;
            break;
    }
}


//セルの高さ
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

//セルの内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 8;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"BGSLoggerについて";
                    cell.imageView.image = [UIImage imageNamed:@"27-planet.png"];
                    break;
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"開発者情報";
                    cell.imageView.image = [UIImage imageNamed:@"132-ghost.png"];
                    break;
                    
                default:
                    break;
            }
            
        default:
            break;
    }
    return cell;
}


//セルタップ時に呼ばれる
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //選択の解除
    [informationTable deselectRowAtIndexPath:informationTable.indexPathForSelectedRow animated:YES]; 
    
    if(indexPath.section == 0){
        [self performSegueWithIdentifier:@"Detail" sender:self];
    }
    else if(indexPath.section == 1){
        [self performSegueWithIdentifier:@"Develop" sender:self];
    }
}

@end
