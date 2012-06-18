//
//  InfoNavigationViewController.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/17/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Marker;

@interface InfoNavigationViewController : UINavigationController

@property (strong, nonatomic) Marker *detailItem;

@end
