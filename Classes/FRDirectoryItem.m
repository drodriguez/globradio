//
//  FRTableViewItem.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRDirectoryItem.h"
#import "FRRadio.h"
#import "FRRadioGroup.h"

static NSString *kTableName = @"table_view_items";

@implementation FRDirectoryItem

@synthesize position = position_;
@synthesize parent = parent_;
@synthesize radio = radio_;

- (NSString *)name {
  return [self.radio name];
}

- (void)dealloc {
  [radio_ release];
  
  [super dealloc];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

+ (NSArray *)indices {
  return [NSArray arrayWithObjects:
          [NSArray arrayWithObjects:@"parent", @"position", nil],
          [NSArray arrayWithObject:@"parent"],
          nil];
}

+ (NSArray *)transients {
  return [NSArray arrayWithObject:@"name"];
}

@end
