//
//  DetailViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/9/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DetailViewController.h"

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
    // Update the user interface for the detail item.
    
    NSString *street = [self.detailItem valueForKey:@"street"];
    
    self.navigationItem.title = street;
    
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[self.detailItem valueForKey:@"latitude"] doubleValue];
    coordinate.longitude = [[self.detailItem valueForKey:@"longitude"] doubleValue];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = street;
    [self.mapView addAnnotation:annotation];
    
    CLLocationDistance accuracy = [[self.detailItem valueForKey:@"accuracy"] doubleValue];
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:accuracy];
    [self.mapView addOverlay:circle];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1500, 1500);
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    
    // an annotation view isn't available so init a newone
    if (annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                         reuseIdentifier:identifier];
    } 
    
    else {
        annotationView.annotation = annotation;
    }
    
    UIImage *annotationImage = [UIImage imageNamed:@"flag.png"];
    
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    annotationView.image = annotationImage;
    
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

- (IBAction)openMapsApp:(id)sender {
    double latitude = [[self.detailItem valueForKey:@"latitude"] doubleValue];
    double longitude = [[self.detailItem valueForKey:@"longitude"] doubleValue];
    
    NSString *url = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=Current+Location&daddr=%f,%f", 
                     latitude, longitude];
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
}
@end
