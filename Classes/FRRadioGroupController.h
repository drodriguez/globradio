//
//  FRRadioGroupController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRRadioTableController.h"

@class FRTableViewItem;
@protocol FRRadioGroupControllerDelegate;

@interface FRRadioGroupController : FRRadioTableController {
 @private
  NSInteger parentId_;
  NSMutableArray *items_;
  NSTimer *timeoutTimer_;
  id<FRRadioGroupControllerDelegate> subdelegate_;
}

@property (nonatomic, assign) NSInteger parentId;
@property (nonatomic, assign) id<FRRadioGroupControllerDelegate> subdelegate;

@end

@protocol FRRadioGroupControllerDelegate

- (void)radioGroupController:(FRRadioGroupController *)radioGroupController
selectedRadioDidChangeForParent:(FRTableViewItem *)parentItem;

@end
