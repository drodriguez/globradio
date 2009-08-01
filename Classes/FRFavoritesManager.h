//
//  FRFavoritesManager.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/08/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FRRadio;

@interface FRFavoritesManager : NSObject {
 @private
  NSMutableArray *items_;
}

@property (nonatomic, retain, readonly) NSArray *items;

- (void)playRadio:(FRRadio *)radio;

@end
