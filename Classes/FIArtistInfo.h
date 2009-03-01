//
//  FIArtistInfo.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/03/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FIArtistInfo : NSObject {
 @private
  unsigned int lastFMId_;
  NSString *name_;
  NSString *mbid_;
  NSMutableDictionary *images_;
}

@property (nonatomic, assign) unsigned int lastFMId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mbid;
@property (nonatomic, retain) NSDictionary *images;

- (id)initWithString:(NSString *)xmlString;
- (id)initWithData:(NSData *)xmlData;

- (NSURL *)image;

@end
