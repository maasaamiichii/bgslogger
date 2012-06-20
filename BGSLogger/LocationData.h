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
    
    NSString *_fromStationName; //駅名
}


+ (id)sharedCenter;

//ユーザの緯度をセット
-(void)setUserLatitude:(double)userLatitude;
//ユーザの経度をセット
-(void)setUserLongitude:(double)userLongitude;

-(double)getUserLatitude;

-(double)getUserLongitude;

-(void)setFromStationName:(NSString *) fromStatinName;

-(NSString *)getFromStationName;

@end
