//
//  InformationViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/07/01.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InformationViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>

@property (retain, nonatomic) IBOutlet UITableView *informationTable;

- (IBAction)doneButton:(id)sender;

@end
