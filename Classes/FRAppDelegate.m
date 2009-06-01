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
#import "SQLiteInstanceManager.h"

#import "isArrrrr.m"

static NSString *kRNEHost = @"rtve.stream.flumotion.com";

void interruptionListenerCb(void *inClientData, UInt32 interruptionState) {
	FRViewController *controller = (FRViewController *) inClientData;
	[controller audioSessionInterruption:interruptionState];
}

#pragma mark Private interface
@interface FRAppDelegate ()

- (void)installUserDatabase;

@end

#pragma mark Public implementation
@implementation FRAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [self installUserDatabase];
  
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

#pragma mark Private methods implementation

- (void)installUserDatabase {
  SQLiteInstanceManager *mgr = [SQLiteInstanceManager sharedManager];
  NSString *dbPath = [mgr databaseFilepath];
  NSString *appResources = [[NSBundle mainBundle] resourcePath];
  NSString *bundledDb = [appResources stringByAppendingPathComponent:@"franceradio.sqlite3"];
  
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  if (![fileMgr fileExistsAtPath:dbPath]) {
    NSError *error;
    
    if (![fileMgr copyItemAtPath:bundledDb toPath:dbPath error:&error]) {
      RNLog(@"Can not copy database file with error (%d) '%@'",
            [error code], [error description]);
    }
  } else {
    NSLog(@"Database already in place, skipping");
  }
}

@end