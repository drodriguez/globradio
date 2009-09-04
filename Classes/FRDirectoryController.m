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

static const float kTimeout = 5.0;
static const float kSelectionTimeout = 2.5;

static UIImage *soundOff;
static UIImage *soundOn;
static UIImageView *whiteDisclosure;

@interface FRDirectoryController ()

@property (nonatomic, retain, readonly) NSArray *items;
@property (nonatomic, retain, readonly) NSTimer *timeoutTimer;

@end

@interface FRRadioBase (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath;

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@implementation FRDirectoryController

@synthesize activeRadio = activeRadio_;
@synthesize parentController = parentController_;
@synthesize timeoutTimer = timeoutTimer_;

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

- (void)dealloc {
  [timeoutTimer_ release];
  
  [super dealloc];
}

#pragma mark UIViewController methods

- (void)viewDidAppear:(BOOL)animated {
  timeoutTimer_ = [[NSTimer scheduledTimerWithTimeInterval:kTimeout
                                                    target:self
                                                  selector:@selector(timerFired:)
                                                  userInfo:nil
                                                   repeats:NO] retain];
  [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [timeoutTimer_ invalidate];
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

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kTimeout];
  return indexPath;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  
  [item.radio controller:self
   tableView:tableView
   didSelectRowAtIndexPath:indexPath];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  timeoutTimer_.fireDate = [NSDate dateWithTimeIntervalSinceNow:kTimeout];
}

#pragma mark Private methods

- (NSArray *)items {
  if (!items_) {
    items_ = [[FRDirectoryItem findByParent:groupId_] retain];
  }
  
  return items_;
}

- (void)timerFired:(NSTimer *)timer {
  [self.navigationController popToRootViewControllerAnimated:YES];
}

@end

@implementation FRRadio (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath {
  cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // TODO
  controller.timeoutTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:kSelectionTimeout];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

@implementation FRRadioGroup (FRDirectoryControllerBehaviour)

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
  accessoryForCell:(UITableViewCell *)cell
       atIndexPath:(NSIndexPath *)indexPath {
  cell.accessoryView = whiteDisclosure;
}

- (void)controller:(FRDirectoryController *)controller
         tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [controller.timeoutTimer invalidate];
  FRDirectoryItem *item = [[controller items] objectAtIndex:indexPath.row];
  FRDirectoryController *subcontroller = [[FRDirectoryController alloc] initWithGroupId:item.pk];
  [controller.navigationController pushViewController:subcontroller animated:YES];
  [subcontroller release];
}

@end
