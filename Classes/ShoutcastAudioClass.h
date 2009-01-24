//
//  ShoutcastAudioClass.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 23/01/09.
//  Copyright 2009 Daniel Rodríguez y Javier Quevedo. All rights reserved.
//

#import "AudioClass.h"


@interface ShoutcastPlayer : Player {
 @private
  unsigned int metadataInterval;
  unsigned int byteCounter;
  unsigned int bufferCounter;
  unsigned int metadataLength;
  unsigned int metadataCounter;
  
  BOOL headerParsed;
  
  NSDictionary *headers_;
  
  void *metadata;
}

@property(nonatomic, readonly, retain) NSDictionary *headers;

@end
