//
//  NetworkSearchViewController.m
//  BoardShare
//
//  Created by Albert Pascual on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetworkSearchViewController.h"

@interface NetworkSearchViewController ()

@end

@implementation NetworkSearchViewController

@synthesize timer = _timer;
@synthesize serviceBrowser = _serviceBrowser;
@synthesize deviceNames = _deviceNames;
@synthesize tableView = _tableView;
@synthesize selectedDevices = _selectedDevices;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(timerCallback:) userInfo: nil repeats: NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)timerCallback:(NSTimer *)timer {
    // look for network
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    [self.serviceBrowser setDelegate:self];
    //[self.serviceBrowser searchForServicesOfType:@"_netclass._tcp" inDomain:@""];
    [self.serviceBrowser searchForServicesOfType:@"_doodle._tcp" inDomain:@""];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"Found Something %@", aNetService.name);
    
    if ( self.deviceNames == nil )
        self.deviceNames = [[NSMutableArray alloc] init];
    
    [self.deviceNames addObject:aNetService.name];
    
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( self.deviceNames != nil)
        return self.deviceNames.count;
    
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // Configure the cell.
    cell.textLabel.text = [self.deviceNames objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
    NSString *selectedItem = [self.deviceNames objectAtIndex:selectedPath.row];
    NSLog(@"Item Selected %@", selectedItem);
    
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] init];
    
    self.selectedDevices = [userDefaults objectForKey:@"selectedItems"];
    [self.selectedDevices addObject:selectedItem];
    
    [userDefaults setObject:self.selectedDevices forKey:@"selectedItems"];
    [userDefaults synchronize];
    
    [self.delegate SelectedDone:selectedItem];
}




@end
