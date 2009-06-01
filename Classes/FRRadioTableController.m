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
#import "FRMainRadiosController.h"
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
    if (activeRadio_ != -1) {
      NSIndexPath *oldIndexPath =
        [NSIndexPath indexPathForRow:activeRadio_ inSection:0];
      [[self.tableView cellForRowAtIndexPath:oldIndexPath] setImage:nil];
    }
    [[self.tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
		activeRadio_ = indexPath.row;
    
    FRTableViewItem *item = [self.items objectAtIndex:activeRadio_];
    if (item.group && !item.radioGroup.selected) {
      // TODO: show better the next controller.
      FRRadioTableController *subcontroller = [[FRMainRadiosController alloc] initWithNibName:@"RadiosView" bundle:nil];
      [self.navigationController pushViewController:subcontroller animated:YES];
    } else if (item.group) {
      [self.delegate playRadio:item.radioGroup.selected];
    } else {
      [self.delegate playRadio:item.radio];
    }
	}
}

- (void)dealloc {
    [super dealloc];
}


@end

