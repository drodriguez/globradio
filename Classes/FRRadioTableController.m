//
//  FRRadioTableController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioTableController.h"
#import "FRDirectoryItem.h"
#import "FRRadioGroup.h"
#import "FRRadioGroupController.h"
#import "RRQTransparentGradientCell.h"

enum FRSections {
	FRRadioSection,
	FR_NUM_SECTIONS
};

static UIImage *soundOff;
static UIImage *soundOn;



@interface FRRadioTableController ()

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) FRRadioGroupControllerDelegate *helperDelegate;

@end



// Private class for the RadioGroupController delegate
@interface FRRadioGroupControllerDelegate : NSObject <FRRadioTableControllerDelegate> {
 @private
  FRRadioTableController *parentController_;
  FRDirectoryItem *tableViewItem_;
}

@property (nonatomic, retain) FRRadioTableController *parentController;
@property (nonatomic, retain) FRDirectoryItem *tableViewItem;

- (id)initWithController:(FRRadioTableController *)parentController;

@end

@implementation FRRadioGroupControllerDelegate

@synthesize parentController = parentController_;
@synthesize tableViewItem = tableViewItem_;

- (id)initWithController:(FRRadioTableController *)parentController {
  if (self = [super init]) {
    parentController_ = [parentController retain];
    
    [parentController_.delegate addObserver:self
                                 forKeyPath:@"isPlaying"
                                     options:0
                                     context:nil];
  }
  
  return self;
}

- (BOOL)isPlaying {
  return [parentController_.delegate isPlaying];
}

- (void)playRadio:(FRRadio *)radio {
  parentController_.activeRadio = tableViewItem_.position - 1;
  [parentController_.delegate playRadio:radio];
}

- (FRRadio *)activeRadio {
  return [parentController_.delegate activeRadio];
}

- (void)dealloc {
  [parentController_.delegate removeObserver:self forKeyPath:@"isPlaying"];
  [parentController_ release];
  [tableViewItem_ release];
  
  [super dealloc];
}

#pragma mark NSKeyValueObserving methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == parentController_.delegate) {
    if ([keyPath isEqualToString:@"isPlaying"]) {
      // Simulate that the underlaying value is changing.
      [self willChangeValueForKey:@"isPlaying"];
      [self didChangeValueForKey:@"isPlaying"];
      return;
    }
  }
  
  [super observeValueForKeyPath:keyPath
                       ofObject:object
                         change:change
                        context:context];
}

@end



@implementation FRRadioTableController

@dynamic items;
@synthesize delegate = delegate_;
@synthesize activeRadio = activeRadio_;
@synthesize helperDelegate = helperDelegate_;

+ (void)initialize {
  soundOn = [UIImage imageNamed:@"altavoz-on.png"];
  soundOff = [UIImage imageNamed:@"altavoz.png"];
}

- (id)init {
  if (self = [super initWithNibName:@"RadiosView" bundle:nil]) {
    activeRadio_ = -1;
  }
  
  return self;
}

- (void)setDelegate:(NSObject<FRRadioTableControllerDelegate> *)newDelegate {
  if (delegate_ != newDelegate) {
    if (delegate_ != nil) {
      [delegate_ removeObserver:self forKeyPath:@"isPlaying"];
    }
    delegate_ = newDelegate;
    [delegate_ addObserver:self
                forKeyPath:@"isPlaying"
                   options:0
                   context:nil];
  }
}

- (void)setActiveRadioWithRadio:(FRRadio *)radio {
  if (radio) {
    for(FRDirectoryItem *item in self.items) {
      if (item.finalRadio == radio) {
        activeRadio_ = item.position - 1;
        return;
      }
    }
  }
  
  activeRadio_ = -1;
}

- (FRRadioGroupControllerDelegate *)helperDelegate {
  if (!helperDelegate_) {
    helperDelegate_ = [[FRRadioGroupControllerDelegate alloc]
                       initWithController:self];
  }
  
  return helperDelegate_;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
  [delegate_ removeObserver:self forKeyPath:@"isPlaying"];
  [helperDelegate_ release];
  
  [super dealloc];
}

#pragma mark NSKeyValueObserving methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == delegate_) {
    if ([keyPath isEqualToString:@"isPlaying"]) {
      [self.tableView reloadData];
      return;
    }
  }
  
  [super observeValueForKeyPath:keyPath
                       ofObject:object
                         change:change
                        context:context];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return FR_NUM_SECTIONS;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  NSInteger count;
	switch (section) {
		case FRRadioSection:
      count = self.items.count;
      if (count > 8) {
        self.tableView.scrollEnabled = YES;
      }
			return count;
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	RRQTransparentGradientCell *cell = (RRQTransparentGradientCell *)
    [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[RRQTransparentGradientCell alloc]
             initWithFrame:CGRectZero
             reuseIdentifier:CellIdentifier] autorelease];
  }
	
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  cell.text = item.name;
  if (item.group) {
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  }
  
  FRRadio *radio = item.finalRadio;
	if (activeRadio_ == indexPath.row) {
    if (radio != nil &&
        radio == [self.delegate activeRadio] &&
        [self.delegate isPlaying]) {
      cell.image = soundOn;
		} else {
      cell.image = soundOff;
    }
	} else {
		cell.image = nil;
	}
  
	return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  if ([self.delegate activeRadio] != item.finalRadio ||
      ![self.delegate isPlaying]) {
    FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
    
    if (activeRadio_ != -1) {
      NSIndexPath *oldIndexPath =
        [NSIndexPath indexPathForRow:activeRadio_ inSection:0];
      [[self.tableView cellForRowAtIndexPath:oldIndexPath] setImage:nil];
    }
    
    if (item.group && !item.radioGroup.selected) {
      FRRadioGroupController *subcontroller = [[FRRadioGroupController alloc] init];
      subcontroller.parentItem = item;
      self.helperDelegate.tableViewItem = item;
      subcontroller.delegate = self.helperDelegate;
      [self.navigationController pushViewController:subcontroller animated:YES];
      [subcontroller release];
    } else if (item.group) {
      [[self.tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
      [self.delegate playRadio:item.radioGroup.selected];
      activeRadio_ = indexPath.row;
    } else {
      [[self.tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
      [self.delegate playRadio:item.radio];
      activeRadio_ = indexPath.row;
    }
	}
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  FRDirectoryItem *item = [self.items objectAtIndex:indexPath.row];
  FRRadioGroupController *subcontroller = [[FRRadioGroupController alloc] init];
  subcontroller.parentItem = item;
  self.helperDelegate.tableViewItem = item;
  subcontroller.delegate = self.helperDelegate;
  [self.navigationController pushViewController:subcontroller animated:YES];
  [subcontroller release];
}

@end

