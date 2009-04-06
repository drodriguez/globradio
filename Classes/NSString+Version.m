//
//  NSString+Version.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 06/04/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "NSString+Version.h"

#ifdef TESTING
#  define STATIC_MODIFIER
#else
#  define STATIC_MODIFIER static
#endif


typedef BOOL (comparation_func)(NSMutableArray *a1, NSMutableArray *a2);

STATIC_MODIFIER void normalizeVersion(NSMutableArray *version) {
  if ([version count] == 1) {
    return;
  }
  
  while ([version count] > 0 && [[version lastObject] intValue] == 0) {
    [version removeLastObject];
  }
  
  if ([version count] == 0) {
    [version addObject:@"0"];
  }
}

STATIC_MODIFIER int compareVersions(NSArray *a1, NSArray *a2) {
  int l1 = [a1 count];
  int l2 = [a2 count];
  int len = MIN(l1, l2);
  
  for(int idx = 0; idx < len; idx++) {
    int v1 = [[a1 objectAtIndex:idx] intValue];
    int v2 = [[a2 objectAtIndex:idx] intValue];
    
    if (v1 > v2) {
      return 1;
    } else if (v1 < v2) {
      return -1;
    }
  }
  
  if (l1 == l2) {
    return 0;
  } else {
    return l1 == len ? -1 : 1;
  }
}

STATIC_MODIFIER BOOL versionEquals(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) == 0;
}

STATIC_MODIFIER BOOL versionDifferent(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) != 0;
}

STATIC_MODIFIER BOOL versionGreaterOrEquals(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) >= 0;
}

STATIC_MODIFIER BOOL versionLowerOrEquals(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) <= 0;
}

STATIC_MODIFIER BOOL versionGreater(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) > 0;
}

STATIC_MODIFIER BOOL versionLower(NSMutableArray *a1, NSMutableArray *a2) {
  return compareVersions(a1, a2) < 0;
}

STATIC_MODIFIER BOOL versionCompatible(NSMutableArray *a1, NSMutableArray *a2) {
  NSMutableArray *a3 = [NSMutableArray arrayWithArray:a2];
  if ([a3 count] > 1) {
    [a3 removeLastObject];
  }
  int newNumber = [[a3 lastObject] intValue]+1;
  [a3 removeLastObject];
  [a3 addObject:[NSString stringWithFormat:@"%d", newNumber]];
  
  return compareVersions(a1, a2) >= 0 && compareVersions(a1, a3) < 0;
}

@implementation NSString (Version)

- (BOOL)checkVersion:(NSString *)version {
  int startIndex;
  comparation_func *op;
  if ([version hasPrefix:@"="]) {
    startIndex = 1;
    op = versionEquals;
  } else if ([version hasPrefix:@"!="]) {
    startIndex = 2;
    op = versionDifferent;
  } else if ([version hasPrefix:@">="]) {
    startIndex = 2;
    op = versionGreaterOrEquals;
  } else if ([version hasPrefix:@"<="]) {
    startIndex = 2;
    op = versionLowerOrEquals;
  } else if ([version hasPrefix:@">"]) {
    startIndex = 1;
    op = versionGreater;
  } else if ([version hasPrefix:@"<"]) {
    startIndex = 1;
    op = versionLower;
  } else if ([version hasPrefix:@"~>"]) {
    startIndex = 2;
    op = versionCompatible;
  } else {
    startIndex = 0;
    op = versionEquals;
  }
  
  NSMutableArray *components = [NSMutableArray arrayWithCapacity:3];
  [components addObjectsFromArray:[self componentsSeparatedByString:@"."]];
  NSMutableArray *others = [NSMutableArray arrayWithCapacity:3];
  [others addObjectsFromArray:[[[version substringFromIndex:startIndex]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                               componentsSeparatedByString:@"."]];  
  normalizeVersion(components);
  normalizeVersion(others);
                            
  return op(components, others);
}

@end
