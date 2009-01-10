//
//  COPEViewController.h
//  radio3
//
//  Created by Javier Quevedo on 1/8/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class Player;

@interface COPEViewController : UIViewController {
@private
	IBOutlet UIButton *controlButton;
	IBOutlet UIView *volumeViewHolder;
	IBOutlet UIImageView *loadingImage;
	
	Player *player;
	
	BOOL isPlaying;
	BOOL interruptedDuringPlayback;
	
	UIView *volumeSlider;
}

- (IBAction)controlButtonClicked:(UIButton *)button;

- (void)audioSessionInterruption:(UInt32)interruptionState;

@end
