//
//  LocationData.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/20.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationData : NSObject{
    
    double current_lat; //ユーザの緯度
    double current_lon; //ユーザの経度
    NSString *current_name;
    NSMutableArray *nearStations; //近くの駅データを格納するアレイ
    double from_lat;
    double from_lon;
    double to_lat;
    double to_lon;
    NSString *from_name;
    NSString *to_name;
    NSString *from_date;
    NSString *to_date;
    NSString *account_name;//アカウント名
    
}

@property(retain,nonatomic) NSMutableArray *nearStations; //近くの駅データを格納するアレイ
@property(readwrite) double current_lat;
@property(readwrite) double current_lon;
@property(readwrite) double from_lat;
@property(readwrite) double from_lon;
@property(readwrite) double to_lat;
@property(readwrite) double to_lon;
@property(retain,nonatomic) NSString *current_name;
@property(retain,nonatomic) NSString *from_name;
@property(retain,nonatomic) NSString *to_name;
@property(retain,nonatomic) NSString *from_date;
@property(retain,nonatomic) NSString *to_date;
@property(retain,nonatomic) NSString *account_name;


+ (id)sharedCenter;

@end
