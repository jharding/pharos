//
//  InfoTableViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/17/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "InfoTableViewController.h"

#import "Marker.h"

@interface InfoTableViewController ()

@end

@implementation InfoTableViewController

@synthesize detailItem = _detailItem;
@synthesize streetLabel = _streetLabel;
@synthesize cityLabel = _cityLabel;
@synthesize stateLabel = _stateLabel;
@synthesize countryLabel = _countryLabel;
@synthesize latitudeLabel = _latitudeLabel;
@synthesize longitudeLabel = _longitudeLabel;
@synthesize accuracyLabel = _accuracyLabel;
@synthesize headingLabel = _headingLabel;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // address
    self.streetLabel.text = [NSString stringWithFormat:@"%@ %@", 
                            self.detailItem.subThoroughfare,
                             self.detailItem.thoroughfare];
    self.cityLabel.text = self.detailItem.city;
    self.stateLabel.text = self.detailItem.state;
    self.countryLabel.text = self.detailItem.country;
    
    // coordinates
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f", 
                              self.detailItem.latitude.doubleValue];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f", 
                               self.detailItem.longitude.doubleValue];
    
    // accuracy
    self.accuracyLabel.text = [NSString stringWithFormat:@"%.02f m", 
                              self.detailItem.accuracy.doubleValue];
    
    // heading
    self.headingLabel.text = [NSString stringWithFormat:@"%.02f\u00B0", 
                               self.detailItem.heading.doubleValue];
    
}

- (void)viewDidUnload
{
    [self setStreetLabel:nil];
    [self setCityLabel:nil];
    [self setStateLabel:nil];
    [self setCountryLabel:nil];
    [self setLatitudeLabel:nil];
    [self setLongitudeLabel:nil];
    [self setAccuracyLabel:nil];
    [self setHeadingLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)dismiss:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}
@end
