//
//  FIViewController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ShoutcastAudioClass.h"



@interface FIViewController : UIViewController <ShoutcastPlayerDelegate> {
 @private
  IBOutlet UIButton *controlButton;
  IBOutlet UIView *volumeViewHolder;
  IBOutlet UIImageView *loadingImage;
  IBOutlet UIView *bottomBar;
  IBOutlet UILabel *titleLabel;
  IBOutlet UILabel *artistLabel;
  IBOutlet UIView *albumArtContainer;
  
  UIImage *playImage;
  UIImage *playHighlightImage;
  UIImage *pauseImage;
  UIImage *pauseHighlightImage;
  
  ShoutcastPlayer *player;
  
  BOOL isPlaying;
  BOOL interruptedDuringPlayback;
  
  UISlider *volumeSlider;
}

- (IBAction)controlButtonClicked:(UIButton *)button;

- (void)audioSessionInterruption:(UInt32)interruptionState;

@end
