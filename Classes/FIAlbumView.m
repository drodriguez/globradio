//
//  FIAlbumView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/02/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import "FIAlbumView.h"

#define DATA_INITIAL_CAPACITY 2048

@implementation FIAlbumView

// TODO: Create the internal UIImageView?
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

// TODO: Draw the shadow and border?
- (void)drawRect:(CGRect)rect {
  CGRect bounds = self.bounds;
  CGSize shadowOffset = CGSizeMake(0.0, 0.0);
  const CGFloat shadowValues[] = {0.0f, 0.0f, 0.0f, 1.0f};
  CGColorRef shadowColor;
  CGColorSpaceRef deviceColorSpace;
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  float grayLevel = 38.0/255.0;
  CGContextSetRGBFillColor(ctx, grayLevel, grayLevel, grayLevel, 1.0);
  CGContextFillRect(ctx, bounds);
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, NULL, CGRectMake(15.0, 15.0, bounds.size.width-30, bounds.size.height-30));

  CGContextSaveGState(ctx);
  
  deviceColorSpace = CGColorSpaceCreateDeviceRGB();
  shadowColor = CGColorCreate(deviceColorSpace, shadowValues);
  CGContextSetShadowWithColor(ctx, shadowOffset, 20.0, shadowColor);
  CGColorRelease(shadowColor);
  CGColorSpaceRelease(deviceColorSpace);
  
  CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
  CGContextBeginPath(ctx);
  CGContextAddPath(ctx, path);
  CGContextFillPath(ctx);
  
  CGContextRestoreGState(ctx);
  
  CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
  CGContextBeginPath(ctx);
  CGContextAddPath(ctx, path);
  CGContextStrokePath(ctx);
  
  CGPathRelease(path);
}

#pragma mark Custom methods

- (void)loadImageFromURL:(NSURL *)url {
  if (connection_) {
    [connection_ release];
    connection_ = nil;
  }
  if (data_) {
    [data_ release];
    data_ = nil;
  }
  
  NSURLRequest* request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                       timeoutInterval:60.0];
  connection_ = [[NSURLConnection alloc]
                 initWithRequest:request delegate:self];
  // TODO: error handling?
}

#pragma mark Connection delegate methods

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {
  if (!data_) {
    data_ = [[NSMutableData alloc] initWithCapacity:DATA_INITIAL_CAPACITY];
  }
  [data_ appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  [connection_ release];
  connection = nil;
  
  if ([[self subviews] count] > 0) {
    [[[self subviews] objectAtIndex:0] removeFromSuperview];
  }
  
  UIImageView *imageView = [[[UIImageView alloc]
                             initWithImage:[UIImage imageWithData:data_]] autorelease];
  
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.autoresizingMask =
    (UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight);
  
  [self addSubview:imageView];
  imageView.frame = self.bounds;
  [imageView setNeedsLayout];
  [self setNeedsLayout];
  [data_ release];
  data_ = nil;
}

#pragma mark Accesor

- (UIImage *)image {
  UIImageView *iv = [[self subviews] objectAtIndex:0];
  return [iv image];
}

#pragma mark dealloc

- (void)dealloc {
  [super dealloc];
}

@end
