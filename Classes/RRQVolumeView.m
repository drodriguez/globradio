//
//  RRQVolumeView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 07/04/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RRQVolumeView.h"
#import "RRQNSString+Version.h"
#import "RRQUISlider+Volume.h"

// Avoid warnings about not defined messages.
@interface MPVolumeView (RRQRouteButton)

- (UIButton *)routeButton;

@end



@implementation RRQVolumeView

- (void)layoutSubviews {
  if ([self respondsToSelector:@selector(routeButton)]) {
    [[self routeButton] removeFromSuperview];
    [self setValue:nil forKeyPath:@"_internal._routeButton"];
  }
}

- (UISlider *)volumeSlider {
  // Find the slider
  @try {
    return [self valueForKeyPath:@"_internal._volumeSlider"];
  }
  @catch (NSException *e) {
    if ([[e name] isEqualToString:NSUndefinedKeyException]) {
      return [self valueForKey:@"_volumeSlider"];
    }
    @throw;
  }
  return nil;
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
