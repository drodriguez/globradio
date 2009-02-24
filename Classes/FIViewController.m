//
//  FIViewController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "FIViewController.h"
#import "ShoutcastAudioClass.h"
#import "Reachability.h"
// #import "FIShoutcastMetadataFilter.h"

NSString *kFIFMRadioURL = @"http://radio.asoc.fi.upm.es:8000/";
// NSString *kFIFMRadioURL = @"http://scfire-ntc-aa10.stream.aol.com:80/stream/1040";

@interface FIViewController ()

@property (nonatomic, retain) UIImage *playImage;
@property (nonatomic, retain) UIImage *playHighlightImage;
@property (nonatomic, retain) UIImage *pauseImage;
@property (nonatomic, retain) UIImage *pauseHighlightImage;

- (void)stopRadio;

- (void)playRadio;
- (void)privatePlayRadio;

- (void)showNetworkProblemsAlert;

- (void)reachabilityChanged:(NSNotification *)notification;

@end

@implementation FIViewController

@synthesize playImage;
@synthesize playHighlightImage;
@synthesize pauseImage;
@synthesize pauseHighlightImage;

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
  RNLog(@"audioSessionInterruption %d", interruptionState);
  if (interruptionState == kAudioSessionBeginInterruption) {
    RNLog(@"AudioSessionBeginInterruption");
    BOOL playing = isPlaying;
    [self stopRadio];
    OSStatus status = AudioSessionSetActive(false);
    if (status) { RNLog(@"AudioSessionSetActive err %d", status); }
    interruptedDuringPlayback = playing;
  } else if (interruptionState == kAudioSessionEndInterruption) {
    RNLog(@"AudioSessionEndInterruption && interruptedDuringPlayback");
    OSStatus status = AudioSessionSetActive(true);
    if (status != kAudioSessionNoError) { RNLog(@"AudioSessionSetActive err %d", status); }
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
  [alertView release];
}

- (void)stopRadio {
  if (isPlaying) {
    [player stop];
  }
}

- (void)setPlayState {
  controlButton.hidden = NO;
  loadingImage.hidden = YES;
  if (loadingImage.isAnimating)
    [loadingImage startAnimating];
  [controlButton setImage:pauseImage forState:UIControlStateNormal];
  [controlButton setImage:pauseHighlightImage
                 forState:UIControlStateHighlighted];
}

- (void)setStopState {
  controlButton.hidden = NO;
	loadingImage.hidden = YES;
	if (loadingImage.isAnimating)
		[loadingImage stopAnimating];
	[controlButton setImage:playImage forState:UIControlStateNormal];
	[controlButton setImage:playHighlightImage
                 forState:UIControlStateHighlighted];  
}

- (void)setFailedState:(NSError *)error {
  // If we loose network reachability both callbacks will get call, so we
  // step aside if a network lose has happened.
  if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
    // The reachability callback will show its own AlertView.
    return;
  }
  
  controlButton.hidden = NO;
  loadingImage.hidden = YES;
  if (loadingImage.isAnimating)
    [loadingImage stopAnimating];
  [controlButton setImage:playImage forState:UIControlStateNormal];
  [controlButton setImage:playHighlightImage forState:UIControlStateHighlighted];
  
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
  [alertView release];
}

- (void)setLoadingState {
  controlButton.hidden = YES;
  loadingImage.hidden = NO;
  if (!loadingImage.isAnimating)
    [loadingImage startAnimating];
}

- (void)playRadio {
  if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
    [self showNetworkProblemsAlert];
    return;
  }
  
  if (isPlaying) {
    return;
  }
  
  // FIX: trying to play?
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
  
  player = [[ShoutcastPlayer alloc] initWithString:kFIFMRadioURL audioTypeHint:kAudioFileMP3Type];
  // player.connectionFilter = [[FIShoutcastMetadataFilter alloc] init];
  
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
  // Load some interface images
  bottomBar.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"bottom-bar.png"]];
  
  self.playImage = [UIImage imageNamed:@"play.png"];
  self.playHighlightImage = [UIImage imageNamed:@"play-hl.png"];
  self.pauseImage = [UIImage imageNamed:@"pause.png"];
  self.pauseHighlightImage = [UIImage imageNamed:@"pause-hl.png"];
  
  // Load the loading animation files
  NSMutableArray *loadingFiles = [[NSMutableArray alloc] init];
  for (int index = 0; index < 4; index++) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *fileName = [NSString stringWithFormat:@"loading_%d.png", index];
    UIImage *frame = [UIImage imageNamed:fileName];
    [loadingFiles addObject:frame];
    [pool release];
  }
  loadingImage.animationImages = loadingFiles;
  loadingImage.animationDuration = 1.2f;
  [loadingFiles release];
  
  // Set up the volume slider
  MPVolumeView *volumeView =
    [[[MPVolumeView alloc] initWithFrame:volumeViewHolder.bounds] autorelease];
  [volumeViewHolder addSubview:volumeView];
  
  // Find the slider
  volumeSlider = [volumeView valueForKey:@"_volumeSlider"];
  CGRect frame = volumeView.frame;
  frame.size.height = 53;
  volumeSlider.frame = frame;
  
  UIImage *volumeMinimumTrackImage = [[UIImage imageNamed:@"volume-track.png"]
                                      stretchableImageWithLeftCapWidth:38.0
                                                          topCapHeight:0.0];
  UIImage *volumeMaximumTrackImage = [[UIImage imageNamed:@"volume-track.png"]
                                      stretchableImageWithLeftCapWidth:38.0
                                                          topCapHeight:0.0];
  UIImage *volumeThumbImage = [UIImage imageNamed:@"volume-thumb.png"];
  
  [volumeSlider setMinimumTrackImage:volumeMinimumTrackImage
                            forState:UIControlStateNormal];
  [volumeSlider setMaximumTrackImage:volumeMaximumTrackImage
                            forState:UIControlStateNormal];
  [volumeSlider setThumbImage:volumeThumbImage
                     forState:UIControlStateNormal];
  
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
  self.playImage = nil;
  self.playHighlightImage = nil;
  self.pauseImage = nil;
  self.pauseHighlightImage = nil;
  
  [super dealloc];
}


@end
