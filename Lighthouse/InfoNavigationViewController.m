//
//  InfoNavigationViewController.m
//  Lighthouse
//
//  Created by Jacob Harding on 6/17/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "InfoNavigationViewController.h"

#import "InfoTableViewController.h"
#import "Marker.h"

@interface InfoNavigationViewController ()

@end

@implementation InfoNavigationViewController

@synthesize detailItem;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.navigationBar.tintColor = [UIColor colorWithRed:49.0f/255.0f
                                   green:146.0f/255.0f blue:198.0f/255.0f alpha:1];
    
    // this navigation view is acting as a proxy to the table view
    // detailItem just gets passed on
    InfoTableViewController *tableViewController = (InfoTableViewController *)
                                                   self.topViewController;
    tableViewController.detailItem = self.detailItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
