//
//  FRRadioGroupController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioGroupController.h"
#import "FRTableViewItem.h"
#import "FRRadio.h"
#import "FRRadioGroup.h"

#define kTimeout 5.0
#define kSelectionTimeout 2.5

@implementation FRRadioGroupController

@synthesize parentItem = parentItem_;

- (NSMutableArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc]
              initWithArray:[FRTableViewItem findByCriteria:@"WHERE parent=%d ORDER BY position ASC", self.parentItem.pk]];
  }
  
  return items_;
}

- (void)setParentItem:(FRTableViewItem *)newItem {
  if (parentItem_ != newItem) {
    [newItem retain];
    [parentItem_ release];
    parentItem_ = newItem;
    
    [items_ release];
    items_ = nil;
    
    if (parentItem_.radioGroup.selected) {
      FRRadio *selectedRadio = parentItem_.radioGroup.selected;
      FRTableViewItem *selectedTableViewItem = (FRTableViewItem *)
        [FRTableViewItem findFirstByCriteria:@"WHERE radio = 'FRRadio-%d'", selectedRadio.pk];
      activeRadio_ = selectedTableViewItem.position - 1;
    }
  }
}

- (void)timerFired:(NSTimer *)timer {
  [self.navigationController popViewControllerAnimated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView
willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kTimeout];
  // super do not implement it, so leave it commented out
  // return [super tableView:tableView willSelectRowAtIndexPath:indexPath];
  return indexPath;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Lets use a shorter time when a user select a row
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kSelectionTimeout];
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  
  // Update the parent selected field
  FRTableViewItem *item = [self.items objectAtIndex:indexPath.row];
  FRRadioGroup *radioGroup = self.parentItem.radioGroup;
  radioGroup.selected = item.radio;
  [radioGroup save];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kTimeout];
  // super do not implement it, so leave it commented out
  // [super scrollViewDidScroll:scrollView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  if (activeRadio_ != -1) {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:activeRadio_ inSection:0]
     atScrollPosition:UITableViewScrollPositionMiddle
     animated:YES];
  }  
}

- (void)viewDidAppear:(BOOL)animated {
  timeoutTimer_ = [[NSTimer scheduledTimerWithTimeInterval:kTimeout
                                                    target:self
                                                  selector:@selector(timerFired:)
                                                  userInfo:nil
                                                   repeats:NO] retain];
  [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [timeoutTimer_ invalidate];
  [super viewDidDisappear:animated];
}

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

@end
