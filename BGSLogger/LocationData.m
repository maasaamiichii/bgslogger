//
//  LocationData.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/20.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "LocationData.h"

@implementation LocationData

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

//ユーザの経度をセット
-(void)setUserLongitude:(double)userLongitude{
    _userLongitude = userLongitude;
}

-(double)getUserLatitude{
    return _userLatitude;
}

-(double)getUserLongitude{
    return _userLongitude;
}


-(void)setFromStationName:(NSString *)fromStatinName{
    _fromStationName = fromStatinName;
}

-(NSString *)getFromStationName{
    return _fromStationName;
}



@end
