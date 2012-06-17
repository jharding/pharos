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
#define SECONDS_BETWEEN_ATTEMPTS 2
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
    
	self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:.49 
                                                        green:.69 blue:.84 alpha:1];
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
    return YES;
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
         
         // set the timestamp and coordinates of location
         Marker *marker = [NSEntityDescription insertNewObjectForEntityForName:[entity name] 
                                                        inManagedObjectContext:context];
         [marker setTimestamp:[NSDate date]];
         [marker setLatitude:[NSNumber numberWithDouble:coordinates.latitude]];
         [marker setLongitude:[NSNumber numberWithDouble:coordinates.longitude]];
         [marker setAccuracy:[NSNumber numberWithDouble:location.horizontalAccuracy]];
         
         if (heading != nil) {
             [marker setHeading:[NSNumber numberWithDouble:heading.trueHeading]];
         }
         
         else {
             NSLog(@"Invalid heading");
             [marker setHeading:0];
         }
             
         // if placemark is available, set address
         if ([placemarks count] > 0) {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             
             
             [marker setName:placemark.name];
             [marker setThoroughfare:placemark.thoroughfare];
             [marker setSubThoroughfare:placemark.subThoroughfare];
             [marker setCity:placemark.locality];
             [marker setState:placemark.administrativeArea];
             [marker setCountry:placemark.country];
             [marker setPostalCode:placemark.postalCode];
             
             NSString *address = [NSString stringWithFormat:ADDRESS_FORMAT,
                                  placemark.name, placemark.locality,
                                  placemark.administrativeArea];
             [marker setAddress:address];
         }
         
         else {
             // TODO: no placemarks
         }
         
         // save context
         NSLog(@"Saving coordinates:%f,%f accuracy:%f, heading:%f", 
               coordinates.latitude, coordinates.longitude,
               location.horizontalAccuracy, heading.trueHeading);
         NSError *saveError = nil;
         if (![context save:&saveError]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
             abort();
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
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
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
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
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
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
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
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
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
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // construct address string and figure out its size
    NSString *address = [object valueForKey:@"address"];
    CGSize textLabelSize = [address sizeWithFont:[UIFont fontWithName:@"Helvetica" size:18.0f]
                           constrainedToSize:maxLabelSize lineBreakMode:UILineBreakModeWordWrap];
    
    // construct date string and figure out its size
    NSDate *date = [object valueForKey:@"timestamp"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [dateFormatter stringFromDate:date];
    CGSize detailTextLabelSize = [dateString sizeWithFont:[UIFont fontWithName:@"Helvetica" 
                                 size:14.0f] constrainedToSize:maxLabelSize 
                                 lineBreakMode:UILineBreakModeWordWrap];
    
    return textLabelSize.height + detailTextLabelSize.height + 
    TEXT_LABEL_PADDING;    
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *address = [object valueForKey:@"address"];
    cell.textLabel.text = address;
    
    // construct date string and set the detail text label's value accordingly
    NSDate *date = [object valueForKey:@"timestamp"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    cell.detailTextLabel.text = [dateFormatter stringFromDate:date];
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
