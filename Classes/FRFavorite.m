//
//  FRFavorite.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRFavorite.h"
#import "FRRadio.h"

static NSString *kTableName = @"favorites";

@implementation FRFavorite

@synthesize position = position_;
@synthesize lastUsedAt = lastUsedAt_;
@synthesize radio = radio_;

- (NSString *)name {
  return [self.radio name];
}

- (void)dealloc {
  [lastUsedAt_ release];
  [radio_ release];
  
  [super dealloc];
}

+ (FRFavorite *)findFirstLeastRecentlyUsed {
  return (FRFavorite *)[self findFirstByCriteria:@"ORDER BY \"last_used_at\" DESC"]; 
}

+ (NSArray *)allByPosition {
  return [self findByCriteria:@"ORDER BY \"position\" DESC"];
}

#pragma mark SQLitePersistentObject private methods

+ (NSString *)tableName {
  return kTableName;
}

+ (NSArray *)indices {
  return [NSArray arrayWithObjects:
          [NSArray arrayWithObject:@"parent"],
          nil];
}

+ (NSArray *)transients {
  return [NSArray arrayWithObject:@"name"];
}

@end
