//
//  RRQVolumeView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 07/04/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RRQVolumeView.h"
#import "RRQUIView+Description.h"

// Avoid warnings about not defined messages.
@interface MPVolumeView (RRQRouteButton)

- (UIButton *)routeButton;

@end



@implementation RRQVolumeView

- (void)layoutSubviews {
  if (!layoutDone) {
    NSLog(@"layoutSubviews");
    layoutDone = TRUE;
    if ([self respondsToSelector:@selector(routeButton)]) {
      [[self routeButton] removeFromSuperview];
      [self setValue:nil forKeyPath:@"_internal._routeButton"];
    }
  }
}

- (void)setShowsRouteButton:(BOOL)value animated:(BOOL)animated {
  NSLog(@"setShowsRouteButton:%@ animated:%@",
        value ? @"TRUE" : @"FALSE",
        animated ? @"TRUE" : @"FALSE");
  // eat this method call, so the slider do not move
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
}

@end
