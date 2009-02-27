//
//  FILastFMDataProvider.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FILastFMDataProvider.h"
#import "FINSString+URLQuery.h"

NSString *kLastFMApiURL = @"http://ws.audioscrobbler.com/2.0/";

@implementation FILastFMDataProvider

- (id)initWithApiKey:(NSString *)apiKey {
  return [self initWithApiKey:apiKey andApiSecret:apiSecret];
}

- (id)initWithApiKey:(NSString *)apiKey andApiSecret:(NSString *)apiSecret {
  if (self = [super init]) {
    apiKey_ = [apiKey copy];
    apiSecret_ = [apiSecret copy];
  }
  
  return self;
}

- (FITrackInfo *)trackInfoForTitle:(NSString *)title
                         andArtist:(NSString *)artist {
  NSDictionary *queryParameters = [[NSDictionary alloc]
    initWithObjectsAndKeys:apiKey_, @"api_key",
                                   title, @"track",
                                   artist, @"artist", nil];
  NSString *queryParametersStr =
    [NSString stringWithQueryDictionary:queryParameters];
  [queryParameters release];
  
  NSString *urlStr =
    [[NSString alloc] initWithFormat:@"%@?%@",
     kLastFMApiURL,
     queryParametersStr];
  NSURL *queryUrl = [[NSURL alloc] initWithString:urlStr];
  [urlStr release];
  
  NSData xmlData = [[[NSData alloc] initWithContentsOfURL:queryUrl] autorelease];  
  return [[[FITrackInfo alloc] initWithData:xmlData] autorelease];
}

- (FIArtistInfo *)artistInfoForArtist:(NSString *) {
  
}

- (NSURL *)imageForTitle:(NSString *)title andArtist:(NSString *)artist {
  
}

@end
