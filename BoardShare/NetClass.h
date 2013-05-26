//
//  NetClass.h
//  BoardShare
//
//  Created by Albert Pascual on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetClass : NSObject <NSNetServiceDelegate> {
    
    // net service stuff
    NSNetService *myService;
    NSSocketPort *netSocket;
    NSFileHandle *socketHandle;
    NSFileHandle *readHandle;
    struct sockaddr *socketAddr;
    int sPort;
    NSMutableArray *services;
    NSNetService *netService;
    
}

// service communication methods
-(BOOL) establishNetService;
-(void) acceptConnection:(NSNotification*) n;
-(void) readData:(NSNotification*) notification;

// NSNetService delegate methods
-(void) netService:(NSNetService*) sender didNotPublish:(NSDictionary*) errorDict;
-(void) netServiceDidPublish:(NSNetService*) sender;
-(void) netServiceWillPublish:(NSNetService*) sender;

@end