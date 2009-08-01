//
//  FRFavoritesController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FRViewController;

@interface FRFavoritesController : NSObject <UITableViewDataSource, UITableViewDelegate> {
 @private
  FRViewController *parentController_;
  NSArray *items_;
  NSInteger activeRadio_;
}

@property (nonatomic, assign) NSInteger activeRadio;

- (id)initWithParentController:(FRViewController *)parentController;

- (void)addRadio:(FRRadio *)radio;

@end
