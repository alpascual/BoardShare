//
//  BoardShareController.h
//  BoardShare
//
//  Created by Albert Pascual on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MediaPlayer/MPVolumeView.h>

#import "NetworkSearchViewController.h"
#import "TCPServer.h"
//#import "NetClass.h"

@interface BoardShareController : UIViewController <GKPeerPickerControllerDelegate, GKSessionDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, NSNetServiceDelegate, ItemProtocol> {
    
@private
    CGPoint lastPoint;
	BOOL mouseSwiped;	
	int mouseMoved;
    UIImageView *imageView;
    NSMutableArray *pointsArray;
}
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic, retain) GKSession	 *gameSession;
@property(nonatomic, copy)	 NSString	 *gamePeerId;
@property(nonatomic) NSInteger		gameState;
@property (strong) UIAlertView		*connectionAlert;
@property (strong, nonatomic) NSMutableArray *undoImages;
@property (strong, nonatomic) NSTimer *startTimer;
@property (strong, nonatomic) UIImagePickerController *picker1;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (nonatomic,strong) NetworkSearchViewController *networkSearchController;
//@property (nonatomic,strong) NetClass *netClass;
@property (nonatomic, strong) NSNetService *netService;
@property (nonatomic, strong) TCPServer *server;


-(IBAction)toggleDrawMethod:(id)sender;
-(IBAction)clear:(id)sender;

- (IBAction)connectDevices:(id)sender;
- (void)startPicker;
- (void)invalidateSession:(GKSession *)session;

- (void)sendNetworkPacket:(GKSession *)session packetID:(int)packetID withData:(void *)data ofLength:(int)length reliable:(BOOL)howtosend;

- (void) sendStatusPacket:(int)statusPacket;
- (IBAction)undoPresses:(id)sender;

@end
