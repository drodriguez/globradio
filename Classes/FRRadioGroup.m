//
//  FRRadioGroup.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioGroup.h"
#import "FRRadio.h"

static NSString *kTableName = @"radio_groups";

@implementation FRRadioGroup

@synthesize name = name_;

- (void)dealloc {
  [name_ release];
  
  [super dealloc];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

@end
