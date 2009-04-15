//
//  COPEViewController.m
//  radio3
//
//  Created by Javier Quevedo on 1/8/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "COPEViewController.h"
#import "RRQAudioPlayer.h"
#import "RRQReachability.h"
#import "RNM3UParser.h"
#import "COPENeedleView.h"

@interface COPEViewController ()

@property (nonatomic, retain) UIImage *playImage;
@property (nonatomic, retain) UIImage *playHighlightImage;
@property (nonatomic, retain) UIImage *pauseImage;
@property (nonatomic, retain) UIImage *pauseHighlightImage;
@property (nonatomic, retain) UIImage *volumeMinimumTrackImage;
@property (nonatomic, retain) UIImage *volumeMaximumTrackImage;
@property (nonatomic, retain) UIImage *volumeThumbImage;

- (void)stopRadio;

- (void)playRadio;
- (void)privatePlayRadio;

- (void)setRadioNameInTitle;

- (void)showNetworkProblemsAlert;

- (void)reachabilityChanged:(NSNotification *)notification;

- (void)needleChangeRadioTo:(NSNumber *)index;

@end

@implementation COPEViewController

@synthesize playImage, playHighlightImage, pauseImage, pauseHighlightImage,
volumeMinimumTrackImage, volumeMaximumTrackImage, volumeThumbImage;

#pragma mark IBActions

- (IBAction)controlButtonClicked:(UIButton *)button {
  if (isPlaying) {
		[self stopRadio];
	} else {
		[self playRadio];
	}
}

#define SUPPORT_WEB_BUTTON 1001
#define SUPPORT_MAIL_BUTTON 1002
- (IBAction)openInfoURL:(UIButton *)button {
  NSURL *url = nil;
  switch (button.tag) {
    case SUPPORT_WEB_BUTTON: // Web url
      url = [NSURL URLWithString:@"http://apps.yoteinvoco.com/"];
      break;
    case SUPPORT_MAIL_BUTTON: { // email url
#if defined(BETA) || defined(DEBUG)
      NSString *log = [NSString stringWithContentsOfFile:
                       [[RRQFileLogger sharedLogger] logFile]];
      NSString *encodedLog = (NSString *)
        CFURLCreateStringByAddingPercentEscapes(NULL,
                                                (CFStringRef)log,
                                                NULL,
                                                (CFStringRef)@";/?:@&=+$,",
                                                kCFStringEncodingUTF8);
      if (encodedLog) {
         url = [NSURL URLWithString:[NSString stringWithFormat:
                                     @"mailto://support@yoteinvoco.com?body=%@",
                                     encodedLog]];
      } else {
         url = [NSURL URLWithString:@"mailto://support@yoteinvoco.com?body=No+es+posible+recuperar+el+log"];
      }
#else
      url = [NSURL URLWithString:@"mailto://support@yoteinvoco.com"];
#endif
    break; }
  }
  
  if (url != nil)
    [[UIApplication sharedApplication] openURL:url];
}
#undef SUPPORT_WEB_BUTTON
#undef SUPPORT_MAIL_BUTTON

- (IBAction)infoButtonClicked:(UIButton *)button {
	if (flipping) {
		return;
	}
	
	UIView *inView, *outView;
	if (infoViewVisible) {
		inView = radiosView;
		outView = infoView;
	} else {
		inView = infoView;
		outView = radiosView;
	}
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
						   forView:flippableView
							 cache:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationWillStartSelector:@selector(animationWillStart:context:)];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:context:)];
	
	[outView removeFromSuperview];
	[flippableView addSubview:inView];
	
	[UIView commitAnimations];
	
#if defined(DEBUG)
	if (!interruptedDuringPlayback)
		[self audioSessionInterruption:kAudioSessionBeginInterruption];
	else
		[self audioSessionInterruption:kAudioSessionEndInterruption];
#endif
}

#define RADIO_COPE 1001
#define RADIO_RNG  1002
- (IBAction)changeRadio:(UIButton *)button {
  int selectedRadio = -1;
  switch (button.tag) {
    case RADIO_COPE:
      selectedRadio = 0;
      break;
    case RADIO_RNG:
      selectedRadio = 1;
      break;
  }
  
  if (activeRadio != selectedRadio || !isPlaying) {
    if (activeRadio != selectedRadio) {
      [needleView switchToRadioIndex:selectedRadio];
    }
    activeRadio = selectedRadio;
    [self playRadio];
  }
}
#undef RADIO_COPE
#undef RADIO_RNG

#pragma mark Custom methods

- (void)audioSessionInterruption:(UInt32)interruptionState {
	if (interruptionState == kAudioSessionBeginInterruption) {
		BOOL playing = isPlaying;
		[self stopRadio];
		AudioSessionSetActive(NO);
		interruptedDuringPlayback = playing;
	} else if (interruptionState == kAudioSessionEndInterruption) {
		AudioSessionSetActive(YES);
		// if (interruptedDuringPlayback)
		//	[self playRadio];
		interruptedDuringPlayback = NO;
	}
}

- (void)saveApplicationState {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[NSNumber numberWithInt:activeRadio]
	 forKey:@"activeRadio"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reachabilityChanged:(NSNotification *)notification {
	if ([[RRQReachability sharedReachability] remoteHostStatus] == NotReachable) {
		[self showNetworkProblemsAlert];
	}
}

- (void)needleChangeRadioTo:(NSNumber *)index {
  if (activeRadio != [index intValue] || !isPlaying) {
    activeRadio = [index intValue];
    [self playRadio];
  }
}

- (void)animationWillStart:(NSString *)animation context:(void *)context {
	flipping = YES;
}

- (void)animationDidStop:(NSString *)animation context:(void *)context {
	infoViewVisible = !infoViewVisible;
	flipping = NO;
}



- (void)showNetworkProblemsAlert {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problemas de conexión"
														message:@"No es posible conectar a Internet.\nAsegurese de disponer de conexión a Internet."
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"Aceptar", nil];
	[alertView show];
}


- (NSString *)getRadioURL:(NSString *)radioAddress {
	RNLog(@"getRadioURL radioAddress %@", radioAddress);
	NSURL *m3UUrl = [[NSURL alloc] initWithString:radioAddress];
	NSString *m3UContent = [NSString stringWithContentsOfURL:m3UUrl];
	
	NSArray *tracks = [RNM3UParser parse:m3UContent];
	if ([tracks count] > 0) {
		NSString *location = [[[tracks objectAtIndex:0] objectForKey:@"location"]
							  retain];
		RNLog(@"getRadioURL location %@", location);
		return location;
	} else {
		// No error here, returning a invalid URL makes the streamer fail
		RNLog(@"Can not extract information from M3U");
		return @"";
	}
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
	[controlButton setImage:playHighlightImage forState:UIControlStateHighlighted];
}

- (void)setFailedState:(NSError *)error {
	// If we loose network reachability both callbacks will get call, so we
	// step aside if a network lose has happened.
	if ([[RRQReachability sharedReachability] remoteHostStatus] == NotReachable) {
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
}

- (void)setLoadingState {
  controlButton.hidden = YES;
  loadingImage.hidden = NO;
  if (!loadingImage.isAnimating)
    [loadingImage startAnimating];
}

- (void)playRadio {
	if ([[RRQReachability sharedReachability] remoteHostStatus] == NotReachable) {
		[self showNetworkProblemsAlert];
		return;
	}
		
	[NSThread detachNewThreadSelector:@selector(privatePlayRadio)
							 toTarget:self
						   withObject:nil];
}

- (void)privatePlayRadio {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
  if (isPlaying) {
    [self stopRadio];
    
    // Wait for stop
    pthread_mutex_lock(&stopMutex);
    while (isPlaying)
      pthread_cond_wait(&stopCondition, &stopMutex);
    pthread_mutex_unlock(&stopMutex);
  }
  
	[self performSelector:@selector(setLoadingState)
				 onThread:[NSThread mainThread]
			   withObject:nil
			waitUntilDone:NO];
	
  [self setRadioNameInTitle];
  NSString *radioAddress = [radiosURLS objectAtIndex:activeRadio];
  NSString *radioURL = [self getRadioURL:radioAddress];
  
	player = [[RRQAudioPlayer alloc] initWithString:radioURL];
	
	[player addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
	[player addObserver:self forKeyPath:@"failed" options:0 context:nil];
	[player start];
	
	isPlaying = YES;
	
	[pool release];
}

- (void)setRadioNameInTitle {
  stationLabel.text = [radiosList objectAtIndex:activeRadio];
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
				
        pthread_mutex_lock(&stopMutex);
				isPlaying = NO;
        pthread_cond_signal(&stopCondition);
        pthread_mutex_unlock(&stopMutex);
				
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
	
	// Load some images
	backgroundView.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
  topBar.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"top-bar.png"]];
  bottomBar.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"bottom-bar.png"]];
  
	self.playImage = [UIImage imageNamed:@"play.png"];
	self.playHighlightImage = [UIImage imageNamed:@"play-hl.png"];
	self.pauseImage = [UIImage imageNamed:@"pause.png"];
	self.pauseHighlightImage = [UIImage imageNamed:@"pause-hl.png"];
	self.volumeMinimumTrackImage = [[UIImage imageNamed:@"volume-track.png"]
									stretchableImageWithLeftCapWidth:38.0
									topCapHeight:0.0];
	self.volumeMaximumTrackImage = [[UIImage imageNamed:@"volume-track.png"]
									stretchableImageWithLeftCapWidth:38.0
									topCapHeight:0.0];
	self.volumeThumbImage = [UIImage imageNamed:@"volume-thumb.png"];
	
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
	
  // Set up slider
	MPVolumeView *volumeView =
    [[[MPVolumeView alloc] initWithFrame:volumeViewHolder.bounds] autorelease];
	// [volumeView sizeToFit];
	[volumeViewHolder addSubview:volumeView];
	
	// Find the slider
	volumeSlider = [volumeView valueForKey:@"_volumeSlider"];
	CGRect frame = volumeView.frame;
	frame.size.height = 53;
	volumeSlider.frame = frame;
	
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
	
	// Loading subviews from the nib files
	NSBundle *mainBundle = [NSBundle mainBundle];
	[mainBundle loadNibNamed:@"InfoView"
					   owner:self
					 options:nil];
	
	[mainBundle loadNibNamed:@"RadiosView"
					   owner:self
					 options:nil];
	[flippableView addSubview:radiosView];
  // Set needle target and action
  [needleView setTarget:self action:@selector(needleChangeRadioTo:)];
	
	// Initialize mutexes
	pthread_mutex_init(&stopMutex, NULL);
	pthread_cond_init(&stopCondition, NULL);
	
	// Initialize radios list
	NSString *radiosFilePath = [mainBundle pathForResource:@"radios"
                                                  ofType:@"plist"];
	NSData *radiosData;
	NSString *error;
	NSPropertyListFormat format;
	NSDictionary *radiosInfo;
	
	radiosData = [NSData dataWithContentsOfFile:radiosFilePath];
	radiosInfo = (NSDictionary *) [NSPropertyListSerialization
								   propertyListFromData:radiosData
								   mutabilityOption:NSPropertyListImmutable
								   format:&format
								   errorDescription:&error];
	
	if (radiosInfo) {
		radiosList = [[radiosInfo objectForKey:@"radioNames"] retain];
		radiosURLS = [[radiosInfo objectForKey:@"radioURLs"] retain];
	} else {
		RNLog(@"Error loading radios information");
		// TODO: show error to user... but it should not happen
	}
	
	// Initialize saved values
	NSNumber *result =
	[[NSUserDefaults standardUserDefaults] objectForKey:@"activeRadio"];
	if (result != nil) {
		activeRadio = [result intValue];
    if (activeRadio != -1)
      [self setRadioNameInTitle];
	} else {
		activeRadio = -1;
  }
  
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	// Needed to start receiving reachability status notifications
	[[RRQReachability sharedReachability] remoteHostStatus];
  
  [needleView showAtRadioIndex:activeRadio];
  
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
	self.volumeMinimumTrackImage = nil;
	self.volumeMaximumTrackImage = nil;
	self.volumeThumbImage = nil;
		
	[infoView release];
	[radiosView release];
	
	[radiosList release];
	[radiosURLS release];
	
	[super dealloc];
}


@end
