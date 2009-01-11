//
//  COPENeedleView.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 11/01/09.
//  Copyright 2009 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface COPENeedleView : UIView {
 @private
  BOOL isVisible;
  UIImageView *imageView;
  CGPoint startLocation;
  
  id _target;
  SEL _action;
}

- (void)switchToRadioIndex:(int)index;

- (void)showAtRadioIndex:(int)index;

- (void)setTarget:(id)target action:(SEL)action;

@end
