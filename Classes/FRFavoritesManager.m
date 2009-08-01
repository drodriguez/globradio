//
//  FRFavoritesManager.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/08/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRFavoritesManager.h"
#import "FRRadio.h"
#import "FRFavorite.h"


@implementation FRFavoritesManager

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

- (NSArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc] initWithArray:[FRFavorite allByPosition]];
  }
  
  return items_;
}

- (void)playRadio:(FRRadio *)radio {
  
}

@end
