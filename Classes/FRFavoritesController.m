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

enum FRFavoritesSections {
  FRFavoritesSection,
  FRFavoritesSectionsNumber
};

static UIImage *soundOff;
static UIImage *soundOn;

@interface FRFavoritesController ()

@property (nonatomic, retain) FRViewController *parentController;

- (NSArray *)items;

@end


@implementation FRFavoritesController

@synthesize activeRadio = activeRadio_;
@synthesize parentController = parentController_;

+ (void)initialize {
  soundOn = [UIImage imageNamed:@"altavoz-on.png"];
  soundOff = [UIImage imageNamed:@"altavoz.png"];
}

- (id)initWithParentController:(FRViewController *)parentController {
  if (self = [super init]) {
    parentController_ = [parentController retain];
    activeRadio_ = -1; // TODO: search for the real active radio
  }
  
  return self;
}

- (void)dealloc {
  [items_ release];
  [parentController_ release];
  
  [super dealloc];
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
    case FRRadioSection:
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
  
  if (indexPath.row > self.items.count) {
    // This is the last row
    cell.text = @"Plus..."
    UIFont *font = cell.font;
    cell.font = [UIFont italicSystemFontOfSize:cell.font.pointSize];
  } else {
    FRFavorite *item = [self.items objectAtIndex:indexPath.row]
    cell.text = item.name;
    cell.font = [UIFont systemFontOfSize:cell.font.pointSize];
    
    FRRadio *radio = item.radio;
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
  // TODO: check the last row
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

#pragma mark Private methods

- (NSArray *)items {
  if (!items_) {
    items = [FRFavorite allByPosition];
  }
  
  return items_;
}

@end
