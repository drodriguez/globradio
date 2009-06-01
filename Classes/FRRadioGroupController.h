//
//  FRRadioGroupController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRRadioTableController.h"

@interface FRRadioGroupController : FRRadioTableController {
 @private
  NSInteger parentId_;
  NSMutableArray *items_;
}

@property (nonatomic, assign) NSInteger parentId;

@end
