//
//  MasterViewController.h
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@class MBProgressHUD;

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, CLLocationManagerDelegate> 
{
    int retriesLeft;
    MBProgressHUD *hud;
}

// core data
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// ui
@property (strong, nonatomic) UIBarButtonItem *addButton;
@property (strong, nonatomic) UIImageView *getStartedView;

// location
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;

@end
