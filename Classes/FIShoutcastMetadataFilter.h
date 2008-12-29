//
//  FIShoutcastMetadataFilter.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 29/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioClass.h"

@interface FIShoutcastMetadataFilter : NSObject <RNConnectionFilter> {
 @private
  int metaint;
  int counter;
  void *metadata;
  int metadataLength;
  int metadataCounter;
  BOOL headerParsed;
  NSDictionary *headers;
}

- (id)init;

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request;
- (NSData *)connection:(NSURLConnection *)connection
            filterData:(NSData *)data;

@end
