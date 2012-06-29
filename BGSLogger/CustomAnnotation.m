//
//  CustomAnnotation.m
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/19.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import "CustomAnnotation.h"

@implementation CustomAnnotation
@synthesize coordinate;
@synthesize annotationTitle;
@synthesize annotationSubtitle;

- (NSString *)title {  
    return annotationTitle;
}

- (NSString *)subtitle {  
    return annotationSubtitle;
}

- (id)initWithLocationCoordinate:(CLLocationCoordinate2D) _coordinate
                           title:(NSString *)_annotationTitle subtitle:(NSString *)_annotationSubtitle {
    coordinate = _coordinate;
    self.annotationTitle = _annotationTitle;
    self.annotationSubtitle = _annotationSubtitle;
    return self;
}

- (void)changeCoordinate:(CLLocationCoordinate2D)_coordinate {
    [self willChangeValueForKey:@"coordinate"];
    coordinate = _coordinate;
    [self didChangeValueForKey:@"coordinate"];
    
}

- (void) dealloc {
    [annotationTitle release];
    [annotationSubtitle release];
    [super dealloc];
}

@end