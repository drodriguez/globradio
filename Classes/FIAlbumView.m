//
//  FIAlbumView.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/02/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import "FIAlbumView.h"

#define DATA_INITIAL_CAPACITY 2048
#define DEFAULT_IMAGE_SIZE 300
#define SHADOW_RADIUS 20
#define MARGIN 30

@implementation FIAlbumView

// TODO: Create the internal UIImageView?
/*- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      // Initialization code
    }
    return self;
}*/

- (void)drawRect:(CGRect)rect {
  CGRect bounds = self.bounds;
  
  CGSize imageSize;
  if (image_) {
    imageSize = image_.size;
  } else {
    imageSize = CGSizeMake(DEFAULT_IMAGE_SIZE, DEFAULT_IMAGE_SIZE);
  }
  
  // resize image if larger
  if (imageSize.width + MARGIN > bounds.size.width) {
    imageSize.height /= imageSize.width / (bounds.size.width - MARGIN);
    imageSize.width = bounds.size.width - MARGIN;
  }
  if (imageSize.height + MARGIN > bounds.size.height) {
    imageSize.width /= imageSize.height / (bounds.size.height - MARGIN);
    imageSize.height = bounds.size.height - MARGIN;
  }
  
  CGPoint imagePosition =
    CGPointMake(self.bounds.size.width/2 - imageSize.width/2,
                self.bounds.size.height/2 - imageSize.width/2);
  
  CGSize shadowOffset = CGSizeMake(0.0, 0.0);
  const CGFloat shadowValues[] = {0.0f, 0.0f, 0.0f, 1.0f};
  CGColorRef shadowColor;
  CGColorSpaceRef deviceColorSpace;
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  float grayLevel = 38.0/255.0;
  CGContextSetRGBFillColor(ctx, grayLevel, grayLevel, grayLevel, 1.0);
  CGContextFillRect(ctx, bounds);
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathAddRect(path, NULL,
                CGRectMake(imagePosition.x - 1, imagePosition.y - 1,
                           imageSize.width + 1, imageSize.height + 1));

  CGContextSaveGState(ctx);
  
  deviceColorSpace = CGColorSpaceCreateDeviceRGB();
  shadowColor = CGColorCreate(deviceColorSpace, shadowValues);
  CGContextSetShadowWithColor(ctx, shadowOffset, SHADOW_RADIUS, shadowColor);
  CGColorRelease(shadowColor);
  CGColorSpaceRelease(deviceColorSpace);
  
  CGContextBeginPath(ctx);
  CGContextAddPath(ctx, path);
  CGContextFillPath(ctx);
  
  CGContextRestoreGState(ctx);
  
  if (image_) {
    [image_ drawInRect:CGRectMake(imagePosition.x,
                                  imagePosition.y,
                                  imageSize.width,
                                  imageSize.height)];
  }
  
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
  
  if (image_) {
    [image_ release];
  }
  
  image_ = [[UIImage alloc] initWithData:data_];
  
  [self setNeedsDisplay];
  
  [data_ release];
  data_ = nil;
}

#pragma mark Accesor

- (UIImage *)image {
  return image_;
}

#pragma mark dealloc

- (void)dealloc {
  if (image_) [image_ release];
  
  [super dealloc];
}

@end
