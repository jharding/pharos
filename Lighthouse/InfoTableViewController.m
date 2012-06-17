//
//  InfoTableViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/17/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "InfoTableViewController.h"

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

    self.streetLabel.text = [NSString stringWithFormat:@"%@ %@", 
                            [self.detailItem valueForKey:@"subThoroughfare"], 
                            [self.detailItem valueForKey:@"thoroughfare"]];
    self.cityLabel.text = [self.detailItem valueForKey:@"city"];
    self.stateLabel.text = [self.detailItem valueForKey:@"state"];
    self.countryLabel.text = [self.detailItem valueForKey:@"country"];
    
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f", 
                              [[self.detailItem valueForKey:@"latitude"] doubleValue]];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f", 
                               [[self.detailItem valueForKey:@"longitude"] doubleValue]];
    
    self.accuracyLabel.text = [NSString stringWithFormat:@"%.02f m", 
                               [[self.detailItem valueForKey:@"accuracy"] doubleValue]];
    
    self.headingLabel.text = [NSString stringWithFormat:@"%.02f\u00B0", 
                               [[self.detailItem valueForKey:@"heading"] doubleValue]];
    
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
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
