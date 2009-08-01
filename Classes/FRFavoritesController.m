//
//  FRFavoritesController.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 31/07/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "FRFavoritesController.h"
#import "FRFavorite.h"
#import "FRViewController.h"
#import "FRFavoritesManager.h"
#import "FRDirectoryController.h"
#import "RRQTransparentGradientCell.h"

enum FRFavoritesSections {
  FRFavoritesSection,
  FRFavoritesSectionsNumber
};

static UIImage *soundOff;
static UIImage *soundOn;
static UIImageView *whiteDisclosure;

@interface FRFavoritesController ()

- (NSArray *)items;

@end


@implementation FRFavoritesController

@synthesize activeRadio = activeRadio_;
@synthesize parentController = parentController_;

+ (void)initialize {
  soundOn = [[UIImage imageNamed:@"altavoz-on.png"] retain];
  soundOff = [[UIImage imageNamed:@"altavoz.png"] retain];
  whiteDisclosure = [[UIImageView alloc] initWithImage:
                     [UIImage imageNamed:@"white-disclosure.png"]];
}

- (id)init {
  if (self = [super initWithNibName:@"RadiosView" bundle:nil]) {
    activeRadio_ = -1; // TODO: search for the real active radio
  }
  
  return self;
}

- (void)addRadio:(FRRadio *)radio {
  // TODO: check limits
  FRFavorite *lru = [FRFavorite findFirstLeastRecentlyUsed];
  lru.radio = radio;
  [lru save];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return FRFavoritesSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case FRFavoritesSection:
      return self.items.count + 1;
    default:
      return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *kFavoritesCell = @"FavoritesCell";
  
  RRQTransparentGradientCell *cell = (RRQTransparentGradientCell *)
    [tableView dequeueReusableCellWithIdentifier:kFavoritesCell];
  if (cell == nil) {
    cell = [[[RRQTransparentGradientCell alloc]
            initWithFrame:CGRectZero
             reuseIdentifier:kFavoritesCell] autorelease];
  }
  
  if (indexPath.row >= self.items.count) {
    // This is the last row
    cell.text = @"Plus...";
    cell.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:18];
    cell.accessoryView = whiteDisclosure;
  } else {
    FRFavorite *item = [self.items objectAtIndex:indexPath.row];
    cell.text = item.name;
    cell.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (activeRadio_ == indexPath.row) {
      if (self.parentController.isPlaying) {
        cell.image = soundOn;
      } else {
        cell.image = soundOff;
      }
    } else {
      cell.image = nil;
    }
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= self.items.count) {
    FRDirectoryController *directoryController = [[FRDirectoryController alloc] initWithGroupId:0];
    [self.navigationController pushViewController:directoryController animated:YES];
    [directoryController release];
  } else {
    FRFavorite *item = [self.items objectAtIndex:indexPath.row];
    if (self.parentController.activeRadio != item.radio ||
        !self.parentController.isPlaying) {
      if (activeRadio_ != -1) {
        NSIndexPath *oldIndexPath =
          [NSIndexPath indexPathForRow:activeRadio_ inSection:0];
        [[tableView cellForRowAtIndexPath:oldIndexPath] setImage:nil];
      }
      
      [[tableView cellForRowAtIndexPath:indexPath] setImage:soundOff];
      [self.parentController playRadio:item.radio];
      activeRadio_ = indexPath.row;
    }
  }
}

#pragma mark Private methods

- (NSArray *)items {
  return self.parentController.favoritesManager.items;
}

@end
