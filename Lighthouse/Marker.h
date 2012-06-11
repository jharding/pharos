//
//  Marker.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/10/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Marker : NSManagedObject

@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * street;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@end
