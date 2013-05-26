//
//  NetClass.m
//  BoardShare
//
//  Created by Albert Pascual on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NetClass.h"

/* The following is a brief class outline containing only the code needed to
 set up and publish a NSNetService for Bonjour networking
 
 I've left some NSLog calls, some of which are commented out, for use in debugging
 problems when getting up and running, or making sure we have what we expect*/

#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <sys/socket.h>

#define CM_NET_DOMAIN (@"local.")
#define CM_NET_TYPE (@"_netclass._tcp")



@implementation NetClass

-(id) init {
	if(self = [super init]) {
		// set up the net service
		services = [[NSMutableArray alloc] init];
		BOOL go = [self establishNetService];
		if(!go) {
			// deal with error here...
		}
		// sign up for notifications when the file handle accepts a connection
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(acceptConnection:)
                                                     name:NSFileHandleConnectionAcceptedNotification object:nil];
		// sign up for notifications that data is available to be read from the file handle
		[[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(readData:) 
                                                     name:NSFileHandleDataAvailableNotification object:nil];
	}	
    
	return self;
}

// establish our net service and publish it
-(BOOL) establishNetService {
	// set up the port, let the system assign a port number
	netSocket = [[NSSocketPort alloc] initWithTCPPort:0];
	if(!netSocket) {
		NSLog(@"Unable to establish listening socket port...");
		return NO;
	}
    
	// set up the net service
	socketAddr = (struct sockaddr*)[[netSocket address] bytes];
	if(socketAddr->sa_family == AF_INET) {
		sPort = ntohs(((struct sockaddr_in *)socketAddr)->sin_port);
	}
	else if(socketAddr->sa_family == AF_INET6) {
		sPort = ntohs(((struct sockaddr_in6 *)socketAddr)->sin6_port);
	}
	else {
		NSLog(@"Socket Family neither IPv4 or IPv6, can't handle...");
		return NO;
	}
    
	// make sure we have a valid port and our socket is good, then publish
	if(netSocket && sPort) {
		//NSLog(@"got socket and port, getting ready to publish...");
		//NSLog(@"domain: \"%@\"",CM_NET_DOMAIN);
		//NSLog(@"type: \"%@\"",CM_NET_TYPE);
		netService = [[NSNetService alloc] initWithDomain:CM_NET_DOMAIN
                                                     type:CM_NET_TYPE
                                                     name:@""
                                                     port:sPort];
		if(netService) {
			//NSLog(@"publishing service with name \"%@\"", [netService name]);
			[netService setDelegate:self];
			[netService publish];
			return YES;
		}
		else {
			//NSLog(@"Error establishing Net Service...");
			return NO;
		}
	}
    
	// if we're here, something bad happened
	NSLog(@"Something bad happened setting up net service...");
	return NO;
}

// accecpt a connection from the file handle
-(void) acceptConnection:(NSNotification*) n {
	NSLog(@"Got a connection");
	readHandle = [[n userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    
	[readHandle waitForDataInBackgroundAndNotify];
}

// read the data we've been waiting for on the connection
-(void) readData:(NSNotification*) n {
	NSLog(@"Got something...");
    
	NSData *d = [readHandle availableData];
    // go and do something with this data we wanted...
    
	[readHandle waitForDataInBackgroundAndNotify];
}

// what to do if the net service didn't publish
-(void) netService:(NSNetService*) sender didNotPublish:(NSDictionary*) errorDict {
	NSLog(@"Net Service did not publish...");
	for(NSString *s in errorDict) {
		NSLog(@"Got error %@", [errorDict valueForKey:s]); // for debugging...
	}
	if([services containsObject:sender]) {
		[services removeObject:sender];
	}
}



// what to do if the net service published correctly
-(void) netServiceDidPublish:(NSNetService*) sender {
	NSLog(@"Hooray!  We got published with name \"%@\" on port %d", [sender name], [sender port]);
	[services addObject:sender]; // we only want to keep track if it actually published
	socketHandle = [[NSFileHandle alloc] initWithFileDescriptor:[netSocket socket] closeOnDealloc:YES];
	if(socketHandle) {
		NSLog(@"should have file handle...");
		[socketHandle acceptConnectionInBackgroundAndNotify];
	}
}

@end
