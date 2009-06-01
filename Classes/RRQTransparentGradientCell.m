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
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIImageView *backgroundView =
      [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rowBackground.png"]];
    backgroundView.opaque = NO;
    self.backgroundView = backgroundView;
    [backgroundView release];
    self.opaque = NO;
    // FIX: There is a warning in this line, but I don't know why exactly.
    [self.layer setBackgroundColor:[UIColor clearColor].CGColor];
    
    textLabel_ = [[UILabel alloc] initWithFrame:CGRectMake(49, 5, 261, 35)];
    textLabel_.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    textLabel_.backgroundColor = [UIColor clearColor];
    textLabel_.textColor = [UIColor whiteColor];
    textLabel_.contentMode = UIViewContentModeScaleToFill;
    [self.contentView addSubview:textLabel_];
    
    image_ = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 37, 33)];
    image_.contentMode = UIViewContentModeScaleAspectFill;
    image_.clipsToBounds = YES;
    [self.contentView addSubview:image_];
  }
  
  return self;
}

- (void)dealloc {
  [textLabel_ release];
  [image_ release];
  
  [super dealloc];
}

- (void)setText:(NSString *)text {
  textLabel_.text = text;
}

- (NSString *)text {
  return textLabel_.text;
}

- (void)setImage:(UIImage *)image {
  image_.image = image;
}

- (UIImage *)image {
  return image_.image;
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
  if (accessoryType == UITableViewCellAccessoryDetailDisclosureButton) {
    CGRect frame = textLabel_.frame;
    frame.size.width = 236;
    textLabel_.frame = frame;
  }
  
  [super setAccessoryType:accessoryType];
}

@end
