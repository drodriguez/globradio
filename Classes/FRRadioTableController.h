//
//  FRRadioTableController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FRRadio;
@class FRRadioGroupControllerDelegate;
@protocol FRRadioTableControllerDelegate;

@interface FRRadioTableController : UITableViewController {
 @private
  FRRadioGroupControllerDelegate *helperDelegate_;
 @protected
  NSInteger activeRadio_;
  NSObject<FRRadioTableControllerDelegate> *delegate_;
}

@property (nonatomic, assign) NSObject<FRRadioTableControllerDelegate> *delegate;
@property (nonatomic, assign) NSInteger activeRadio;

- (id)init;

- (void)setActiveRadioWithRadio:(FRRadio *)radio;

@end

@protocol FRRadioTableControllerDelegate

- (BOOL)isPlaying;
- (FRRadio *)activeRadio;
- (void)playRadio:(FRRadio *)radio;

@end

