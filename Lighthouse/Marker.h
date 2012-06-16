//
//  Marker.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/15/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Marker : NSManagedObject

@property (nonatomic, retain) NSDate *timestamp;
@property (nonatomic, retain) NSNumber *accuracy;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *thoroughfare;
@property (nonatomic, retain) NSString *subThoroughfare;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *postalCode;

@end
