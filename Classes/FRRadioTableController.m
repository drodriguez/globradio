//
//  FRRadioTableController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 21/05/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRRadioTableController.h"
#import "FRTableViewItem.h"
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

@end


@implementation FRRadioTableController

@dynamic items;
@synthesize delegate = delegate_;

+ (void)initialize {
  soundOn = [UIImage imageNamed:@"altavoz-on.png"];
  soundOff = [UIImage imageNamed:@"altavoz.png"];
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle {
  if (self = [super initWithNibName:nibName bundle:bundle]) {
    activeRadio_ = -1;
  }
  
  return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
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
	
  FRTableViewItem *item = [self.items objectAtIndex:indexPath.row];
  cell.text = item.name;
  if (item.group) {
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  }
	
	if (activeRadio_ == indexPath.row) {
    if ([self.delegate isPlaying]) {
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
  if (activeRadio_ != indexPath.row || ![self.delegate isPlaying]) {
    FRTableViewItem *item = [self.items objectAtIndex:indexPath.row];
    
    if (activeRadio_ != -1) {
      NSIndexPath *oldIndexPath =
        [NSIndexPath indexPathForRow:activeRadio_ inSection:0];
      [[self.tableView cellForRowAtIndexPath:oldIndexPath] setImage:nil];
    }
    
    if (item.group && !item.radioGroup.selected) {
      FRRadioGroupController *subcontroller = [[FRRadioGroupController alloc] initWithNibName:@"RadiosView" bundle:nil];
      subcontroller.parentId = [item pk];
      [self.navigationController pushViewController:subcontroller animated:YES];
    } else if (item.group) {
      [[self.tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
      [self.delegate playRadio:item.radioGroup.selected];
    } else {
      [[self.tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
      [self.delegate playRadio:item.radio];
    }
    activeRadio_ = indexPath.row;
	}
}

- (void)tableView:(UITableView *)tableView
accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  FRTableViewItem *item = [self.items objectAtIndex:indexPath.row];
  FRRadioGroupController *subcontroller = [[FRRadioGroupController alloc] initWithNibName:@"RadiosView" bundle:nil];
  subcontroller.parentId = [item pk];
  [self.navigationController pushViewController:subcontroller animated:YES];
}

- (void)dealloc {
    [super dealloc];
}


@end

