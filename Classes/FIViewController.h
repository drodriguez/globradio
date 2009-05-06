//
//  FIViewController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RRQShoutcastAudioPlayer.h"
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class FILastFMDataProvider;
@class FIAlbumView;

@interface FIViewController : UIViewController <RRQShoutcastAudioPlayerDelegate> {
 @private
  IBOutlet UIButton *controlButton;
  IBOutlet UIView *volumeViewHolder;
  IBOutlet UIImageView *loadingImage;
  IBOutlet UIView *bottomBar;
  IBOutlet UILabel *titleLabel;
  IBOutlet UILabel *artistLabel;
  IBOutlet FIAlbumView *albumArt;
  
  UIImage *playImage;
  UIImage *playHighlightImage;
  UIImage *pauseImage;
  UIImage *pauseHighlightImage;
  UIImage *albumArtDefaultImage;
  
  RRQShoutcastAudioPlayer *player;
  
  BOOL isPlaying;
  BOOL interruptedDuringPlayback;
  
  FILastFMDataProvider *dataProvider;
}

- (IBAction)controlButtonClicked:(UIButton *)button;

- (void)audioSessionInterruption:(UInt32)interruptionState;

@end
