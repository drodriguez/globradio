//
//  RRQShoutcastAudioPlayer.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 23/01/09.
//  Copyright 2009 Daniel Rodríguez y Javier Quevedo. All rights reserved.
//

#import "RRQAudioPlayer.h"


@protocol RRQShoutcastAudioPlayerDelegate;


@interface RRQShoutcastAudioPlayer : RRQAudioPlayer {
 @private
  unsigned int metadataInterval;
  unsigned int byteCounter;
  unsigned int metadataLength;
  unsigned int metadataCounter;
  
  BOOL headerParsed;
  
  NSDictionary *headers_;
  
  void *metadata;
  
  NSObject<ShoutcastPlayerDelegate> *delegate;
}

@property(nonatomic, readonly, retain) NSDictionary *headers;
@property(nonatomic, assign) NSObject<ShoutcastPlayerDelegate> *delegate;

@end



@protocol RRQShoutcastAudioPlayerDelegate

@optional
- (void)player:(RRQShoutcastAudioPlayer *)player
updatedMetadata:(NSDictionary *)metadataDictionary;

@end

