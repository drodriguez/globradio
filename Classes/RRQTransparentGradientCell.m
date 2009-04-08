//
//  RRQTransparentGradientCell.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 04/04/09.
//  Copyright 2009 Javier Quevedo & Daniel Rodríguez. All rights reserved.
//

#import "RRQTransparentGradientCell.h"



@implementation RRQTransparentGradientCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
  if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
    self.textColor = [UIColor whiteColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *backgroundView =
      [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rowBackground.png"]];
    backgroundView.opaque = NO;
    self.backgroundView = backgroundView;
    [backgroundView release];
    self.opaque = NO;
    // FIX: There is a warning in this line, but I don't know why exactly.
    [self.layer setBackgroundColor:[UIColor clearColor].CGColor];
  }
  
  return self;
}

@end
