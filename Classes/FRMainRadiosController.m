//
//  FRMainRadiosController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRMainRadiosController.h"
#import "FRTableViewItem.h"

@implementation FRMainRadiosController

- (NSMutableArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc]
              initWithArray:[FRTableViewItem findByCriteria:@"WHERE parent=0 ORDER BY position ASC"]];
  }
  
  return items_;
}

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

@end
