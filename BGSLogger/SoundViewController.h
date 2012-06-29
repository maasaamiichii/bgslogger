//
//  SoundViewController.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/30.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface SoundViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate,AVAudioPlayerDelegate>{
    
}


@property (retain, nonatomic) IBOutlet UITableView *soundTable;

@end
