//
//  DetailViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DetailViewController.h"

#import <Twitter/Twitter.h>
#import "Marker.h"

#define ZOOM_DISTANCE_IN_METERS 1000
#define OVERLAY_OPACITY 0.3
#define OVERLAY_STROKE_WIDTH 5

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController


@synthesize detailItem = _detailItem;
@synthesize mapView = _mapView;
@synthesize navigationItem;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{    
    self.navigationItem.title = self.detailItem.name;
    
    CLLocationCoordinate2D coordinates;
    coordinates.latitude = self.detailItem.latitude.doubleValue;
    coordinates.longitude = self.detailItem.longitude.doubleValue;
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinates;
    annotation.title = self.detailItem.name;
    [self.mapView addAnnotation:annotation];
    
    // only show accuracy overlay if accuracy isn't within 10 meters
    CLLocationDistance accuracy = self.detailItem.accuracy.doubleValue;
    if (accuracy > kCLLocationAccuracyNearestTenMeters) {
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinates radius:accuracy];
        [self.mapView addOverlay:circle];
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinates, 
                                ZOOM_DISTANCE_IN_METERS, ZOOM_DISTANCE_IN_METERS);
    [self.mapView setRegion:region];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.mapView.showsUserLocation = YES;
    
    [self configureView];
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setNavigationItem:nil];
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - MKMapViewDelegate

- (void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    // bring user location to front
    for (MKAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
            [view.superview bringSubviewToFront:view];
        }
        
        else {
            [view.superview sendSubviewToBack:view];
        }
    }
}

-(void) mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // bring user location to front
    for (id annotation in [mapView annotations]) {
        if ([annotation isKindOfClass:[MKUserLocation class]]) {
            MKAnnotationView *view = [mapView viewForAnnotation:(MKUserLocation *)annotation];
            [view.superview bringSubviewToFront:view];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // static identifier so annotation views can be reused
    static NSString *identifier = @"LighthouseAnnotationIdentifier";
    
    // annotation is for the user's location
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    // reuse annotation view if possible
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    // an annotation view isn't available so init a new one
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                         reuseIdentifier:identifier];
    } 
    
    else {
        annotationView.annotation = annotation;
    }
    
    UIImage *annotationImage = [UIImage imageNamed:@"annotation.png"];
    
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    annotationView.image = annotationImage;
    
    // center annotation image
    // why i have to divide by 4 rather than 2 idk
    CGPoint centerOffset = CGPointMake(-(annotationImage.size.width)/4, 0);
    annotationView.centerOffset = centerOffset;
    
    return annotationView;
}

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.lineWidth = OVERLAY_STROKE_WIDTH;
    circleView.strokeColor = [UIColor yellowColor];
    circleView.fillColor = [[UIColor yellowColor] colorWithAlphaComponent:OVERLAY_OPACITY];
    
    return circleView;
}

#pragma mark - UI Handlers

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showInfo"]) {
        [[segue destinationViewController] setDetailItem:self.detailItem];
    }
}

- (IBAction)openMapsAppForDirections:(id)sender 
{
    NSLog(@"Opening Maps app for directions");
    
    CLLocationCoordinate2D startCoordinates = self.mapView.userLocation.location.coordinate;
    double startLatitude = startCoordinates.latitude;
    double startLongitude = startCoordinates.longitude;
    
    double destinationLatitude = self.detailItem.latitude.doubleValue;
    double destinationLongitude = self.detailItem.longitude.doubleValue;
    
    NSString *mapsUrlFormat = @"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f";
    NSString *url = [NSString stringWithFormat:mapsUrlFormat, startLatitude, startLongitude,
                    destinationLatitude, destinationLongitude];
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
}

- (IBAction)tweetLocation:(id)sender 
{
    NSLog(@"Prompting user with Twitter interface");
    
    double latitude = self.detailItem.latitude.doubleValue;
    double longitude = self.detailItem.longitude.doubleValue;
    double heading = self.detailItem.heading.doubleValue;
    
    NSString *city = [self.detailItem.city 
                      stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];    
    NSString *state = [self.detailItem.state 
                       stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *street = nil;
    if (self.detailItem.subThoroughfare) {
        street = [[NSString stringWithFormat:@"%@ %@", 
                 self.detailItem.subThoroughfare, self.detailItem.thoroughfare] 
                 stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    
    else {
        street = [self.detailItem.thoroughfare 
                 stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    
    NSString *urlFormat = @"http://pharosapp.com/map.html?l=%f,%f&h=%.02f"
                          "&sr=%@&c=%@&sa=%@";
    NSString *url = [NSString stringWithFormat:urlFormat, latitude, longitude, 
                    heading, street, city, state];
    
    TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];
    [twitter addURL:[NSURL URLWithString:url]];
    
    
    [twitter setInitialText:NSLocalizedString(@"boilerplateTweet", nil)];
    
    [self presentModalViewController:twitter animated:YES];
}

- (IBAction)showCurrentLocation:(id)sender 
{
    CLLocationCoordinate2D currentCoordinates = self.mapView.userLocation.location.coordinate;    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(currentCoordinates,
                                ZOOM_DISTANCE_IN_METERS, ZOOM_DISTANCE_IN_METERS);
    
    NSLog(@"Showing user current location: %f,%f", 
          currentCoordinates.latitude, currentCoordinates.longitude);
    [self.mapView setRegion:region animated:YES];
}

@end
