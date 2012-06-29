//
//  CustomAnnotation.h
//  BGSLogger
//
//  Created by Masamichi Ueta on 12/06/19.
//  Copyright (c) 2012年 The University of Tokyo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CustomAnnotation : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;  
    NSString *annotationTitle;  
    NSString *annotationSubtitle;
}  

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;  
@property (nonatomic, retain) NSString *annotationTitle;  
@property (nonatomic, retain) NSString *annotationSubtitle;
- (id)initWithLocationCoordinate:(CLLocationCoordinate2D) _coordinate 
                           title:(NSString *)_annotationTitle subtitle:(NSString *)_annotationannSubtitle;
- (NSString *)title;
- (NSString *)subtitle;
- (void)changeCoordinate:(CLLocationCoordinate2D)_coordinate;

@end