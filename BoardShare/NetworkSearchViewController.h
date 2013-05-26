//
//  NetworkSearchViewController.h
//  BoardShare
//
//  Created by Albert Pascual on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ItemProtocol <NSObject>

-(void)SelectedDone:(NSString*)item;

@end

@interface NetworkSearchViewController : UIViewController <NSNetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *deviceNames;
@property (nonatomic,strong) NSMutableArray *selectedDevices;

@property (nonatomic,strong) id<ItemProtocol> delegate;

@end
