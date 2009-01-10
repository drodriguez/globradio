//
//  COPEViewController.m
//  radio3
//
//  Created by Javier Quevedo on 1/8/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "COPEViewController.h"
#import "AudioClass.h"
#import "Reachability.h"


NSString *kFIFMRadioURL = @"http://cope.stream.flumotion.com/cope/copefm.mp3.m3u";

// NSString *kFIFMRadioURL = @"http://scfire-ntc-aa10.stream.aol.com:80/stream/1040";

@interface COPEViewController ()

- (void)stopRadio;

- (void)playRadio;
- (void)privatePlayRadio;

- (void)showNetworkProblemsAlert;

- (void)reachabilityChanged:(NSNotification *)notification;

@end

@implementation COPEViewController

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
	} else if (interruptionState == kAudioSessionEndInterruption) {
		AudioSessionSetActive(YES);
		if (interruptedDuringPlayback)
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
	//player.connectionFilter = [[FIShoutcastMetadataFilter alloc] init];
	
	[player addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
	[player addObserver:self forKeyPath:@"failed" options:0 context:nil];
	[player start];
	
	isPlaying = YES;
	
	[pool release];
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
