//
//  FIAlbumView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/02/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import "FIAlbumView.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_IMAGE_SIZE 300
#define SHADOW_RADIUS 10.0
#define MARGIN 10

#pragma mark FIAlbumView private interface

@interface FIAlbumView ()

- (void)setupLayerTree;

@end



#pragma mark FIShadowLayerDelegate interface & implementation

@interface FIShadowLayerDelegate : NSObject
{
 @private
  CGSize offset_;
  CGFloat blur_;
  CGColorRef color_;
}

@property (nonatomic, assign) CGSize offset;
@property (nonatomic, assign) CGFloat blur;
@property (nonatomic, assign) CGColorRef color;

- (id)init;
- (id)initWithOffset:(CGSize)offset andBlur:(CGFloat)blur;
// Designated initalizer
- (id)initWithOffset:(CGSize)offset blur:(CGFloat)blur andColor:(CGColorRef)color;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;

@end

@implementation FIShadowLayerDelegate

@synthesize offset = offset_;
@synthesize blur = blur_;
@synthesize color = color_;

- (id)init {
  return [self initWithOffset:CGSizeMake(0.0, 0.0)
                      andBlur:SHADOW_RADIUS];
}

- (id)initWithOffset:(CGSize)offset andBlur:(CGFloat)blur {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat components[] = {0.0, 0.0, 0.0, 1.0/3.0};
  CGColorRef color = CGColorCreate(colorSpace, components);
  self = [self initWithOffset:offset blur:blur andColor:color];
  CFRelease(color);
  CFRelease(colorSpace);
  
  return self;
}

- (id)initWithOffset:(CGSize)offset blur:(CGFloat)blur andColor:(CGColorRef)color {
  if (self = [super init]) {
    self.offset = offset;
    self.blur = blur;
    CFRetain(color);
    self.color = color;
  }
  
  return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
  CGRect bounds = layer.bounds;
  bounds.size.width -= 2*blur_;
  bounds.size.height -= 2*blur_;
  bounds.origin.x += blur_;
  bounds.origin.y += blur_;
  
  CGContextSaveGState(ctx);
  CGContextSetShadowWithColor(ctx, offset_, blur_, color_);
  
  CGContextFillRect(ctx, bounds);
  
  CGContextRestoreGState(ctx);
}

- (void)dealloc {
  if (color_) CFRelease(color_);
  
  [super dealloc];
}

@end



#pragma mark FIBorderLayerDelegate interface & implementation

@interface FIBorderLayerDelegate : NSObject
{
 @private
  CGFloat width_;
  CGColorRef color_;
}

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGColorRef color;

- (id)init;
// Designated initializer
- (id)initWithWidth:(CGFloat)width andColor:(CGColorRef)color;

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;

@end

@implementation FIBorderLayerDelegate

@synthesize width = width_;
@synthesize color = color_;

- (id)init {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat components[] = {0.0, 0.0, 0.0, 1.0};
  CGColorRef color = CGColorCreate(colorSpace, components);
  self = [self initWithWidth:1.0 andColor:color];
  CFRelease(color);
  CFRelease(colorSpace);
  
  return self;
}

- (id)initWithWidth:(CGFloat)width andColor:(CGColorRef)color {
  if (self = [super init]) {
    self.width = width;
    CFRetain(color);
    self.color = color;
  }
  
  return self;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
  CGRect bounds = layer.bounds;
  
  CGContextSaveGState(ctx);
  CGContextSetStrokeColorWithColor(ctx, color_);
  CGContextSetLineWidth(ctx, width_);
  
  CGContextStrokeRect(ctx, bounds);
  
  CGContextRestoreGState(ctx);
}

- (void)dealloc {
  if (color_) CFRelease(color_);
  
  [super dealloc];
}

@end



#pragma mark FIAlbumView implementation

@implementation FIAlbumView

@synthesize image = image_;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      [self setupLayerTree];
    }
    return self;
}

- (void)awakeFromNib {
  [self setupLayerTree];
}

#pragma mark Custom methods

- (void)loadImageFromURL:(NSURL *)url {
  NSData *data = [NSData dataWithContentsOfURL:url];
  
  self.image = [UIImage imageWithData:data];
}

#pragma mark Accesors

- (void)setImage:(UIImage *)newImage {
  if (newImage != image_) {
    // Yo dawg, I animating!
    CGSize imageSize = newImage.size;
    CGRect bounds = self.bounds;
    
    // resize image if larger
    CGFloat scaleHeight = 1.0;
    CGFloat scaleWidth = 1.0;
    if (imageSize.width + MARGIN > bounds.size.width) {
      scaleHeight /= imageSize.width / (bounds.size.width - MARGIN);
      scaleWidth /= imageSize.width / (bounds.size.width - MARGIN);
    }
    if (imageSize.height*scaleHeight + MARGIN > bounds.size.height) {
      scaleWidth /= imageSize.height*scaleHeight / (bounds.size.height - MARGIN);
      scaleHeight /= imageSize.width*scaleWidth / (bounds.size.height - MARGIN);
    }
    
    [CATransaction begin];
    // The bounds unfortunately move at different pace.
    // [CATransaction setValue:[NSNumber numberWithFloat:5.0f] forKey:kCATransactionAnimationDuration];
    coverLayer_.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
    borderLayer_.bounds = CGRectMake(0, 0, imageSize.width*scaleWidth+1, imageSize.height*scaleHeight+1);
    shadowLayer_.bounds = CGRectMake(0, 0, imageSize.width*scaleWidth+2*SHADOW_RADIUS, imageSize.height*scaleHeight+2*SHADOW_RADIUS);
    coverLayer_.contents = (id)newImage.CGImage;
    coverLayer_.transform = CATransform3DMakeScale(scaleWidth, scaleHeight, 1.0);
    [CATransaction commit];
    
    [image_ release];
    image_ = [newImage retain];
  }
}

#pragma mark Private Methods

- (void)setupLayerTree {
  CGRect bounds = self.bounds;

  coverLayer_ = [CALayer layer];
  coverLayer_.needsDisplayOnBoundsChange = YES;
  coverLayer_.position = CGPointMake(bounds.size.width/2.0, bounds.size.height/2.0);
  coverLayer_.bounds = CGRectZero;
  
  shadowLayer_ = [CALayer layer];
  shadowLayer_.needsDisplayOnBoundsChange = YES;
  shadowLayer_.delegate = [[FIShadowLayerDelegate alloc] init];
  shadowLayer_.position = CGPointMake(bounds.size.width/2.0, bounds.size.height/2.0);
  shadowLayer_.bounds = CGRectZero;
  
  borderLayer_ = [CALayer layer];
  borderLayer_.needsDisplayOnBoundsChange = YES;
  borderLayer_.delegate = [[FIBorderLayerDelegate alloc] init];
  borderLayer_.position = CGPointMake(bounds.size.width/2.0, bounds.size.height/2.0);
  borderLayer_.bounds = CGRectZero;
  
  [self.layer addSublayer:shadowLayer_];
  [self.layer addSublayer:coverLayer_];
  [self.layer addSublayer:borderLayer_];
}

#pragma mark dealloc

- (void)dealloc {
  if (coverLayer_) [coverLayer_ release];
  if (shadowLayer_) {
    [shadowLayer_.delegate release];
    [shadowLayer_ release];
  }
  if (borderLayer_) {
    [borderLayer_.delegate release];
    [borderLayer_ release];
  }
  if (image_) [image_ release];
  
  [super dealloc];
}

@end
