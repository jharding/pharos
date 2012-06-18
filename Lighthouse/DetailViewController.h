//
//  DetailViewController.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

@class Marker;

@interface DetailViewController : UIViewController <MKMapViewDelegate> 

@property (strong, nonatomic) Marker *detailItem;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

- (IBAction)openMapsAppForDirections:(id)sender;
- (IBAction)tweetLocation:(id)sender;
- (IBAction)showCurrentLocation:(id)sender;
@end
