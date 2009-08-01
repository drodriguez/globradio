//
//  FRFavorite.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@class FRRadio;

@interface FRFavorite : SQLitePersistentObject {
 @private
  NSUInteger position_;
  NSDate *lastUsedAt_;
  FRRadio *radio_;
}

@property (nonatomic, assign) NSUInteger *position;
@property (nonatomic, retain) NSDate *lastUsedAt;
@property (nonatomic, retain) FRRadio *radio;

@property (nonatomic, retain, readonly) NSString *name;

- (FRFavorite *)findLeastRecentlyUsed;

- (NSArray *)allByPosition;

@end
