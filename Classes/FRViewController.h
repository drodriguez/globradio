//
//  FRViewController.h
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRRadioTableController.h"
#include <pthread.h>

@class RRQAudioPlayer;

@interface FRViewController : UIViewController <FRRadioTableControllerDelegate> {
@private
  UINavigationController *navigationController;
	IBOutlet UIButton *controlButton;
	IBOutlet UIView *volumeViewHolder;
	IBOutlet UIView *flippableView;
	IBOutlet UIImageView *loadingImage;
  IBOutlet UIView *bottomBarView;
  IBOutlet UIView *bgView;
		
	RRQAudioPlayer *myPlayer;
	
	BOOL isPlaying;
	BOOL infoViewVisible;
	BOOL flipping;
  BOOL tryingToPlay;
	
	pthread_mutex_t stopMutex;
	pthread_cond_t stopCondition;
	
	UIImage *playImage;
	UIImage *playHighlightImage;
	UIImage *pauseImage;
	UIImage *pauseHighlightImage;
  
	UIView *infoView;
}

@property (nonatomic, readonly) BOOL isPlaying;

- (IBAction)controlButtonClicked:(UIButton *)button;
- (IBAction)infoButtonClicked:(UIButton *)button;
- (IBAction)openInfoURL:(UIButton *)button;

- (void)saveApplicationState;
- (void)audioSessionInterruption:(UInt32)interruptionState;

@end

