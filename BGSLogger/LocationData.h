//
//  LocationData.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/20.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationData : NSObject{
    
    double _userLatitude; //ユーザの緯度
    double _userLongitude; //ユーザの経度
    NSMutableArray *nearStations; //近くの駅データを格納するアレイ
    double _from_lat;
    double _from_lon;
    double _to_lat;
    double _to_lon;
    NSString *_from_name;
    NSString *_to_name;
    
}

@property(retain,nonatomic) NSMutableArray *nearStations; //近くの駅データを格納するアレイ


+ (id)sharedCenter;

//ユーザの緯度
-(void)setUserLatitude:(double)userLatitude;
-(double)getUserLatitude;

//ユーザの経度
-(void)setUserLongitude:(double)userLongitude;
-(double)getUserLongitude;


-(void)setFromLat:(double)from_lat;
-(double)getFromLat;

-(void)setFromLon:(double)from_lon;
-(double)getFromLon;

-(void)setToLat:(double)to_lat;
-(double)getToLat;

-(void)setToLon:(double)to_lon;
-(double)getToLon;

-(void)setFromName:(NSString *)from_name;
-(NSString *)getFromName;

-(void)setToName:(NSString *)to_name;
-(NSString *)getToName;



@end
