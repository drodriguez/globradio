//
//  FIViewController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "FIViewController.h"
#import "AudioClass.h"
#import "Reachability.h"

NSString *kFIFMRadioURL = @"http://radio.asoc.fi.upm.es:8000/";

@interface FIViewController ()

- (void)stopRadio;

- (void)playRadio;
- (void)privatePlayRadio;

- (void)showNetworkProblemsAlert;

- (void)reachabilityChanged:(NSNotification *)notification;

@end

@implementation FIViewController

#pragma mark IBActions

- (IBAction)controlButtonClicked:(UIButton *)button {
  if (isPlaying) {
    [self stopRadio];
  } else {
    [self playRadio];
  }
}

#pragma mark Custom methods

- (void)audioSessionInterruption:(UInt32)interruptionState {
  if (interruptionState == kAudioSessionBeginInterruption) {
    BOOL playing = isPlaying;
    [self stopRadio];
    AudioSessionSetActive(NO);
    interruptedDuringPlayback = playing;
  } else if (interruptionState == kAudioSessionEndInterruption &&
             interruptedDuringPlayback) {
    AudioSessionSetActive(YES);
    [self playRadio];
    interruptedDuringPlayback = NO;
  }
}

- (void)reachabilityChanged:(NSNotification *)notification {
  if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
    [self showNetworkProblemsAlert];
  }
}

- (void)showNetworkProblemsAlert {
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problemas de conexión"
                                                      message:@"No es posible conectar a Internet.\nAsegurese de disponer de conexión a Internet."
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Aceptar", nil];
  [alertView show];
}

- (void)stopRadio {
  if (isPlaying) {
    [player stop];
  }
}

- (void)setPlayState {
  
}

- (void)setStopState {
  
}

- (void)setFailedState:(NSError *)error {
  // If we loose network reachability both callbacks will get call, so we
  // step aside if a network lose has happened.
  if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
    // The reachability callback will show its own AlertView.
    return;
  }
  
  NSString *message;
  if (error != nil) {
    message = [NSString stringWithFormat:@"Ha sucedido un error \"%@\".\nLo sentimos mucho.", error.localizedDescription];
  } else {
    message = @"Ha sucedido un error.\nLo sentimos mucho.";
  }
  
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problemas"
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Aceptar", nil];
  [alertView show];
}

- (void)setLoadingState {
  
}

- (void)playRadio {
  if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
    [self showNetworkProblemsAlert];
    return;
  }
  
  if (isPlaying) {
    return;
  }
  
  [NSThread detachNewThreadSelector:@selector(privatePlayRadio)
                           toTarget:self
                         withObject:nil];
}

- (void)privatePlayRadio {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [self performSelector:@selector(setLoadingState)
               onThread:[NSThread mainThread]
             withObject:nil
          waitUntilDone:NO];
  
  player = [[Player alloc] initWithString:kFIFMRadioURL audioTypeHint:kAudioFileMP3Type];
  
  [player addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
  [player addObserver:self forKeyPath:@"failed" options:0 context:nil];
  [player start];
  
  isPlaying = YES;
  
  [pool release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == player) {
    if ([keyPath isEqual:@"isPlaying"]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      
      if ([player isPlaying]) { // Started playing
        [self performSelector:@selector(setPlayState)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
      } else {
        [player removeObserver:self forKeyPath:@"isPlaying"];
        [player removeObserver:self forKeyPath:@"failed"];
        [player release];
        player = nil;
        
        isPlaying = NO;
        
        [self performSelector:@selector(setStopState)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
      }
      
      [pool release];
      return;
    } else if ([keyPath isEqual:@"failed"]) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      
      if ([player failed]) { // Have failed
        RNLog(@"failed!");
        [self performSelector:@selector(setFailedState:)
                     onThread:[NSThread mainThread]
                   withObject:player.error
                waitUntilDone:NO];
      } else { // Have un-failed. Can't happen
        RNLog(@"un-failed?");
      }
      
      [pool release];
      return;
    }
  }
  
  [super observeValueForKeyPath:keyPath
                       ofObject:object
                         change:change
                        context:context];
}

- (void)volumeChanged:(NSNotification *)notify {
  RNLog(@"volume changed");
  [volumeSlider _updateVolumeFromAVSystemController];
}

#pragma mark UIViewController methods

- (void)viewDidLoad {
  MPVolumeView *volumeView =
    [[[MPVolumeView alloc] initWithFrame:volumeViewHolder.bounds] autorelease];
  [volumeView sizeToFit];
  [volumeViewHolder addSubview:volumeView];
  
  // Find the slider
  volumeSlider = [volumeView valueForKey:@"_volumeSlider"];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(volumeChanged:)
                                               name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                             object:nil];
  
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  // Needed to start receiving reachability status notifications
  [[Reachability sharedReachability] remoteHostStatus];
  
  [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
  [super dealloc];
}


@end
