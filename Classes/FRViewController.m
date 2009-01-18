//
//  FRViewController.m
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FRViewController.h"
#import "AudioClass.h"
#import "PLSParser.h"
#import "Reachability.h"
#import <MediaPlayer/MediaPlayer.h>

enum RNSections {
	RNRadioSection,
	RN_NUM_SECTIONS
};



@interface FRViewController ()

@property (nonatomic, retain) UIImage *playImage;
@property (nonatomic, retain) UIImage *playHighlightImage;
@property (nonatomic, retain) UIImage *pauseImage;
@property (nonatomic, retain) UIImage *pauseHighlightImage;
@property (nonatomic, retain) UIImage *rowBackgroundImage;
@property (nonatomic, retain) UIImage *volumeMinimumTrackImage;
@property (nonatomic, retain) UIImage *volumeMaximumTrackImage;
@property (nonatomic, retain) UIImage *volumeThumbImage;

- (void)stopRadio;

- (void)playRadio;
- (void)privatePlayRadio;

- (void)showNetworkProblemsAlert;

- (void)animationWillStart:(NSString *)animation context:(void *)context;
- (void)animationDidStop:(NSString *)animation context:(void *)context;

- (void)reachabilityChanged:(NSNotification *)notification;

@end


@implementation FRViewController

@synthesize playImage, playHighlightImage, pauseImage, pauseHighlightImage,
rowBackgroundImage, volumeMinimumTrackImage,
volumeMaximumTrackImage, volumeThumbImage;


- (void)volumeChanged:(NSNotification *)notify {
	[volumeSlider _updateVolumeFromAVSystemController];
}

- (IBAction)controlButtonClicked:(UIButton *)button {
	if (isPlaying) {
		[self stopRadio];
	}	else if (activeRadio != -1) {
		[self playRadio];
	}
}

#define SUPPORT_WEB_BUTTON 1001
#define SUPPORT_MAIL_BUTTON 1002
- (IBAction)openInfoURL:(UIButton *)button {
	NSURL *url = nil;
	switch (button.tag) {
		case SUPPORT_WEB_BUTTON: // Web url
			url = [NSURL URLWithString:@"http://rneradio.yoteinvoco.com/"];
			break;
		case SUPPORT_MAIL_BUTTON: { // email url
			/*#if defined(BETA) || defined(DEBUG)
			 NSString *log = [NSString stringWithContentsOfFile:
			 [[RNFileLogger sharedLogger] logFile]];
			 NSString *encodedLog = (NSString *)
			 CFURLCreateStringByAddingPercentEscapes(NULL,
			 (CFStringRef)log,
			 NULL,
			 (CFStringRef)@";/?:@&=+$,",
			 kCFStringEncodingUTF8);
			 if (encodedLog)
			 url = [NSURL URLWithString:[NSString stringWithFormat:
			 @"mailto://support@yoteinvoco.com?body=%@",
			 encodedLog]];
			 else
			 url = [NSURL URLWithString:@"mailto://support@yoteinvoco.com?body=No+es+posible+recuperar+el+log"];
			 #else*/
			url = [NSURL URLWithString:@"mailto://support@yoteinvoco.com"];
			//#endif
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

- (void)saveApplicationState {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[NSNumber numberWithInt:activeRadio]
	 forKey:@"activeRadio"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

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
		// if (interruptedDuringPlayback)
		// [self playRadio];
		interruptedDuringPlayback = NO;
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


- (NSString *)getRadioURL:(NSString *)radioAddress {
	RNLog(@"getRadioURL radioAddress %@", radioAddress);
	NSURL *plsUrl = [[NSURL alloc] initWithString:radioAddress];
	NSString *plsContent = [NSString stringWithContentsOfURL:plsUrl];
	
	NSArray *tracks = [PLSParser parse:plsContent];
	
	if ([tracks count] > 0) {
		
		NSString *location = [[tracks objectAtIndex:0]
							  retain];
		RNLog(@"getRadioURL location %@", location);
		return location;
	}
	else
	{
		// No error here, returning a invalid URL makes the streamer fail
		RNLog(@"Can not extract information from M3U");
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
	[radiosTable reloadData];
}

- (void)setStopState {
	controlButton.hidden = NO;
	loadingImage.hidden = YES;
	if (loadingImage.isAnimating)
		[loadingImage stopAnimating];
	[controlButton setImage:playImage forState:UIControlStateNormal];
	[controlButton setImage:playHighlightImage forState:UIControlStateHighlighted];
	[radiosTable reloadData];
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
	[radiosTable reloadData];
	
	NSString *message;
	if (error != nil) {
		message = [NSString stringWithFormat:@"Ha sucedido un error \"%@\". Lo sentimos mucho.", error.localizedDescription];
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
	if ([[Reachability sharedReachability] remoteHostStatus] == NotReachable) {
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
	
	NSString *radioAddress = [radiosURLS objectAtIndex:activeRadio];
	NSString *radioURL = [self getRadioURL:radioAddress];
	

	myPlayer = [[Player alloc] initWithString:radioURL audioTypeHint:kAudioFileMP3Type];
	[myPlayer addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
	[myPlayer addObserver:self forKeyPath:@"failed" options:0 context:nil];
	[myPlayer start];
    
	isPlaying = YES;
	
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
				// [myPlayer setGain:[volumeSlider value]];
				
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	
	return 270/5;
	
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return RN_NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case RNRadioSection:
			return [radiosList count];
		default:
			return 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc]
				 initWithFrame:CGRectZero
				 reuseIdentifier:CellIdentifier] autorelease];
		cell.textAlignment = UITextAlignmentCenter;
		cell.textColor = [UIColor whiteColor];
		cell.indentationLevel = 1;    
		
		UIView *backgroundView =
		[[UIView alloc] initWithFrame:cell.bounds];
		backgroundView.backgroundColor =
		[UIColor colorWithPatternImage:rowBackgroundImage];
		backgroundView.opaque = NO;
		cell.backgroundView = backgroundView;
		[backgroundView release];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	cell.text = [radiosList objectAtIndex:indexPath.row];
	
	if (activeRadio == indexPath.row) {
		if (isPlaying)
			[cell setAccessoryView:soundOnView];
		else
			[cell setAccessoryView:soundOffView];
	} else {
		[cell setAccessoryView:nil];
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (activeRadio != indexPath.row || !isPlaying) {
		if (activeRadio != -1) {
			[[tableView cellForRowAtIndexPath:
			  [NSIndexPath indexPathForRow:activeRadio inSection:0]]
			 setAccessoryView:nil];
		}
		[[tableView cellForRowAtIndexPath:indexPath] setAccessoryView:soundOffView];
		activeRadio = indexPath.row;
		[self playRadio];
	}
}



- (void)viewDidLoad {
	// Load some images
	self.view.backgroundColor =
    [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	self.playImage = [UIImage imageNamed:@"play.png"];
	self.playHighlightImage = [UIImage imageNamed:@"play-hl.png"];
	self.pauseImage = [UIImage imageNamed:@"pause.png"];
	self.pauseHighlightImage = [UIImage imageNamed:@"pause-hl.png"];
	self.rowBackgroundImage = [UIImage imageNamed:@"rowBackground.png"];
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
	
	// Build accessory views
	soundOnView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"altavoz-on.png"]];
	soundOffView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"altavoz.png"]];
	/*
	 accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 37, 33)];
	 accessoryView.backgroundColor = self.soundOffColor;
	 accessoryView.opaque = NO;
	 */
	
	// Set up slider
	MPVolumeView *volumeView =
    [[[MPVolumeView alloc] initWithFrame:volumeViewHolder.bounds] autorelease];
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
	} else
		activeRadio = -1;
	
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	// Needed to start receiving reachibility status notifications
	[[Reachability sharedReachability] remoteHostStatus];
	
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
	self.rowBackgroundImage = nil;
	self.volumeMinimumTrackImage = nil;
	self.volumeMaximumTrackImage = nil;
	self.volumeThumbImage = nil;
	
	[soundOnView release];
	[soundOffView release];
	
	[infoView release];
	[radiosView release];
	
	[radiosList release];
	[radiosURLS release];
  	
	[super dealloc];
}

@end
