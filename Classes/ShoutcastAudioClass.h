//
//  ShoutcastAudioClass.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 23/01/09.
//  Copyright 2009 Daniel Rodríguez y Javier Quevedo. All rights reserved.
//

#import "RRQAudioPlayer.h"


@protocol ShoutcastPlayerDelegate;


@interface ShoutcastPlayer : RRQAudioPlayer {
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



@protocol ShoutcastPlayerDelegate

@optional
- (void)player:(ShoutcastPlayer *)player
updatedMetadata:(NSDictionary *)metadataDictionary;

@end

