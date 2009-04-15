//
//  RRQVolumeView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 07/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RRQVolumeView.h"
#import "RRQNSString+Version.h"
#import "RRQUISlider+Volume.h"

@interface MPVolumeView (RRQRouteButton)

- (UIButton *)routeButton;

@end



@implementation RRQVolumeView

- (void)layoutSubviews {
  if ([[[UIDevice currentDevice] systemVersion] checkVersion:@">=3.0"]) {
    if ([self routeButton]) {
      [[self routeButton] removeFromSuperview];
      [self setValue:nil forKeyPath:@"_internal._routeButton"];
    }
  }
}

- (UISlider *)volumeSlider {
  // Find the slider
  if ([[[UIDevice currentDevice] systemVersion] checkVersion:@">=3.0"]) {
    return [self valueForKeyPath:@"_internal._volumeSlider"];
  } else {
    return [self valueForKeyPath:@"_volumeSlider"];
  }
}

- (void)finalSetup {
  UISlider *slider = [self volumeSlider];
	[slider setMinimumTrackImage:[[UIImage imageNamed:@"volume-track-l.png"]
                                stretchableImageWithLeftCapWidth:38.0
                                topCapHeight:0.0]
                      forState:UIControlStateNormal];
	[slider setMaximumTrackImage:[[UIImage imageNamed:@"volume-track-r.png"]
                                stretchableImageWithLeftCapWidth:2.0
                                topCapHeight:0.0]
                      forState:UIControlStateNormal];
	[slider setThumbImage:[UIImage imageNamed:@"volume-thumb.png"]
               forState:UIControlStateNormal];
  
  slider.frame = self.bounds;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(volumeChanged:) 
                                               name:@"AVSystemController_SystemVolumeDidChangeNotification" 
                                             object:nil];
}

- (void)volumeChanged:(NSNotification *)notify {
	[[self volumeSlider] _updateVolumeFromAVSystemController];
}

@end
