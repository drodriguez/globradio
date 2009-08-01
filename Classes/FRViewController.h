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
@class FRRadio;
@class FRFavoritesManager;

@interface FRViewController : UIViewController <UINavigationControllerDelegate> {
@private
  UINavigationController *navigationController;
	IBOutlet UIButton *controlButton;
	IBOutlet UIView *volumeViewHolder;
	IBOutlet UIView *flippableView;
	IBOutlet UIImageView *loadingImage;
  IBOutlet UIView *bottomBarView;
  IBOutlet UIView *bgView;
  IBOutlet UIView *infoView;
		
	RRQAudioPlayer *myPlayer;
	
	BOOL internalPlaying;
  BOOL isReallyPlaying;
	BOOL infoViewVisible;
	BOOL flipping;
  BOOL tryingToPlay;
	
	pthread_mutex_t stopMutex;
	pthread_cond_t stopCondition;
	
	UIImage *playImage;
	UIImage *playHighlightImage;
	UIImage *pauseImage;
	UIImage *pauseHighlightImage;
    
  FRRadio *activeRadio;
  FRFavoritesManager *favoritesManager;
}

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, retain, readonly) FRRadio *activeRadio;
@property (nonatomic, retain, readonly) FRFavoritesManager *favoritesManager;

- (void)playRadio:(FRRadio *)radio;
- (IBAction)controlButtonClicked:(UIButton *)button;
- (IBAction)infoButtonClicked:(UIButton *)button;
- (IBAction)openInfoURL:(UIButton *)button;

- (void)saveApplicationState;
- (void)audioSessionInterruption:(UInt32)interruptionState;

@end

@protocol FRTableViewController



@end