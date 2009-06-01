//
//  FRRadio.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"

@interface FRRadio : SQLitePersistentObject {
 @private
  NSString *name_;
  NSString *lowURL_;
  NSString *highURL_;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *lowURL;
@property (nonatomic, copy) NSString *highURL;

@end
