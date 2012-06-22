//
//  LocationData.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/20.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "LocationData.h"

@implementation LocationData
@synthesize nearStations;

static LocationData* sharedInstance = nil;

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (!sharedInstance) {
			sharedInstance = [super allocWithZone:zone];
		}
	}
	return sharedInstance;
}

+ (id)sharedCenter {
    
	static LocationData* sharedInstance = nil;
	@synchronized(self) {
		if(!sharedInstance) {
			sharedInstance = [[self alloc] init];
		}
	}
	return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	return UINT_MAX;  // 解放できないオブジェクトであることを示す
}

- (oneway void)release {
	// 何もしない
}

- (id)autorelease {
	return self;
}

//ユーザの緯度をセット
-(void)setUserLatitude:(double)userLatitude{
    _userLatitude = userLatitude;
}

-(double)getUserLatitude{
    return _userLatitude;
}


//ユーザの経度をセット
-(void)setUserLongitude:(double)userLongitude{
    _userLongitude = userLongitude;
}

-(double)getUserLongitude{
    return _userLongitude;
}


-(void)setFromLat:(double)from_lat{
    _from_lat = from_lat;
}

-(double)getFromLat{
    return _from_lat;
}

-(void)setFromLon:(double)from_lon{
    _from_lon = from_lon;
}

-(double)getFromLon{
    return _from_lon;
}

-(void)setToLat:(double)to_lat{
    _to_lat = to_lat;
}

-(double)getToLat{
    return _to_lat;
}

-(void)setToLon:(double)to_lon{
    _to_lon = to_lon;
}

-(double)getToLon{
    return _to_lon;
}

-(void)setFromName:(NSString *)from_name{
    _from_name = from_name;
}

-(NSString *)getFromName{
    return _from_name;
}

-(void)setToName:(NSString *)to_name{
    _to_name = to_name;
}

-(NSString *)getToName{
    return _to_name;
}


@end
