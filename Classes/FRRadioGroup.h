//
//  FRRadioGroup.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"
#import "FRRadio.h"

@interface FRRadioGroup : FRRadioBase {
 @private
  NSString *name_;
}

@property (nonatomic, copy) NSString *name;

@end
