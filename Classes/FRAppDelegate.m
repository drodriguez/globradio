//
//  FRAppDelegate.m
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "FRAppDelegate.h"
#import "FRViewController.h"
#import "RRQReachability.h"

#import "isArrrrr.m"

static NSString *kRNEHost = @"rtve.stream.flumotion.com";

void interruptionListenerCb(void *inClientData, UInt32 interruptionState) {
	FRViewController *controller = (FRViewController *) inClientData;
	[controller audioSessionInterruption:interruptionState];
}

@implementation FRAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[[RRQReachability sharedReachability] setHostName:kRNEHost];
	[[RRQReachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
	
	OSStatus err = AudioSessionInitialize(NULL, NULL,
										  interruptionListenerCb,
										  viewController);
	if (err != kAudioSessionNoError) {
		RNLog(@"AudioSessionInitialize error %d", err);
	}
	
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	err = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
								  sizeof(sessionCategory),
								  &sessionCategory);
	if (err != kAudioSessionNoError) {
		RNLog(@"AudioSessionSetProperty error %d", err);
	}
	
	err = AudioSessionSetActive(YES);
	if (err != kAudioSessionNoError) {
		RNLog(@"AudioSessionSetActive error %d", err);
	}
  
  if (isArrrrr()) {
    RNLog(@"Busted!");
  }  
	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
    
	[[NSNotificationCenter defaultCenter] addObserver:viewController
											 selector:@selector(reachabilityChanged:)
												 name:@"kNetworkReachabilityChangedNotification"
											   object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[viewController saveApplicationState];
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end