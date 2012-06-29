//
//  Record_Information.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/30.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Record_Information : NSManagedObject

@property (nonatomic, retain) NSNumber * from_lat;
@property (nonatomic, retain) NSNumber * from_lon;
@property (nonatomic, retain) NSNumber * to_lat;
@property (nonatomic, retain) NSNumber * to_lon;
@property (nonatomic, retain) NSString * from_name;
@property (nonatomic, retain) NSString * to_name;
@property (nonatomic, retain) NSString * file_name;
@property (nonatomic, retain) NSNumber * record_id;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * from_date;
@property (nonatomic, retain) NSString * to_date;

@end
