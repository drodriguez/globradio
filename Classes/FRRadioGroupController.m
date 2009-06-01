//
//  FRRadioGroupController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioGroupController.h"
#import "FRTableViewItem.h"

@implementation FRRadioGroupController

@synthesize parentId = parentId_;

- (NSMutableArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc]
              initWithArray:[FRTableViewItem findByCriteria:@"WHERE parent=%d ORDER BY position ASC", parentId_]];
  }
  
  return items_;
}

- (void)setParentId:(NSInteger)parentId {
  [items_ release];
  parentId_ = parentId;
}

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

@end
