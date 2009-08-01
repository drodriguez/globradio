//
//  FRDirectoryController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRDirectoryController.h"
#import "FRDirectoryItem.h"
#import "FRRadio.h"
#import "FRRadioGroup.h"
#import "RRQTransparentGradientCell.h"

enum FRDirectorySections {
  FRDirectorySection,
  FRDirectorySectionsNumber
};

static UIImage *soundOff;
static UIImage *soundOn;
static UIImageView *whiteDisclosure;

@interface FRDirectoryController ()

- (NSArray *)items;

@end

@interface FRRadioBase (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)
       atIndexPath:(NSIndexPath *)indexPath;

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@implementation FRDirectoryController

@synthesize activeRadio = activeRadio_;
@synthesize parentController = parentController_;

+ (void)initialize {
  soundOn = [UIImage imageNamed:@"altavoz-on.png"];
  soundOff = [UIImage imageNamed:@"altavoz.png"];
  whiteDisclosure = [[UIImageView alloc] initWithImage:
                     [UIImage imageNamed:@"white-disclosure.png"]];
}

- (id)initWithGroupId:(NSInteger)groupId {
  if (self = [super initWithNibName:@"RadiosView" bundle:nil]) {
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
  cell.text = item.name;
  [item.radio controller:self
               tableView:tableView
        accessoryForCell:cell
             atIndexPath:indexPath];
  
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

@implementation FRRadio (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath {
  cell.accessoryType = UITableViewCellAccessoryNone;
}

@end

@implementation FRRadioGroup (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath {
  cell.accessoryView = whiteDisclosure;
}

@end
