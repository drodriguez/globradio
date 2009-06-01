//
//  FRTableViewItem.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@class FRRadio;
@class FRRadioGroup;

@interface FRTableViewItem : SQLitePersistentObject {
 @private
  NSUInteger position_;
  NSUInteger parent_;
  BOOL isGroup_;
  FRRadio *radio_;
  FRRadioGroup *radioGroup_;
  
  NSString *name_;
}

@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger parent;
@property (nonatomic, assign) BOOL group;
@property (nonatomic, retain) FRRadio *radio;
@property (nonatomic, retain) FRRadioGroup *radioGroup;

@property (nonatomic, retain, readonly) NSString *name;

@end
