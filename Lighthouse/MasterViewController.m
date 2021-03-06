//
//  MasterViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"
#import "MBProgressHUD.h"
#import "Marker.h"

#define TEXT_LABEL_WIDTH_IPHONE_PORTRAIT  269
#define TEXT_LABEL_WIDTH_IPHONE_LANDSCAPE 420
#define TEXT_LABEL_PADDING 20
#define MAX_NUM_OF_RETRIES 3
#define SECONDS_BETWEEN_ATTEMPTS 1
#define ADDRESS_FORMAT @"%@\n%@, %@"

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)showHUD;
- (void)hideHUD;
- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message;
@end

@implementation MasterViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize addButton = _addButton;
@synthesize getStartedView = _getStartedView;
@synthesize locationManager = _locationManager;
@synthesize geocoder = _geocoder;

- (UIBarButtonItem *)addButton
{
    if (_addButton != nil) {
        return _addButton;
    }
    
    _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                 target:self action:@selector(addCurrentLocation:)];
    
    return _addButton;
}

- (CLLocationManager *)locationManager 
{
    if (_locationManager != nil) {
        return _locationManager;
    }
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.delegate = self;
    
    return _locationManager;
}

- (CLGeocoder *)geocoder 
{
    if (_geocoder != nil) {
        return _geocoder;
    }
    
    _geocoder = [[CLGeocoder alloc] init];
    
    return _geocoder;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:49.0f/255.0f 
                                                        green:146.0f/255.0f blue:198.0f/255.0f
                                                        alpha:1];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [self addButton];
    self.addButton.enabled = NO;
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    NSLog(@"locationManager started");
}

- (void)viewDidUnload
{
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    NSLog(@"locationManager stopped");
    
    [self setAddButton:nil];
    [self setLocationManager:nil];
    [self setGeocoder:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)addCurrentLocation:(id)sender
{
    NSLog(@"User attempting to save current location");
    retriesLeft = MAX_NUM_OF_RETRIES;
    [self retrieveCurrentLocation];
}

- (void)retrieveCurrentLocation
{
    [self showHUD];
    
    CLLocation *location = self.locationManager.location;
    CLHeading *heading = self.locationManager.heading;
    
    // bad location if we got no location or bad accuracy
    BOOL isBadLocation = !location || 
                         location.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters;
    
    // try again in a couple of seconds if we haven't reached the attempt limit
    if (isBadLocation && retriesLeft > 0) {
        retriesLeft--;
        
        NSLog(@"Retrying to retrieve location, %d tries left", retriesLeft);
        [NSTimer scheduledTimerWithTimeInterval:SECONDS_BETWEEN_ATTEMPTS target:self 
        selector:@selector(retrieveCurrentLocation) userInfo:nil repeats:NO];
        
        return;
    }
    
    // ran out of attempts and still have no location, have nothing 
    // to save so hide hud and return
    if (!location) {
        NSLog(@"Failed to retrieve location");
        [self showAlertViewWithTitle:NSLocalizedString(@"noLocationAlertTitle", nil) 
        message:NSLocalizedString(@"noLocationAlertMessage", nil)];
        
        [self hideHUD];
        return;
    }
    
    // ran out of attempts and still have inaccurate location
    else if (location.horizontalAccuracy > kCLLocationAccuracyHundredMeters) {
        NSLog(@"Retrieved inaccurate location");
        [self showAlertViewWithTitle:NSLocalizedString(@"inaccurateLocationAlertTitle", nil) 
        message:NSLocalizedString(@"inaccurateLocationAlertMessage", nil)];
    }
    
    // saveLocation:heading: will hide the HUD
    [self saveLocation:location heading:heading];
}

- (void)saveLocation:(CLLocation *)location heading:(CLHeading *)heading
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    // get the user's current location
    CLLocationCoordinate2D coordinates = [location coordinate];
    
    NSLog(@"Attempting to reverse geocode %f, %f", coordinates.latitude, coordinates.longitude);
    [[self geocoder] reverseGeocodeLocation:location completionHandler:
     ^(NSArray *placemarks, NSError *error) 
     {
         [self hideHUD];
         
         Marker *marker = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                          inManagedObjectContext:context];
         
         // set the timestamp and coordinates of location
         marker.timestamp = [NSDate date];
         marker.latitude = [NSNumber numberWithDouble:coordinates.latitude];
         marker.longitude = [NSNumber numberWithDouble:coordinates.longitude];
         marker.accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
         
         if (heading != nil) {
             [marker setHeading:[NSNumber numberWithDouble:heading.trueHeading]];
         }
         
         // heading isn't available, default to north
         else {
             NSLog(@"Invalid heading");
             marker.heading = 0;
         }
         
         if (!error) {
             // if placemark is available, set address
             if ([placemarks count] > 0) {
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                 
                 marker.name = placemark.name;
                 marker.subThoroughfare = placemark.subThoroughfare;
                 marker.thoroughfare = placemark.thoroughfare;
                 marker.city = placemark.locality;
                 marker.state = placemark.administrativeArea;
                 marker.country = placemark.country;
                 marker.postalCode = placemark.postalCode;
                 
                 NSString *address = [NSString stringWithFormat:ADDRESS_FORMAT,
                                      placemark.name, placemark.locality,
                                      placemark.administrativeArea];
                 marker.address = address;
             }
             
             else {
                 NSLog(@"Reverse geocoding failed to find a placemark");
                 
                 marker.name = @"";
                 marker.subThoroughfare = @"";
                 marker.thoroughfare = @"";
                 marker.city = @"";
                 marker.state = @"";
                 marker.country = @"";
                 marker.postalCode = @"";
                 marker.address = NSLocalizedString(@"reverseGeocodingFailed", nil);
             }
         }
         
         else {
             NSLog(@"Reverse geocoding returned error: %@", error);
             
             marker.name = @"";
             marker.subThoroughfare = @"";
             marker.thoroughfare = @"";
             marker.city = @"";
             marker.state = @"";
             marker.country = @"";
             marker.postalCode = @"";
             marker.address = NSLocalizedString(@"reverseGeocodingFailed", nil);
         }
            
         NSLog(@"Saving coordinates:%f,%f accuracy:%f, heading:%f", 
               coordinates.latitude, coordinates.longitude,
               location.horizontalAccuracy, heading.trueHeading);
         
         // save context
         NSError *saveError = nil;
         if (![context save:&saveError]) {
             NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
             
             // show alert dialog to notify user of error
             UIAlertView *alertView = [[UIAlertView alloc] 
                                      initWithTitle:NSLocalizedString(@"saveErrorTitle", nil) 
                                      message:NSLocalizedString(@"saveErrorMessage", nil) 
                                      delegate:nil cancelButtonTitle:@"OK" 
                                      otherButtonTitles:nil];
             [alertView show];
         }
     }];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] 
                                                   objectAtIndex:section];
    
    NSInteger numOfRows = [sectionInfo numberOfObjects];
    
    // show the get started view if the user doesn't have any
    // saved locations
    if (numOfRows == 0) {
        [self showGetStartedView];
    }
    
    else {
        [self hideGetStartedView];
    }
    
    return numOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            
            // show alert dialog to notify user of error
            UIAlertView *alertView = [[UIAlertView alloc] 
                                      initWithTitle:NSLocalizedString(@"saveErrorTitle", nil) 
                                      message:NSLocalizedString(@"saveErrorMessage", nil) 
                                      delegate:nil cancelButtonTitle:@"OK" 
                                      otherButtonTitles:nil];
            [alertView show];
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Marker *marker = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:marker];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Marker" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);

        // show alert dialog to notify user of error
        UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:NSLocalizedString(@"loadErrorTitle", nil) 
                                  message:NSLocalizedString(@"loadErrorMessage", nil) 
                                  delegate:nil cancelButtonTitle:@"OK" 
                                  otherButtonTitles:nil];
        [alertView show];
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isPortrait = (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation));
    
    // get dimensions of largest possible label
    CGFloat maxHeight = 9999;
    CGFloat maxWidth = isPortrait ? TEXT_LABEL_WIDTH_IPHONE_PORTRAIT :
    TEXT_LABEL_WIDTH_IPHONE_LANDSCAPE;
    CGSize maxLabelSize = CGSizeMake(maxWidth, maxHeight);
    
    Marker *marker = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // construct address string and figure out its size
    CGSize textLabelSize = [marker.address 
                           sizeWithFont:[UIFont fontWithName:@"Helvetica" size:18.0f]
                           constrainedToSize:maxLabelSize lineBreakMode:UILineBreakModeWordWrap];
    
    // construct date string and figure out its size
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:marker.timestamp];
    CGSize detailTextLabelSize = [dateString sizeWithFont:[UIFont fontWithName:@"Helvetica" 
                                 size:14.0f] constrainedToSize:maxLabelSize 
                                 lineBreakMode:UILineBreakModeWordWrap];
    
    return textLabelSize.height + detailTextLabelSize.height + 
    TEXT_LABEL_PADDING;    
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Marker *marker = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = marker.address;
    
    // construct date string and set the detail text label's value accordingly
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    cell.detailTextLabel.text = [dateFormatter stringFromDate:marker.timestamp];
}

#pragma mark - Location Manager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation
{
    self.addButton.enabled = YES;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager failed. Error: %@", error);
    self.addButton.enabled = NO;
}

#pragma mark - UI Helpers

- (void)showGetStartedView
{
    if (!self.getStartedView) {
        // create and add get started view as a subview
        self.getStartedView = [[UIImageView alloc] 
                              initWithImage:[UIImage imageNamed:@"get-started.png"]];
        [self.view addSubview:self.getStartedView];
        
        // disable scrolling and editing
        self.tableView.scrollEnabled = NO;
        self.editButtonItem.enabled = NO;
        self.editing = NO;
    }
}

- (void)hideGetStartedView
{
    if (self.getStartedView) {
        // remove get started view
        [self.getStartedView removeFromSuperview];
        self.getStartedView = nil;
        
        // enable scroll and edit button
        self.tableView.scrollEnabled = YES;
        self.editButtonItem.enabled = YES;
    }
}

- (void)showHUD
{
    if (hud != nil) {
        return;
    }
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"savingNewLocation", nil);
}

- (void)hideHUD
{
    if (hud == nil) {
        return;
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    hud = nil;
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message 
                             delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alertView show];
}

@end
