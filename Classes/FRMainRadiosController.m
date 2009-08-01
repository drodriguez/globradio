//
//  FRMainRadiosController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRMainRadiosController.h"
#import "FRDirectoryItem.h"

@implementation FRMainRadiosController

- (NSMutableArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc]
              initWithArray:[FRDirectoryItem findByCriteria:@"WHERE parent=0 ORDER BY position ASC"]];
  }
  
  return items_;
}

- (void)viewWillAppear:(BOOL)animated {
  [self.tableView reloadData];
  [super viewWillAppear:animated];
}

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

@end
