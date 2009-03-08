//
//  FIAlbumView.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/02/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FIAlbumView : UIView {
 @private
  UIImage *image_;
  
  CALayer *coverLayer_;
  CALayer *shadowLayer_;
  CALayer *borderLayer_;
}

@property (nonatomic, retain) UIImage *image;

- (void)loadImageFromURL:(NSURL *)url;

@end
