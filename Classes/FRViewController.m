//
//  FRViewController.m
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FRViewController.h"
#import "FRMainRadiosController.h"
#import "FRRadio.h"
#import "RRQAudioPlayer.h"
#import "RRQPLSParser.h"
#import "RRQM3UParser.h"
#import "RRQReachability.h"
#import "RRQVolumeView.h"

/*
 e-mail message string, in french (translated by Google) says:
 
 Si vous le pouvez, s'il vous plaît, éscrivez votre message en anglais ou en espagnol.<br><br>
 S'il vous plaît, inclure dans votre message les informations suivantes:<br>
 1. Qu'est-ce que vous faisiez lorsque le problème s'est produit.<br>
 2. Qu'avez-vous compté se produire.<br>
 3. Qu'est-ce qui s'est réellement passé.<br><br>
 
 which should mean in english:
 
 If you can, please, write your message in english or spanish.<br><br>
 Please, include in your message the following information:<br>
 1. What you were doing when the problem happened.<br>
 2. What you expected to happen.<br>
 3. What actually happened.<br><br>
 */
static NSString *kSupportMailURL =
  @"mailto://support@yoteinvoco.com?"
  "subject=France%20Radio%20Problem&"
  "body=Si%20vous%20le%20pouvez%2C%20s'il%20vous%20pla%C3%AEt%2C%20%C3%A9crivez%20votre%20message%20en%20anglais%20ou%20en%20espagnol.%3Cbr%3E%3Cbr%3E"
  "S'il%20vous%20pla%C3%AEt%2C%20inclure%20dans%20votre%20message%20les%20informations%20suivantes%3A%3Cbr%3E"
  "1.%20Qu'est-ce%20que%20vous%20faisiez%20lorsque%20le%20probl%C3%A8me%20s'est%20produit.%3Cbr%3E"
  "2.%20Qu'avez-vous%20compt%C3%A9%20se%20produire.%3Cbr%3E"
  "3.%20Qu'est-ce%20qui%20s'est%20r%C3%A9ellement%20pass%C3%A9.%3Cbr%3E%3Cbr%3E";

@interface FRViewController ()

@property (nonatomic, retain) UIImage *playImage;
@property (nonatomic, retain) UIImage *playHighlightImage;
@property (nonatomic, retain) UIImage *pauseImage;
@property (nonatomic, retain) UIImage *pauseHighlightImage;
@property (nonatomic, assign, readwrite) BOOL isPlaying;

- (void)stopRadio;

- (void)privatePlayRadio:(FRRadio *)radio;

- (void)showNetworkProblemsAlert;

- (void)animationWillStart:(NSString *)animation context:(void *)context;
- (void)animationDidStop:(NSString *)animation context:(void *)context;

- (void)reachabilityChanged:(NSNotification *)notification;

@end


@implementation FRViewController

@synthesize playImage, playHighlightImage, pauseImage, pauseHighlightImage;
@synthesize isPlaying;
@synthesize activeRadio;

- (IBAction)controlButtonClicked:(UIButton *)button {
	if (isPlaying) {
		[self stopRadio];
	}	else if (activeRadio != nil) {
		[self playRadio:activeRadio];
	}
}

#define SUPPORT_WEB_BUTTON 1001
#define SUPPORT_MAIL_BUTTON 1002
- (IBAction)openInfoURL:(UIButton *)button {
	NSURL *url = nil;
	switch (button.tag) {
		case SUPPORT_WEB_BUTTON: // Web url
			url = [NSURL URLWithString:@"http://apps.yoteinvoco.com/franceradio"];
			break;
		case SUPPORT_MAIL_BUTTON: { // email url
#if defined(DEBUG)
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
      [encodedLog release];
#else
			url = [NSURL URLWithString:kSupportMailURL];
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
		inView = navigationController.view;
		outView = infoView;
	} else {
		inView = infoView;
		outView = navigationController.view;
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
}

- (void)saveApplicationState {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[NSNumber numberWithInt:activeRadio.pk]
	 forKey:@"activeRadio"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)audioSessionInterruption:(UInt32)interruptionState {
	RNLog(@"audioSessionInterruption %d", interruptionState);
	if (interruptionState == kAudioSessionBeginInterruption) {
		RNLog(@"AudioSessionBeginInterruption");
		[self stopRadio];
		OSStatus status = AudioSessionSetActive(false);
		if (status) { RNLog(@"AudioSessionSetActive err %d", status); }
	} else if (interruptionState == kAudioSessionEndInterruption) {
		RNLog(@"AudioSessionEndInterruption && interruptedDuringPlayback");
		OSStatus status = AudioSessionSetActive(true);
		if (status != kAudioSessionNoError) { RNLog(@"AudioSessionSetActive err %d", status); }
	}
}

- (void)animationWillStart:(NSString *)animation context:(void *)context {
	flipping = YES;
}

- (void)animationDidStop:(NSString *)animation context:(void *)context {
	infoViewVisible = !infoViewVisible;
	flipping = NO;
}

- (void)reachabilityChanged:(NSNotification *)notification {
	if ([[RRQReachability sharedReachability] remoteHostStatus] == NotReachable) {
		[self showNetworkProblemsAlert];
	}
}

- (void)showNetworkProblemsAlert {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problèmes de connexion"
														message:@"Impossible de se connecter à l'Internet..\nAssurez-vous que vous êtes connecté à Internet."
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	[alertView show];
  [alertView release];
}


- (NSString *)getRadioURL:(NSString *)radioAddress {
  
	if ([radioAddress rangeOfString:@".pls"].length > 0) {
    RNLog(@"getRadioURL pls radioAddress %@", radioAddress);
		NSURL *plsUrl = [NSURL URLWithString:radioAddress];
		NSString *plsContent = [NSString stringWithContentsOfURL:plsUrl];
	
		NSArray *tracks = [RRQPLSParser parse:plsContent];
		if ([tracks count] > 0) {
			NSString *location = [tracks objectAtIndex:0];
			RNLog(@"getRadioURL location %@", location);
			return location;
		} else {
      // No error here, returning a invalid URL makes the streamer fail
      RNLog(@"Can not extract information from M3U");
      return @"";
		}
	} else if ([radioAddress rangeOfString:@".m3u"].length > 0) {
		RNLog(@"getRadioURL m3u radioAddress %@", radioAddress);
		NSURL *m3UUrl = [NSURL URLWithString:radioAddress];
		NSString *m3UContent = [NSString stringWithContentsOfURL:m3UUrl];
		
		NSArray *tracks = [RRQM3UParser parse:m3UContent];
		if ([tracks count] > 0) {
			NSString *location = [[tracks objectAtIndex:0] objectForKey:@"location"];
			RNLog(@"getRadioURL location %@", location);
			return location;
		} else {
			// No error here, returning a invalid URL makes the streamer fail
			RNLog(@"Can not extract information from M3U");
			return @"";
		}
	} else {
		// No error here, returning a invalid URL makes the streamer fail
		RNLog(@"Radio is not m3u or pls");

		return @"";
	}
	


}

- (void)stopRadio {
	if (isPlaying) {
		[myPlayer stop];
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
	// TODO: [radiosTable reloadData]; ???
	
	NSString *message;
	if (error != nil) {
		message = [NSString stringWithFormat:@"Une erreur s'est produite \"%@\". Désolé.", error.localizedDescription];
	} else {
		message = @"Une erreur s'est produite. Désolé.";
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Problème"
														message:message
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
	[alertView show];
  [alertView release];
}

- (void)setLoadingState {
	controlButton.hidden = YES;
	loadingImage.hidden = NO;
	if (!loadingImage.isAnimating)
		[loadingImage startAnimating];
}

- (void)playRadio:(FRRadio *)radio {
	if ([[RRQReachability sharedReachability] remoteHostStatus] == NotReachable) {
		[self showNetworkProblemsAlert];
		return;
	}
	
  if (!tryingToPlay && !isLoading) {
    tryingToPlay = YES;
    
    if (activeRadio != radio) {
      [radio retain];
      [activeRadio release];
      activeRadio = radio;
    }
    
    [NSThread detachNewThreadSelector:@selector(privatePlayRadio:)
                             toTarget:self
                           withObject:radio];
  }
}

- (void)privatePlayRadio:(FRRadio *)radio {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (isPlaying || isLoading) {
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
	
  NSString *radioAddress = nil;
  if ([[RRQReachability sharedReachability] remoteHostStatus] == ReachableViaWiFiNetwork) {
    radioAddress = radio.highURL;
  } else {
    radioAddress = radio.lowURL;
  }
	NSString *radioURL = [self getRadioURL:radioAddress];

	myPlayer = [[RRQAudioPlayer alloc] initWithString:radioURL audioTypeHint:kAudioFileMP3Type];
	[myPlayer addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
	[myPlayer addObserver:self forKeyPath:@"failed" options:0 context:nil];
	[myPlayer start];
    
	isLoading = YES;
  tryingToPlay = FALSE;
	
	[pool release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (object == myPlayer) {
		if ([keyPath isEqual:@"isPlaying"]) {
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			if ([myPlayer isPlaying]) { // Started playing
        isLoading = NO;
        self.isPlaying = YES;
				[self performSelector:@selector(setPlayState)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
			} else { // Stopped playing
				[myPlayer removeObserver:self forKeyPath:@"isPlaying"];
				[myPlayer removeObserver:self forKeyPath:@"failed"];
				[myPlayer release];
				myPlayer = nil;
				
				pthread_mutex_lock(&stopMutex);
				self.isPlaying = NO;
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
			
			if ([myPlayer failed]) { // Have failed
				RNLog(@"failed!");
				[self performSelector:@selector(setFailedState:)
                     onThread:[NSThread mainThread]
                   withObject:myPlayer.error
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

- (void)viewDidLoad {
	// Load some images
	bgView.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
  bottomBarView.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"bottom-bar.png"]];
	self.playImage = [UIImage imageNamed:@"play.png"];
	self.playHighlightImage = [UIImage imageNamed:@"play-hl.png"];
	self.pauseImage = [UIImage imageNamed:@"pause.png"];
	self.pauseHighlightImage = [UIImage imageNamed:@"pause-hl.png"];
    
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
	RRQVolumeView *volumeView =
    [[[RRQVolumeView alloc] initWithFrame:volumeViewHolder.bounds] autorelease];
	[volumeViewHolder addSubview:volumeView];
  [volumeView finalSetup];
  
	// Initialize mutexes
	pthread_mutex_init(&stopMutex, NULL);
	pthread_cond_init(&stopCondition, NULL);
		
	// Initialize saved values
	NSNumber *activeRadioId =
    [[NSUserDefaults standardUserDefaults] objectForKey:@"activeRadio"];
	if (activeRadioId != nil) {
		activeRadio = (FRRadio *) [FRRadio findByPK:[activeRadioId intValue]];
	} else {
		activeRadio = nil;
  }
  
  navigationController = [[UINavigationController alloc] init];
  navigationController.view.frame = flippableView.bounds;
  navigationController.navigationBarHidden = YES;
  
  FRRadioTableController *radioTableController = [[FRMainRadiosController alloc] init];
  radioTableController.delegate = self;
  [radioTableController setActiveRadioWithRadio:activeRadio];
  [navigationController pushViewController:radioTableController animated:YES];
  [radioTableController release];
  
  [navigationController viewWillAppear:NO];
  [flippableView addSubview:navigationController.view];
  [navigationController viewDidAppear:NO];
	
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	// Needed to start receiving reachibility status notifications
	[[RRQReachability sharedReachability] remoteHostStatus];
    
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
  
  [navigationController release];
  
	[super dealloc];
}

@end
