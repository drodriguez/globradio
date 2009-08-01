//
//  FRRadio.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadio.h"

static NSString *kTableName = @"radios";

@implementation FRRadio

@synthesize name = name_;
@synthesize lowURL = lowURL_;
@synthesize highURL = highURL_;

- (void)dealloc {
  [name_ release];
  [lowURL_ release];
  [highURL_ release];
  
  [super dealloc];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

@end

@implementation FRRadioBase

- (NSString *)name {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end
