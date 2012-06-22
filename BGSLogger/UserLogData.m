//
//  UserLogData.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/22.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "UserLogData.h"

@implementation UserLogData
@synthesize stations;

static UserLogData* sharedInstance = nil;

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (!sharedInstance) {
			sharedInstance = [super allocWithZone:zone];
		}
	}
	return sharedInstance;
}

+ (id)sharedCenter {
    
	static UserLogData* sharedInstance = nil;
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
