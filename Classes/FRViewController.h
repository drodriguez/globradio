//
//  FRViewController.h
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <pthread.h>

@class Player;

@interface FRViewController : UIViewController < UITableViewDelegate , UITableViewDataSource >{
@private
	IBOutlet UITableView *radiosTable;
	IBOutlet UIButton *controlButton;
	IBOutlet UIView *volumeViewHolder;
	IBOutlet UIView *flippableView;
	IBOutlet UIImageView *loadingImage;
  IBOutlet UIView *bottomBarView;
  IBOutlet UIView *bgView;
	
	NSInteger activeRadio;
	NSArray *radiosList;
	NSArray *highRadiosURLS;
  NSArray *lowRadiosURLS;
	
	Player *myPlayer;
	
	BOOL isPlaying;
	BOOL infoViewVisible;
	BOOL flipping;
  BOOL tryingToPlay;
	BOOL interruptedDuringPlayback;
	
	pthread_mutex_t stopMutex;
	pthread_cond_t stopCondition;
	
	UIImage *playImage;
	UIImage *playHighlightImage;
	UIImage *pauseImage;
	UIImage *pauseHighlightImage;
	
	UIImageView *soundOnView;
	UIImageView *soundOffView;
	
	UIView *infoView;
	UIView *radiosView;
}

- (IBAction)controlButtonClicked:(UIButton *)button;
- (IBAction)infoButtonClicked:(UIButton *)button;
- (IBAction)openInfoURL:(UIButton *)button;

- (void)saveApplicationState;
- (void)audioSessionInterruption:(UInt32)interruptionState;

@end

