//
//  FRRadioGroup.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioGroup.h"


@implementation FRRadioGroup

@synthesize groupName = groupName_;
@synthesize selected = selected_;

- (NSString *)name {
  if (!name) {
    if (!selected_) {
      name_ = self.selected.name;
    } else {
      name_ = self.groupName;
    }
  }
  
  return name_;
}

- (void)dealloc {
  [groupName_ release];
  [name_ release]
  [selected_ release];
  
  [super dealloc];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

+ (NSArray *)transients {
  return [NSArray arrayWithObject:@"name"];
}

@end
