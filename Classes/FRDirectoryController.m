//
//  FRDirectoryController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRDirectoryController.h"

enum FRDirectorySections {
  FRDirectorySection,
  FRDirectorySectionsNumber
};

static UIImage *soundOff;
static UIImage *soundOn;

@interface FRDirectoryController ()

- (NSArray *)items;

@end


@implementation FRDirectoryController

@synthesize activeRadio = activeRadio_;

+ (void)initialize {
  soundOn = [UIImage imageNamed:@"altavoz-on.png"];
  soundOff = [UIImage imageNamed:@"altavoz.png"];
}

- (id)initWithGroupId:(NSInteger)groupId {
  if (self = [super init]) {
    activeRadio_ = -1;
    groupId_ = groupId;
  }
  
  return self;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return FRDirectorySectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case FRDirectorySection:
      return self.items.count;
    default:
      return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *kDirectoryCell = @"DirectoryCell";
  
  RRQTransparentGradientCell *cell = (RRQTransparentGradientCell *)
    [tableView dequeueReusableCellWithIdentifier:kDirectoryCell];
  if (cell == nil) {
    cell = [[[RRQTransparentGradientCell alloc]
             initWithFrame:CGRectZero
             reuseIdentifier:kDirectoryCell] autorelease];
  }
  
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  cell.text = item.radio.name;
  cell.accessoryType = [item.radio controller:self
                        tableView:tableView
                        accessoryTypeForCellAtIndexPath:indexPath];
  
  if (activeRadio_ == indexPath.row) {
    cell.image = soundOn;
  } else {
    cell.image = nil;
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  
  [item.radio controller:self
   tableView:tableView
   didSelectRowAtIndexPath:indexPath];
}

#pragma mark Private methods

- (NSArray *)items {
  if (!items_) {
    items_ = [FRDirectoryItem findByParent:groupId_];
  }
  
  return items_;
}

@end
