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
@synthesize current_lat;
@synthesize current_lon;
@synthesize current_name;
@synthesize from_lat;
@synthesize from_lon;
@synthesize from_name;
@synthesize to_lat;
@synthesize to_lon;
@synthesize to_name;
@synthesize from_date;
@synthesize to_date;
@synthesize account_name;

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


@end
