//
//  FRTableViewItem.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 16/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLitePersistentObject.h"
#import "FRRadio.h"

@interface FRDirectoryItem : SQLitePersistentObject {
 @private
  NSUInteger position_;
  NSUInteger parent_;
  id<FRRadio> *radio_;
}

@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger parent;
@property (nonatomic, retain) id<FRRadio> *radio;

@property (nonatomic, retain, readonly) NSString *name;

- (NSArray *)findByParent:(NSInteger)parentId;

@end
