//
//  DetailViewController.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

@interface DetailViewController : UIViewController <MKMapViewDelegate> 

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

- (IBAction)openMapsAppForDirections:(id)sender;
- (IBAction)tweetLocation:(id)sender;
@end
