//
//  UserLogData.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserLogData : NSObject{
    
    NSMutableArray *stations; //駅データを格納するアレイ
    
}

@property(retain,nonatomic) NSMutableArray *stations; //近くの駅データを格納するアレイ

+ (id)sharedCenter;

@end
