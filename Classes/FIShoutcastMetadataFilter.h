//
//  FIShoutcastMetadataFilter.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 29/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FIShoutcastMetadataFilter : NSObject <RNConnectionFilter> {
 @private
  int metaint;
  int counter;
  void *metadata;
  int metadataLength;
  int metadataCounter;
}

- (id)init;

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request;
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response;
- (NSData *)connection:(NSURLConnection *)connection
            filterData:(NSData *)data;

@end
