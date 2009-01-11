//
//  COPENeedleView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 11/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "COPENeedleView.h"

#define RADIO_CENTER 160
#define RADIO_0_X 88
#define RADIO_1_X 232
#define BOUNCE_MAX 20
#define NEEDLE_Y 267

static NSString *kPopup = @"kPopup";
static NSString *kPopupBounce = @"kPopupBounce";
static NSString *kSlide = @"kSlide";
static NSString *kSlideBounce = @"kSlideBounce";

@interface COPENeedleView ()

@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;

- (void) createImageView;

- (void)popupFinished:(NSString *)animationID
             finished:(BOOL)finished
              context:(void *)context;

- (void)slideFinished:(NSString *)animationID
             finished:(BOOL)finished
              context:(void *)context;

@end


@implementation COPENeedleView

@synthesize target = _target;
@synthesize action = _action;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      isVisible = NO;
      [self setUserInteractionEnabled:NO];
      [self createImageView];
    }
    return self;
}

- (void)awakeFromNib {
  [self createImageView];
}

- (void)createImageView {
  CGRect frame = self.frame;
  imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,
                                                            frame.size.width,
                                                            frame.size.height)];
  [imageView setImage:[UIImage imageNamed:@"needle.png"]];
  imageView.userInteractionEnabled = NO;
  imageView.alpha = 0.0;
  [self addSubview:imageView];
}

- (void)switchToRadioIndex:(int)index {
  // New position (overshoot)
  CGPoint center;
  switch (index) {
    case 0:
      center = CGPointMake(RADIO_0_X - BOUNCE_MAX, NEEDLE_Y);
      break;
    case 1:
      center = CGPointMake(RADIO_1_X + BOUNCE_MAX, NEEDLE_Y);
      break;
    default:
      center = CGPointMake(RADIO_CENTER, NEEDLE_Y);
      break;      
  }
  
  // Slide animation (overshoot)
  [UIView beginAnimations:kSlide context:[NSNumber numberWithInt:index]];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:0.25];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(slideFinished:finished:context:)];
  
  self.center = center;
  
  [UIView commitAnimations];
}

#define INITIAL_SCALE (1.0/72.0)
#define OVERSHOOT_SCALE 1.25

- (void)showAtRadioIndex:(int)index {
  if (isVisible) {
    return;
  }
  isVisible = YES;
  [self setUserInteractionEnabled:YES];
  
  // Set a small size.
  imageView.transform = CGAffineTransformMakeScale(INITIAL_SCALE, INITIAL_SCALE);
  
  // Set position
  CGPoint center;
  switch (index) {
    case 0:
      center = CGPointMake(RADIO_0_X, NEEDLE_Y);
      break;
    case 1:
      center = CGPointMake(RADIO_1_X, NEEDLE_Y);
      break;
    default:
      center = CGPointMake(RADIO_CENTER, NEEDLE_Y);
      break;      
  }
  self.center = center;
    
  // Make animation
  [UIView beginAnimations:kPopup context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:0.5];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(popupFinished:finished:context:)];
  
  imageView.transform = CGAffineTransformMakeScale(OVERSHOOT_SCALE, OVERSHOOT_SCALE);
  [imageView setAlpha:1.0];
  
  [UIView commitAnimations];
}

- (void)setTarget:(id)target action:(SEL)action {
  self.target = target;
  self.action = action;
}

- (void)popupFinished:(NSString *)animationID
             finished:(BOOL)finished
              context:(void *)context {
  // Make the bounce animation
  [UIView beginAnimations:kPopupBounce context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.2];
  imageView.transform = CGAffineTransformIdentity;
  [UIView commitAnimations];
}

- (void)slideFinished:(NSString *)animationID
             finished:(BOOL)finished
              context:(void *)context {
  NSNumber *index = (NSNumber *) context;
  
  CGPoint center;
  switch ([index intValue]) {
    case 0:
      center = CGPointMake(RADIO_0_X, NEEDLE_Y);
      break;
    case 1:
      center = CGPointMake(RADIO_1_X, NEEDLE_Y);
      break;
    default:
      center = CGPointMake(RADIO_CENTER, NEEDLE_Y);
      break;      
  }
  
  // Make the bounce animation
  [UIView beginAnimations:kSlideBounce context:nil];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
  [UIView setAnimationDuration:0.1];
  
  self.center = center;
  
  [UIView commitAnimations];  
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  startLocation = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  CGPoint pt = [[touches anyObject] locationInView:self];
  CGPoint center = self.center;
  
  center.x += pt.x - startLocation.x;
  
  if (center.x < (RADIO_0_X - BOUNCE_MAX)) center.x = RADIO_0_X - BOUNCE_MAX;
  else if (center.x > (RADIO_1_X + BOUNCE_MAX)) center.x = RADIO_1_X + BOUNCE_MAX;
  
  self.center = center;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  CGPoint pt = [[touches anyObject] locationInView:self];
  CGPoint center = self.center;
  
  center.x += pt.x - startLocation.x;
  
  if (center.x < (RADIO_0_X - BOUNCE_MAX)) center.x = RADIO_0_X - BOUNCE_MAX;
  else if (center.x > (RADIO_1_X + BOUNCE_MAX)) center.x = RADIO_1_X + BOUNCE_MAX;
  
  // Determine the nearer radio
  NSNumber *index;
  if (center.x < RADIO_CENTER) {
    index = [NSNumber numberWithInt:0];
  } else {
    index = [NSNumber numberWithInt:1];
  }
  
  // Determine the overshoot direction & distance
  if ([index intValue] == 0 && center.x < RADIO_0_X) {
    center.x = 2*RADIO_0_X - center.x; // 88 - (center.x - 88);
  } else if ([index intValue] == 0) {
    center.x = center.x > (RADIO_0_X + BOUNCE_MAX) ?
      RADIO_0_X - BOUNCE_MAX :
      2*RADIO_0_X - center.x; // 88 - (center.x - 88)
  } else if ([index intValue] == 1 && center.x > RADIO_1_X) {
    center.x = 2*RADIO_1_X - center.x; // 252 - (center.x - 252);
  } else {
    center.x = center.x < (RADIO_1_X - BOUNCE_MAX) ?
      RADIO_1_X + BOUNCE_MAX :
      2*RADIO_1_X - center.x; // 232 + (232 - center.x)
  }
  
  // Slide animation (overshoot)
  [UIView beginAnimations:kSlide context:index];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:0.2];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(slideFinished:finished:context:)];
  
  self.center = center;
  
  [UIView commitAnimations];
  
  if (_target != nil && [_target respondsToSelector:_action]) {
    [_target performSelector:_action withObject:index];
  }
}

- (void)dealloc {
  [imageView release];
  
  [super dealloc];
}


@end
