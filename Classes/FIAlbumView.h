//
//  FIAlbumView.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 24/02/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FIAlbumView : UIView {
  NSURLConnection *connection_;
  NSMutableData *data_;
  UIImage *image_;
}

- (void)loadImageFromURL:(NSURL *)url;
- (UIImage *)image;

@end
