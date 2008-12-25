//
//  FIViewController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class Player;

@interface FIViewController : UIViewController {
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
