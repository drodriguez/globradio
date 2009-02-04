//
//  RNM3UParser.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 14/11/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RNM3UParser.h"

#ifndef TESTING
NSString *extractLastComponent(NSString *path);
void parseEXTINF
  (NSString *info, NSString **artist, NSString **name, NSInteger *duration);
#endif

NSString *extractLastComponent(NSString *path) {
  NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString:@"\\/"];
  NSRange lastSlash = [path rangeOfCharacterFromSet:cs
                                            options:NSBackwardsSearch];
  int length = [path length];
  NSRange protocolMarker = [path rangeOfString:@"://"];
  int rangeStart;
  int rangeLength;
  
  if (lastSlash.location == 0 && length == 1) { // is root
    rangeStart = 0;
    rangeLength = 1;
  } else if (lastSlash.location+1 == length) { // slash at the end
    lastSlash = [path rangeOfCharacterFromSet:cs
                                      options:NSBackwardsSearch
                                        range:NSMakeRange(0, length-1)];
    if (lastSlash.location == protocolMarker.location + 2) {
      // Check if we are at the protocol marker
      rangeStart = 0;
      rangeLength = length - 1;
    } else {
      rangeStart = lastSlash.location + 1;
      rangeLength = length - lastSlash.location - 2;
    }
  } else if (lastSlash.location == protocolMarker.location + 2) {
    rangeStart = 0;
    rangeLength = length;
  } else if (lastSlash.location == NSNotFound && lastSlash.length == 0) {
    rangeStart = 0;
    rangeLength = length;
  } else {
    rangeStart = lastSlash.location + 1;
    rangeLength = length - lastSlash.location - 1;
  }
    
  return [path substringWithRange:NSMakeRange(rangeStart, rangeLength)];
}

void parseEXTINF
  (NSString *info, NSString **artist, NSString **name, NSInteger *duration) {
    NSArray *tokens = [info componentsSeparatedByString:@","];
    
    if ([tokens count] >= 1) {
      NSScanner *scanner = [NSScanner scannerWithString:[tokens objectAtIndex:0]];
      if ([scanner isAtEnd] == YES || [scanner scanInteger:duration] == NO) {
        *duration = -1;
        return;
      }
    } else {
      return;
    }
    
    if ([tokens count] > 2) { // artist, then name
      *name = [[[tokens objectAtIndex:2]
                stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceCharacterSet]] retain];
      *artist = [[[tokens objectAtIndex:1]
                  stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceCharacterSet]] retain];
    } else if ([tokens count] == 2) { // name (possibly artist)
      NSArray *subtokens = [[tokens objectAtIndex:1] componentsSeparatedByString:@" - "];
      if ([subtokens count] == 2) {
        *name = [[[subtokens objectAtIndex:1]
                  stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceCharacterSet]] retain];
        *artist = [[[subtokens objectAtIndex:0]
                   stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceCharacterSet]] retain];
      } else {
        *name = [[[tokens objectAtIndex:1]
                  stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceCharacterSet]] retain];
      }
    }
}

@implementation RNM3UParser

- (id)init {
  return [self initWithContents:nil];
}

- (id)initWithContents:(NSString *)c {
  self = [super init];
  if (self) {
    [self setContents:c];
  }
  return self;
}

- (void)dealloc {
  [self setContents:nil];
  [super dealloc];
}

+ (NSArray *)parse:(NSString *)c {
  RNM3UParser *parser =
    [[[RNM3UParser alloc] initWithContents:c] autorelease];
  
  return [parser parse];
}

- (NSArray *)parse {
  NSMutableArray *results = [[[NSMutableArray alloc] initWithCapacity:1] autorelease];
  
  NSArray *lines =
    [contents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];

  NSString *name = nil;
  NSString *artist = nil;
  NSString *location = nil;
  NSInteger duration = -1;  
  for (NSString *line in lines) {
    
    if ([line hasPrefix:@"#EXTINF:"]) {
      // Extra information line
      parseEXTINF([line substringFromIndex:8], &artist, &name, &duration);
    } else if ([line hasPrefix:@"#"]) {
      // Comment, do nothing
      continue;
    } else {
      // Normal line
      NSString *cleanLine =
        [line stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
      
      if ([cleanLine length] > 0) {
        if (name == nil) { // use filename as name
          name = extractLastComponent(cleanLine);
        }
        location = cleanLine;
        
        NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                location, @"location",
                                name, @"name",
                                artist, @"artist",
                                duration, @"duration"];
        [results addObject:entry];
        
        // Cleanup
        name = nil;
        artist = nil;
        location = nil;
        duration = -1; 
      }
    }
  }
  
  return results;
}

@synthesize contents;
@end
