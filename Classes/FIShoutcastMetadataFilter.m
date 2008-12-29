//
//  FIShoutcastMetadataFilter.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 29/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FIShoutcastMetadataFilter.h"


@implementation FIShoutcastMetadataFilter

- (id)init {
  self = [super init];
  if (self != nil) {
    metaint = -1;
    counter = 0;
    metadata = NULL;
    metadataLength = 0;
    metadataCounter = 0;
  }
  
  return self;
}

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request {
  NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[request URL]
                                                   cachePolicy:[request cachePolicy]
                                               timeoutInterval:[request timeoutInterval]];
  [r addValue:@"1" forHTTPHeaderField:@"Icy-Metadata"];
  
  return r;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
  // Should read headers, specially Icy-metaint header and store the value
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
  
  NSDictionary *headers = [httpResponse allHeaderFields];
  NSString headerValue;
  if ((headerValue = [headers objectForKey:@"Icy-metaint"]) != nil) {
    metaint = [headerValue intValue];
  }
}

- (NSData *)connection:(NSURLConnection *)connection
            filterData:(NSData *)data {
  // Then it starts counting from the end of the headers until a block has
  // ended, read the metadata block length, and then the metadata. And again
  // starts counting for the block end.
  
  if (metaint == -1) return data;
  
  
  // >_____|____|_____*
  if (counter + [data length] > metaint) {
    NSMutableData *d = [NSMutableData dataWithData:data];
    
    if (!metadata) {
      int metadataStart = metaint - counter;
      void *bytes = [d mutableBytes];
      metadataLength = (unsigned char) bytes[metadataStart] * 16;
      counter += ([d length] % metaint) - metadataLength;
      metadata = malloc(sizeof(unsigned char) * metadataLength);
      if (!metadata) { // Ouch!
        // We simply return the data
        return data;
      }
      
      // TODO
    } else {
      counter += [d length];
    }
    
    [d replaceBytesInRange:NSMakeRange(metadataStart, metadataLength+1) withBytes:NULL length:0];
    
    return d;
  } else {
    counter += [data length];
    
    return data;
  }
}

@end
