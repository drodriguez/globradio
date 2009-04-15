//
//  COPEAppDelegate.m
//  radio3
//
//  Created by Javier Quevedo on 1/8/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "COPEAppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import "COPEViewController.h"
#import "RRQReachability.h"

static NSString *kCOPEHost = @"cope.stream.flumotion.com";

void interruptionListenerCb(void *inClientData, UInt32 interruptionState) {
  COPEViewController *controller = (COPEViewController *) inClientData;
  [controller audioSessionInterruption:interruptionState];
}

@implementation COPEAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  [[RRQReachability sharedReachability] setHostName:kCOPEHost];
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

- (void)applicationWillTerminate:(UIApplication *)application {
  [viewController saveApplicationState];
}

- (void)dealloc {
  [viewController release];
  [window release];
  [super dealloc];
}

@end
