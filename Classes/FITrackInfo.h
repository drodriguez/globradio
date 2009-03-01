//
//  FITrackInfo.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FIArtistInfo;
@class FIAlbumInfo;

@interface FITrackInfo : NSObject {
 @private
  unsigned int lastFMId_;
  NSString *name_;
  NSString *mbid_;
  FIArtistInfo *artist_;
  FIAlbumInfo *album_;
}

@property (nonatomic, assign) unsigned int lastFMId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mbid;
@property (nonatomic, retain) FIArtistInfo *artist;
@property (nonatomic, retain) FIAlbumInfo *album;

- (id)initWithData:(NSData *)xmlData;

- (NSURL *)image;

@end
