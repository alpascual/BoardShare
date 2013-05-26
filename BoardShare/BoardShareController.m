//
//  BoardShareController.m
//  BoardShare
//
//  Created by Albert Pascual on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BoardShareController.h"

#import "CatmullRomSpline.h"
#include <math.h>
#include <stdio.h>

//
// various states the game can get into
//
typedef enum {
	kStateStartGame,
	kStatePicker,
	kStateMultiplayer,
	kStateMultiplayerCointoss,
	kStateMultiplayerReconnect
} gameStates;

@interface BoardShareController ()
-(void)drawSpline;
-(void)drawBezier;
@property (nonatomic,retain) NSMutableArray *pointsArray;
@end

static BOOL drawBezier = NO;
// GameKit Session ID for app
#define kBoardShareSessionID @"gktank"

#define KUndoPacket 1
#define KClearPacket 2
#define KSelectPicture 10

@implementation BoardShareController

@synthesize imageView;
@synthesize pointsArray;
@synthesize gameSession;
@synthesize gamePeerId;
@synthesize gameState;
@synthesize connectionAlert;
@synthesize undoImages;
@synthesize startTimer;
@synthesize picker1;
@synthesize backgroundImage;
@synthesize networkSearchController = _networkSearchController;
//@synthesize netClass = _netClass;
@synthesize netService = _netService;
@synthesize server = _server;


-(IBAction)toggleDrawMethod:(id)sender{
    NSLog(@"[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] %@",[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]]);
    if([[sender titleForSegmentAtIndex:[sender selectedSegmentIndex]] isEqualToString:@"Bezier Curve"]){
        drawBezier = YES;
    }else{
        drawBezier = NO;
    }
}
-(IBAction)clear:(id)sender {
    self.imageView.image = nil;
    [self.undoImages removeAllObjects];
}
- (void)viewDidLoad
{
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.undoImages = [[NSMutableArray alloc] init];    
    self.pointsArray = [NSMutableArray array];
    self.startTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(timerCallback:) userInfo: nil repeats: NO];
      
    [self.view addSubview:self.imageView];
    [super viewDidLoad];
    
    MPVolumeView *volumeView = [ [MPVolumeView alloc] init] ;
    [volumeView setShowsVolumeSlider:YES];
    [volumeView sizeToFit];
    [self.view addSubview:volumeView];
    
}
- (void)timerCallback:(NSTimer *)timer {
    [self startPicker];
    
    // Start accepting connections
    //self.netClass = [[NetClass alloc] init];
    //[self.netClass establishNetService];
    
//    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_netclass._tcp" name:@""];
//    self.netService.delegate = self;
//    [self.netService publish];   
    
    self.server = [TCPServer new];
	[self.server setDelegate:self];
	NSError *error = nil;
	if(self.server == nil || ![self.server start:&error]) {
		if (error == nil) {
			NSLog(@"Failed creating server: Server instance is nil");
		} else {
            NSLog(@"Failed creating server: %@", error);
		}
		
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![self.server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:@"doodle"] name:nil]) {
		
		return;
	}

}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"Service did published");
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
    // Store the image before adding anything.
    if ( self.imageView != nil )
        if ( self.imageView.image != nil )
            [self.undoImages addObject:self.imageView.image];
    
	mouseSwiped = NO;
	UITouch *touch = [touches anyObject];
    [self.pointsArray removeAllObjects];
	lastPoint = [touch locationInView:self.view];
	//lastPoint.y -= 20;
    [self.pointsArray addObject:[NSValue valueWithCGPoint:lastPoint]];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	mouseSwiped = YES;
	
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:self.view];
	//currentPoint.y -= 20;
	
	
	UIGraphicsBeginImageContext(self.view.frame.size);
	[self.imageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
	CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 0.1);
	CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    if ( self.imageView != nil )
        if ( self.imageView.image != nil )
            if ( self.undoImages.count == 0 )
                [self.undoImages addObject:self.imageView.image];
	
	lastPoint = currentPoint;
    
	mouseMoved++;
	
	if (mouseMoved == 10) {
		mouseMoved = 0;
	}
    [self.pointsArray addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [self.imageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 0.1);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    CGContextFlush(UIGraphicsGetCurrentContext());
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //[self drawSpline];
    //[self drawCosine];
    /*if (drawBezier) {
     [self drawBezier];
     }else{
     [self drawSpline];
     }*/
    //if ([self.pointsArray count]>15) {
        [self drawBezier];
    //}
    /*else{
        [self drawSpline];
    }*/
    
    // TEST
    
    /*NSString *error;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:self.pointsArray format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
    
    NSError *error2;  
    NSPropertyListFormat plistFormat;
    self.pointsArray = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:&plistFormat error:&error2];*/
    
    //NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pointsArray];
    //self.pointsArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    // END TEST
    
    if ( self.gameSession != nil ) {
    // Finish and send
    // Send the array to the other user
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pointsArray];
        
       //NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pointsArray];
        [self sendNetworkPacket:self.gameSession packetID:1 withData:(__bridge void*)data ofLength:data.length reliable:YES];
    }
    
	
}

-(void)drawSpline {
    NSLog(@"Drawing Spline");
    UIGraphicsBeginImageContext(CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height));
    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 8.0);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.557, 0.0, 0.0, 0.9);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
	
    CGPoint firstPoint = [[self.pointsArray objectAtIndex:0] CGPointValue];
    
    CatmullRomSpline *currentSpline = [CatmullRomSpline catmullRomSplineAtPoint:firstPoint];
    int i = 0;
    for(NSValue *v in self.pointsArray){
        if (i>0) {
            [currentSpline addPoint:[v CGPointValue]];
        }
        i++;
    }
    BOOL isFirst = YES;
    for (int i =0;i<[[currentSpline asPointArray] count];i++) {
		CGPoint currentPoint = [[[currentSpline asPointArray] objectAtIndex:i] CGPointValue];
		if(isFirst){
			lastPoint = [[[currentSpline asPointArray] objectAtIndex:0] CGPointValue];
		}else {
			lastPoint = [[[currentSpline asPointArray] objectAtIndex:i-1] CGPointValue];
		}
		//lastPoint.y += 50;
		//currentPoint.y += 50;
		
		CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
		CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
		isFirst = NO;
	}
	
    CGContextStrokePath(UIGraphicsGetCurrentContext());
	CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(),YES);
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

-(void)drawBezier {
    NSLog(@"Drawing Bezier");
    UIGraphicsBeginImageContext(CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height));
    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 8.0);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.5, 0.0, 0.9);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
	
    int curIndex = 0;
    CGFloat x0,y0,x1,y1,x2,y2,x3,y3;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path,NULL,[[self.pointsArray objectAtIndex:0] CGPointValue].x,[[self.pointsArray objectAtIndex:0] CGPointValue].y);
    
    for(NSValue *v in self.pointsArray){
        
        if(curIndex >= 4){
            for (int i=curIndex;i>=curIndex-4;i--) {
                int step = (curIndex-i);
                switch (step) {
                    case 0:
                        x3 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y3 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].y;	
                        break;
                    case 1:
                        x2 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y2 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;
                    case 2:
                        x1 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y1 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;
                    case 3:
                        x0 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y0 = [(NSValue*)[self.pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;	
                    default:
                        break;
                }			
            }
            
            
            double smooth_value = 0.5;
            
            double xc1 = (x0 + x1) / 2.0;
            double yc1 = (y0 + y1) / 2.0;
            double xc2 = (x1 + x2) / 2.0;
            double yc2 = (y1 + y2) / 2.0;
            double xc3 = (x2 + x3) / 2.0;
            double yc3 = (y2 + y3) / 2.0;
            
            double len1 = sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
            double len2 = sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
            double len3 = sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2));
            
            double k1 = len1 / (len1 + len2);
            double k2 = len2 / (len2 + len3);
            
            double xm1 = xc1 + (xc2 - xc1) * k1;
            double ym1 = yc1 + (yc2 - yc1) * k1;
            
            double xm2 = xc2 + (xc3 - xc2) * k2;
            double ym2 = yc2 + (yc3 - yc2) * k2;
            
            // Resulting control points. Here smooth_value is mentioned
            // above coefficient K whose value should be in range [0...1].
            double ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1;
            double ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1;
            
            double ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2;
            double ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2;	
            
            CGPathMoveToPoint(path,NULL,x1,y1);
            CGPathAddCurveToPoint(path,NULL,ctrl1_x,ctrl1_y,ctrl2_x,ctrl2_y, x2,y2);
            CGPathAddLineToPoint(path,NULL,x2,y2);
        }
        curIndex++;
    }
	CGContextAddPath(UIGraphicsGetCurrentContext(), path);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
	CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(),YES);
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
}

// Connecting
- (IBAction)connectDevices:(id)sender {
    [self startPicker];
}


#pragma mark -
#pragma mark Peer Picker Related Methods

-(void)startPicker {
	GKPeerPickerController*		picker;
	
	self.gameState = kStatePicker;			// we're going to do Multiplayer!
	
	picker = [[GKPeerPickerController alloc] init]; // note: picker is released in various picker delegate methods when picker use is done.
	picker.delegate = self;
	[picker show]; // show the Peer Picker
}

#pragma mark GKPeerPickerControllerDelegate Methods

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker { 
	// Peer Picker automatically dismisses on user cancel. No need to programmatically dismiss.
    
	// autorelease the picker. 
	picker.delegate = nil;
    picker = nil;
	
	// invalidate and release game session if one is around.
	if(self.gameSession != nil)	{
		[self invalidateSession:self.gameSession];
		self.gameSession = nil;
	}
	
	// go back to start mode
	self.gameState = kStateStartGame;
} 

//
// invalidate session
//
- (void)invalidateSession:(GKSession *)session {
	if(session != nil) {
		[session disconnectFromAllPeers]; 
		session.available = NO; 
		[session setDataReceiveHandler: nil withContext: NULL]; 
		session.delegate = nil; 
	}
}

/*
 *	Note: No need to implement -peerPickerController:didSelectConnectionType: delegate method since this app does not support multiple connection types.
 *		- see reference documentation for this delegate method and the GKPeerPickerController's connectionTypesMask property.
 */

//
// Provide a custom session that has a custom session ID. This is also an opportunity to provide a session with a custom display name.
//
- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type { 
	GKSession *session = [[GKSession alloc] initWithSessionID:kBoardShareSessionID displayName:nil sessionMode:GKSessionModePeer]; 
	return session; // peer picker retains a reference, so autorelease ours so we don't leak.
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session { 
	// Remember the current peer.
	self.gamePeerId = peerID;  // copy
	
	// Make sure we have a reference to the game session and it is set up
	self.gameSession = session; // retain
	self.gameSession.delegate = self; 
	[self.gameSession setDataReceiveHandler:self withContext:NULL];
	
	// Done with the Peer Picker so dismiss it.
	[picker dismiss];
	picker.delegate = nil;
	picker = nil;
	
	// Start Multiplayer game by entering a cointoss state to determine who is server/client.
	self.gameState = kStateMultiplayerCointoss;
} 


// Session delegate
/* Indicates a state change for the given peer.
 */
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    if(self.gameState == kStatePicker) {
		return;				// only do stuff if we're in multiplayer, otherwise it is probably for Picker
	}
	
	if(state == GKPeerStateDisconnected) {
		// We've been disconnected from the other peer.
		
		// Update user alert or throw alert if it isn't already up
		NSString *message = [NSString stringWithFormat:@"Could not reconnect with %@.", [session displayNameForPeer:peerID]];
		if((self.gameState == kStateMultiplayerReconnect) && self.connectionAlert && self.connectionAlert.visible) {
			self.connectionAlert.message = message;
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Connection" message:message delegate:self cancelButtonTitle:@"End Game" otherButtonTitles:nil];
			self.connectionAlert = alert;
			[alert show];
        
		}
		
		// go back to start mode
		self.gameState = kStateStartGame; 
	} 
}

/* Indicates a connection request was received from another peer. 
 
 Accept by calling -acceptConnectionFromPeer:
 Deny by calling -denyConnectionFromPeer:
 */
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    
}

/* Indicates a connection error occurred with a peer, which includes connection request failures, or disconnects due to timeouts.
 */
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    
}

/* Indicates an error occurred with the session such as failing to make available.
 */
- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    
}


// Send and Receive events and methods
/*
 * Getting a data packet. This is the data receive handler method expected by the GKSession. 
 * We set ourselves as the receive data handler in the -peerPickerController:didConnectPeer:toSession: method.
 */
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context { 
	//static int lastPacketTime = -1;
	//unsigned char *incomingPacket = (unsigned char *)[data bytes];
    
    // TODO fix the array
    //NSError *error;  
    //NSPropertyListFormat plistFormat;
    //self.pointsArray = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:&plistFormat error:&error];
    
    if ( data.length > 10 ) {
        self.pointsArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        [self drawSpline];
    }
    else {
        unsigned char *incomingPacket = (unsigned char *)[data bytes];
        int *pIntData = (int *)&incomingPacket[0];
        int packetID = pIntData[1];
        switch (packetID) {
            case KUndoPacket:
                //do something
                [self undoPresses:nil];
                break;
                
            case KClearPacket:
                //do something
                [self clear:nil];
                break;
                
            default:
                break;
        }
    }
    /*int *pIntData = (int *)&incomingPacket[0];
	//
	// developer  check the network time and make sure packers are in order
	//
	int packetTime = pIntData[0];
	int packetID = pIntData[1];
	if(packetTime < lastPacketTime && packetID != NETWORK_COINTOSS) {
		return;	
	}
	
	lastPacketTime = packetTime;
	switch( packetID ) {
		case NETWORK_COINTOSS:
        {
            // coin toss to determine roles of the two players
            int coinToss = pIntData[2];
            // if other player's coin is higher than ours then that player is the server
            if(coinToss > gameUniqueID) {
                self.peerStatus = kClient;
            }
            
            // notify user of tank color
            self.gameLabel.text = (self.peerStatus == kServer) ? kBlueLabel : kRedLabel; // server is the blue tank, client is red
            self.gameLabel.hidden = NO;
            // after 1 second fire method to hide the label
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideGameLabel:) userInfo:nil repeats:NO];
        }
			break;
		case NETWORK_MOVE_EVENT:
        {
            // received move event from other player, update other player's position/destination info
            tankInfo *ts = (tankInfo *)&incomingPacket[8];
            int peer = (self.peerStatus == kServer) ? kClient : kServer;
            tankInfo *ds = &tankStats[peer];
            ds->tankDestination = ts->tankDestination;
            ds->tankDirection = ts->tankDirection;
        }
			break;
		case NETWORK_FIRE_EVENT:
        {
            // received a missile fire event from other player, update other player's firing status
            tankInfo *ts = (tankInfo *)&incomingPacket[8];
            int peer = (self.peerStatus == kServer) ? kClient : kServer;
            tankInfo *ds = &tankStats[peer];
            ds->tankMissile = ts->tankMissile;
            ds->tankMissilePosition = ts->tankMissilePosition;
            ds->tankMissileDirection = ts->tankMissileDirection;
        }
			break;
		case NETWORK_HEARTBEAT:
        {
            // Received heartbeat data with other player's position, destination, and firing status.
            
            // update the other player's info from the heartbeat
            tankInfo *ts = (tankInfo *)&incomingPacket[8];		// tank data as seen on other client
            int peer = (self.peerStatus == kServer) ? kClient : kServer;
            tankInfo *ds = &tankStats[peer];					// same tank, as we see it on this client
            memcpy( ds, ts, sizeof(tankInfo) );
            
            // update heartbeat timestamp
            self.lastHeartbeatDate = [NSDate date];
            
            // if we were trying to reconnect, set the state back to multiplayer as the peer is back
            if(self.gameState == kStateMultiplayerReconnect) {
                if(self.connectionAlert && self.connectionAlert.visible) {
                    [self.connectionAlert dismissWithClickedButtonIndex:-1 animated:YES];
                }
                self.gameState = kStateMultiplayer;
            }
        }
			break;
		default:
			// error
			break;
	}*/
    
}

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend {
	// the packet we'll send is resued
	
	if(length > 10) { 
        NSData *packet = (__bridge NSData*) data;
		if(howtosend == YES) { 
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataReliable error:nil];
		} else {
			[session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataUnreliable error:nil];
		}
	}
    else
    {
        static unsigned char networkPacket[9];
        memcpy( &networkPacket[0], data, length ); 
        NSData *packet = [NSData dataWithBytes: data length: length ];
        [session sendData:packet toPeers:[NSArray arrayWithObject:gamePeerId] withDataMode:GKSendDataReliable error:nil];
    }
}

- (void) sendStatusPacket:(int)statusPacket {
    
    int *pIntData = (int *)&statusPacket;
    [self sendNetworkPacket:self.gameSession packetID:1 withData:pIntData ofLength:1 reliable:YES];
}

// Undo method
- (IBAction)undoPresses:(id)sender {
    
    if ( self.undoImages.count > 0 )
    {
        UIImage *last = [self.undoImages objectAtIndex:self.undoImages.count-1];
        self.imageView.image = last;
        [self.undoImages removeObjectAtIndex:self.undoImages.count-1];
        
        // TODO, send a message to the other user if any
        if ( self.gameSession != nil )
        {
            [self sendStatusPacket:KUndoPacket];
        }
    }
}

// Camera or pictures
-(IBAction)cameraPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Where do you want the image from?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Take Picture"
                                  otherButtonTitles:@"Photo Library", nil];   
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [actionSheet showFromRect:CGRectMake(300, 850, 200, 500) inView:self.view animated:NO];
        
    }
    
    else    
        [actionSheet showFromRect:CGRectMake(0, 300, 200, 500) inView:self.view animated:NO];
}

// What word did the user clicked?
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.picker1 = [[UIImagePickerController alloc] init];
    self.picker1.delegate = self;
    
    if ( buttonIndex == 0)
    {        
        self.picker1.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.picker1.showsCameraControls = YES;
        self.picker1.navigationBarHidden = YES;
        self.picker1.toolbarHidden = YES;
        self.picker1.wantsFullScreenLayout = YES;
        self.picker1.cameraViewTransform = CGAffineTransformMakeScale(1.25, 1.25);
    }    
    else if ( buttonIndex == 1)
    {
        self.picker1.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
        
    [self presentViewController:self.picker1 animated:YES completion:nil];    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *) editingInfo
{
    [self dismissModalViewControllerAnimated:YES];
    
    self.backgroundImage.image = image;
    self.picker1 = nil;
}

- (IBAction)emailPressed:(id)sender {
    MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
    mcvc.mailComposeDelegate = self;
    // Set Subject...
    [mcvc setSubject:@"Look at my new pic"];
    
    NSData *data1 = UIImagePNGRepresentation(self.imageView.image);
    
    [mcvc addAttachmentData:data1 mimeType:@"image/png" fileName:@"Logo.png"];
        
    [self presentModalViewController:mcvc animated:YES];
}

- (IBAction)networkSearch:(id)sender {
    self.networkSearchController = [[NetworkSearchViewController alloc] initWithNibName:@"NetworkSearchViewController" bundle:nil];
    self.networkSearchController.delegate = self;
    
    [self presentModalViewController:self.networkSearchController animated:YES];
}

-(void)SelectedDone:(NSString*)item
{
        //TODO connect to that device
}

@end
