//
//  FRRadioGroup.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@class FRRadio;

@interface FRRadioGroup : SQLitePersistentObject {
 @private
  NSString *groupName_;
  FRRadio *selected_;
}

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, retain) FRRadio *selected;

@property (nonatomic, retain, readonly) NSString *name;

@end
