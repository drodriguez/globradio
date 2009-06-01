//
//  FRTableViewItem.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRTableViewItem.h"
#import "FRRadio.h"
#import "FRRadioGroup.h"

static NSString *kTableName = @"table_view_items";

@implementation FRTableViewItem

@synthesize position = position_;
@synthesize parent = parent_;
@synthesize group = isGroup_;
@synthesize radio = radio_;
@synthesize radioGroup = radioGroup_;

- (NSString *)name {
  if (!name_) {
    if (self.group) {
      name_ = self.radioGroup.name;
    } else {
      name_ = self.radio.name;
    }
  }
  
  return name_;
}

- (void)dealloc {
  [name_ release];
  [radio_ release];
  [radioGroup_ release];
  
  [super dealloc];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

+ (NSArray *)indices {
  return [NSArray arrayWithObjects:
          [NSArray arrayWithObject:@"position"],
          [NSArray arrayWithObject:@"parent"],
          nil];
}

+ (NSArray *)transients {
  return [NSArray arrayWithObject:@"name"];
}

@end
