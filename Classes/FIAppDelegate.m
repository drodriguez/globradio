//
//  FIAppDelegate.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "FIAppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "FIViewController.h"
#import "RRQReachability.h"

static NSString *kFIFMHost = @"radio.asoc.fi.upm.es";

void interruptionListenerCb(void *inClientData, UInt32 interruptionState) {
  FIViewController *controller = (FIViewController *) inClientData;
  [controller audioSessionInterruption:interruptionState];
}

@implementation FIAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [[RRQReachability sharedReachability] setHostName:kFIFMHost];
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
  
  [window addSubview:viewController.view];
  [window makeKeyAndVisible];
  
  [[NSNotificationCenter defaultCenter] addObserver:viewController
                                           selector:@selector(reachabilityChanged:)
                                               name:@"kNetworkReachabilityChangedNotification"
                                             object:nil];
}

- (void)dealloc {
  [viewController release];
  [window release];
  [super dealloc];
}

@end
