//
//  FILastFMDataProvider.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FITrackInfo;
@class FIArtistInfo;

@interface FILastFMDataProvider : NSObject {
 @private
  NSString *apiKey_;
  NSString *apiSecret_;
}

- (id)initWithApiKey:(NSString *)apiKey;
- (id)initWithApiKey:(NSString *)apiKey andApiSecret:(NSString *)apiSecret;

- (FITrackInfo *)trackInfoForTitle:(NSString *)title
                         andArtist:(NSString *)artist;

- (FIArtistInfo *)artistInfoForArtist:(NSString *)artist;

- (NSURL *)imageForTitle:(NSString *)title andArtist:(NSString *)artist;
@end
