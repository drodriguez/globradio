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

@synthesize parentId = parentId_;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle {
  if (self = [super initWithNibName:nibName bundle:bundle]) {
    // FIXME: This timer should be better in viewWillAppear, but seems not to
    // be fired.
    timeoutTimer_ = [[NSTimer scheduledTimerWithTimeInterval:kTimeout
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:NO] retain];
  }
  
  return self;
}  

- (NSMutableArray *)items {
  if (!items_) {
    items_ = [[NSMutableArray alloc]
              initWithArray:[FRTableViewItem findByCriteria:@"WHERE parent=%d ORDER BY position ASC", parentId_]];
  }
  
  return items_;
}

- (void)setParentId:(NSInteger)parentId {
  [items_ release];
  parentId_ = parentId;
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
  FRTableViewItem *parent = (FRTableViewItem *)[FRTableViewItem findByPK:item.parent];
  FRRadioGroup *radioGroup = parent.radioGroup;
  radioGroup.selected = item.radio;
  [radioGroup save];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kTimeout];
  // super do not implement it, so leave it commented out
  // [super scrollViewDidScroll:scrollView];
}

- (void)dealloc {
  [items_ release];
  
  [super dealloc];
}

@end
