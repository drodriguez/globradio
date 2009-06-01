//
//  FRRadioTableController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FRRadio;
@protocol FRRadioTableControllerDelegate;

@interface FRRadioTableController : UITableViewController {
 @protected
  NSInteger activeRadio_;
 @protected
  id<FRRadioTableControllerDelegate> delegate_;
}

@property (nonatomic, assign) id delegate;

- (id)init;

@end

@protocol FRRadioTableControllerDelegate

- (BOOL)isPlaying;
- (void)playRadio:(FRRadio *)radio;

@end

