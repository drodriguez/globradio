//
//  FRDirectoryController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRViewController.h"

@interface FRDirectoryController : UITableViewController <FRTableViewController> {
 @private
  NSArray *items_;
  NSInteger activeRadio_;
  NSInteger groupId_;
  
  FRViewController *parentController_;
  
  NSTimer *timeoutTimer_;
}

@property (nonatomic, assign) NSInteger activeRadio;

@property (nonatomic, assign) FRViewController *parentController;

- (id)initWithGroupId:(NSInteger)groupId;

@end
