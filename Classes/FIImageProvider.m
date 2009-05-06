//
//  FIImageProvider.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 04/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FIImageProvider.h"

static NSDictionary *providers;
static NSInvocation *providerInvocation;

@implementation FIImageProvider

+ (NSURL *)extraLargeImageFrom:(NSURL *)image {
  for (NSString *host in providers) {
    if ([host isEqualToString:[image host]]) {
      providerInvocation.selector = NSSelectorFromString([providers objectForKey:host]);
      [providerInvocation setArgument:&image atIndex:2];
      [providerInvocation invoke];
      NSURL *result;
      [providerInvocation getReturnValue:&result];
      
      return result;
    }
  }
  
  return nil;
}

+ (void)initialize {
  providers = [[NSDictionary alloc] initWithObjectsAndKeys:
               @"extraLargeImageFromLastFM:", @"userserve-ak.last.fm",
               @"extraLargeImageFromAmazon:", @"images.amazon.com",
               nil];
  providerInvocation = [NSInvocation invocationWithMethodSignature:
                        [FIImageProvider methodSignatureForSelector:
                         @selector(extraLargeImageFrom:)]];
  providerInvocation.target = [FIImageProvider class];
}

+ (NSURL *)extraLargeImageFromLastFM:(NSURL *)image {
  NSString *path = image.path;
  NSMutableArray *pathComponents =
    [NSMutableArray arrayWithArray:path.pathComponents];
  if (pathComponents.count == 4) {
    [pathComponents replaceObjectAtIndex:[pathComponents count] - 2
                              withObject:@"_"];
    path = [NSString pathWithComponents:pathComponents];
    image = [[NSURL alloc] initWithScheme:image.scheme
                                     host:image.host
                                     path:path];
    return [image autorelease];
  }
  
  return nil;
}

+ (NSURL *)extraLargeImageFromAmazon:(NSURL *)image {
  NSString *path = image.path;
  NSMutableArray *pathComponents =
  [NSMutableArray arrayWithArray:path.pathComponents];
  if (pathComponents.count == 4) {
    NSString *lastComponent = [pathComponents lastObject];
    if (lastComponent.length == 26) {
      [pathComponents removeLastObject];
      [pathComponents addObject:
       [lastComponent stringByReplacingCharactersInRange:NSMakeRange(14,1)
                                              withString:@"L"]];
      path = [NSString pathWithComponents:pathComponents];
      image = [[NSURL alloc] initWithScheme:image.scheme
                                     host:image.host
                                     path:path];
      return [image autorelease];
    }
  }
  
  return nil;
}

@end
