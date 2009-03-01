//
//  FILastFMDataProvider.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FILastFMDataProvider.h"
#import "FINSString+URLQuery.h"
#import "FITrackInfo.h"
#import "FIArtistInfo.h"

static NSString *kLastFMApiURL = @"http://ws.audioscrobbler.com/2.0/";
static NSString *kMethodParameter = @"method";
static NSString *kApiKeyParameter = @"api_key";
static NSString *kTrackParameter = @"track";
static NSString *kArtistParameter = @"artist";
static NSString *kTrackGetInfoMethod = @"track.getinfo";
static NSString *kArtistGetInfoMethod = @"artist.getinfo";

@implementation FILastFMDataProvider

- (id)initWithApiKey:(NSString *)apiKey {
  return [self initWithApiKey:apiKey andApiSecret:@""];
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
    initWithObjectsAndKeys:kTrackGetInfoMethod, kMethodParameter,
                                   apiKey_, kApiKeyParameter,
                                   title, kTrackParameter,
                                   artist, kArtistParameter, nil];
  NSString *queryParametersStr =
    [NSString stringWithQueryDictionary:queryParameters];
  [queryParameters release];
  
  NSString *urlStr =
    [[NSString alloc] initWithFormat:@"%@?%@",
     kLastFMApiURL,
     queryParametersStr];
  RNLog(@"URL %@", urlStr);
  NSURL *queryUrl = [[NSURL alloc] initWithString:urlStr];
  [urlStr release];
  
  NSData *xmlData = [[[NSData alloc] initWithContentsOfURL:queryUrl] autorelease];  
  return [[[FITrackInfo alloc] initWithData:xmlData] autorelease];
}

- (FIArtistInfo *)artistInfoForArtist:(NSString *)artist {
  NSDictionary *queryParameters = [[NSDictionary alloc]
    initWithObjectsAndKeys:kArtistGetInfoMethod, kMethodParameter,
                                   apiKey_, kApiKeyParameter,
                                   artist, kArtistParameter, nil];
  
  NSString *queryParametersStr =
    [NSString stringWithQueryDictionary:queryParameters];
  [queryParameters release];
  
  NSString *urlStr =
    [[NSString alloc] initWithFormat:@"%@?%@",
     kLastFMApiURL,
     queryParametersStr];
  RNLog(@"URL %@", urlStr);
  NSURL *queryUrl = [[NSURL alloc] initWithString:urlStr];
  [urlStr release];
  
  NSData *xmlData = [[[NSData alloc] initWithContentsOfURL:queryUrl] autorelease];
  return [[[FIArtistInfo alloc] initWithData:xmlData] autorelease];
}

- (NSURL *)imageForTitle:(NSString *)title andArtist:(NSString *)artist {
  NSURL *result;
  // Try first to obtain the album cover from the track info.
  FITrackInfo *trackInfo = [self trackInfoForTitle:title andArtist:artist];
  if (trackInfo) {
    result = [trackInfo image];
    if (result) {
      return result;
    }
  }
  
  // Then try the artist image
  FIArtistInfo *artistInfo = [self artistInfoForArtist:artist];
  if (artistInfo) {
    result = [artistInfo image];
    if (result) {
      return result;
    }
  }
  
  // Then nothing
  return nil;
}

@end
