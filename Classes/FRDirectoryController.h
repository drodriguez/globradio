//
//  FRDirectoryController.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FRDirectoryController : UITableViewController {
 @private
  NSArray *items_;
  NSInteger activeRadio_;
  NSInteger groupId_;
}

- (id)initWithGroupId:(NSInteger)groupId;

@end
