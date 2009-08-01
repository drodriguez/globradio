//
//  FRFavoritesController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRViewController.h"

@interface FRFavoritesController : UITableViewController <FRTableViewController> {
 @private
  NSInteger activeRadio_;
  
  FRViewController *parentController_;
}

@property (nonatomic, assign) NSInteger activeRadio;

@property (nonatomic, assign) FRViewController *parentController;

@end
