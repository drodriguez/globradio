//
//  FIShoutcastMetadataFilter.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 29/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FIShoutcastMetadataFilter.h"

@interface FIShoutcastMetadataFilter ()

- (void)parseMetadata;
- (int)parseHeader:(NSData *)data;

@end

enum ReadHeaderState {
  RHStateReadingName  = (1 << 1),
  RHStateReadingValue = (1 << 2),
  RHStateReadingCRLF  = (1 << 3),
  RHStateDone         = (1 << 4)
};

enum ReadMetadataState {
  RMStateReadingName              = (1 << 1),
  RMStateReadingDelimitedValue    = (1 << 2),
  RMStateReadingNonDelimitedValue = (1 << 3),
  RMStateReadingApostrophe        = (1 << 4),
  RMStateReadingSemicolon         = (1 << 5)
};

BOOL readHeader(NSData *data, int *index,
                NSString **headerName, NSString **headerValue) {
  enum ReadHeaderState state = RHStateReadingName;
  
  int length = [data length];
  const unsigned char *bytes = [data bytes];
  const unsigned char *start = bytes+*index;
  
  // fast return if it is a blank line
  if (bytes[*index] == '\r' && bytes[*index+1] == '\n') {
    *index += 2;
    return NO;
  }
  
  while (state != RHStateDone && *index < length) {
    if (state & RHStateReadingCRLF) {
      if (bytes[*index] == '\n') {
        if (state & RHStateReadingName) {
          *headerName = [[[NSString alloc] initWithBytes:start
                                                  length:bytes+*index-start-1
                                                encoding:NSISOLatin1StringEncoding]
                        autorelease];
        } else if (state & RHStateReadingValue) {
          *headerValue = [[[NSString alloc] initWithBytes:start
                                                   length:bytes+*index-start-1
                                                 encoding:NSISOLatin1StringEncoding]
                        autorelease];
        } else {
          RNLog(@"This should not happen");
        }
          
        state = RHStateDone;
      } else {
        state |= ~RHStateReadingCRLF; 
      }
    } else if (state & RHStateReadingName) {
      if (bytes[*index] == ':') {
        *headerName = [[[NSString alloc] initWithBytes:start
                                                 length:bytes+*index-start
                                              encoding:NSISOLatin1StringEncoding]
                      autorelease];
        state = RHStateReadingValue;
        start = bytes+*index+1;
      } else if (bytes[*index] == '\r') {
        state |= RHStateReadingCRLF;
      }
    } else if (state & RHStateReadingValue) {
      if (bytes[*index] == '\r') {
        state |= RHStateReadingCRLF;
      }      
    }
    *index += 1;
  }
  
  return YES;
}


@implementation FIShoutcastMetadataFilter

- (id)init {
  self = [super init];
  if (self != nil) {
    metaint = -1;
    counter = 0;
    totalCounter = 0;
    metadata = NULL;
    metadataLength = 0;
    metadataCounter = 0;
    headerParsed = NO;
    headers = nil;
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

- (NSData *)connection:(NSURLConnection *)connection
            filterData:(NSData *)data {
  // Should read headers, specially Icy-metaint header and store the value
  // Then it starts counting from the end of the headers until a block has
  // ended, read the metadata block length, and then the metadata. And again
  // starts counting for the block end.
  int start = 0;
  if (!headerParsed) start = [self parseHeader:data];
  
  if (metaint == -1) return data;
    
  int left, length;
  NSMutableData *d = [[[NSMutableData alloc] initWithData:data] autorelease];
  length = [d length];
  left = length - start;
  const void *bytes = [d bytes];
    
  if (metadata != NULL) { // Metadata wasn't fully read
    int copyLength = MIN(metadataLength - metadataCounter, left);
    memcpy(metadata+metadataCounter, bytes, copyLength);
    left -= copyLength;
    metadataCounter += copyLength;
    [self parseMetadata];
    [d replaceBytesInRange:NSMakeRange(0, copyLength) withBytes:NULL length:0];
    length -= copyLength;
  }
  
  while (left > 0) {
    if (counter + left > metaint) {
      left -= metaint - counter;
      int metadataStart = length - left;
      metadataLength = ((unsigned char *) bytes)[metadataStart] * 16;
      int copyLength = MIN(metadataLength, left);
      left -= copyLength+1;
      totalCounter += metaint - counter;
      counter = 0;
      
      metadata = malloc(sizeof(unsigned char) * metadataLength);
      if (!metadata) { // Ouch! We simply return the data
        return d;
      }
      
      memcpy(metadata, bytes+metadataStart+1, copyLength);
      metadataCounter += copyLength;
      [self parseMetadata];
      [d replaceBytesInRange:NSMakeRange(metadataStart, copyLength+1) withBytes:NULL length:0];
      length -= copyLength+1;
    } else {
      counter += left;
      totalCounter += left;
      left = 0;
    }
  }
  
  return d;
}

- (void)parseMetadata {
  if (metadataCounter < metadataLength) return;
  
  if (metadataLength > 0) {
    RNLog(@"metadata: %s", metadata);
  }
  
  // Start parsing
  enum ReadMetadataState state = RMStateReadingName;
  
  unsigned int index = 0;
  const unsigned char *bytes = metadata;
  const unsigned char *start = metadata;
  NSString *tagName, *tagValue;
  
  while (index < metadataLength) {
    if (bytes[index] == '\0') { // start of padding
      break;
    } else if (state & RHStateReadingName) {
      if (bytes[index] == '=') {
        tagName = [[NSString alloc] initWithBytes:start
                                           length:bytes+index-start
                                         encoding:NSISOLatin1StringEncoding];
        state = RMStateReadingApostrophe;
        start = metadata+index+1;
      }
    } else if (state & RMStateReadingApostrophe) {
      // Tag values can be or not delimited by apostrophes
      if (bytes[index] == '\'') {
        start++;
        state = RMStateReadingDelimitedValue;
      } else {
        state = RMStateReadingNonDelimitedValue;
      }
    } else if (state & RMStateReadingDelimitedValue) {      
      // jump escaped apostrophes
      if (bytes[index] == '\\' && bytes[index+1] == '\'') {
        index++; // FIX: escaped apostrophes will show in the string
      } else if (bytes[index] == '\'') {
        tagValue = [[NSString alloc] initWithBytes:start
                                            length:bytes+index-start
                                          encoding:NSISOLatin1StringEncoding];
        
        state = RMStateReadingSemicolon;
      }
    } else if (state & RMStateReadingNonDelimitedValue) {
      if (bytes[index] == ';') {
        tagValue = [[NSString alloc] initWithBytes:start
                                            length:bytes+index-start
                                          encoding:NSISOLatin1StringEncoding];
        // TODO
        RNLog(@"Tag found: name '%@', value '%@', totalCounter %d", tagName, tagValue, totalCounter);
        [tagName release];
        [tagValue release];
        
        start = metadata+index+1;
        state = RMStateReadingName;
      }
    } else if (state & RMStateReadingSemicolon) {
      if (bytes[index] == ';') {
        // We have already stored tagValue
        
        // TODO
        RNLog(@"Tag found: name '%@', value '%@', totalCounter %d", tagName, tagValue, totalCounter);
        [tagName release];
        [tagValue release];
        
        start = metadata+index+1;
        state = RMStateReadingName;
      }
    }
    
    index++;
  }  
  
  metadataCounter = 0;
  metadataLength = 0;
  free(metadata);
  metadata = NULL;
}

- (int)parseHeader:(NSData *)data {
  // FIXME: this suppose that the first data received contains the full headers
  
  int index = 0;
  NSString *headerName = nil, *headerValue = nil;
  NSMutableDictionary *parsedHeaders = [[NSMutableDictionary alloc] init];
  
  while (readHeader(data, &index, &headerName, &headerValue)) {
    if (headerName != nil && headerValue != nil) {
      [parsedHeaders setObject:headerValue forKey:headerName];
      if ([headerName caseInsensitiveCompare:@"icy-metaint"] == NSOrderedSame) {
        metaint = [headerValue intValue];
        RNLog(@"metaint = %d", metaint);
      }
    } else if (headerName != nil) {
      RNLog(@"status line: %@", headerName);
    } else {
      RNLog(@"should not happen");
    }
    headerName = nil;
    headerValue = nil;
  }
  
  headers = [[NSDictionary alloc] initWithDictionary:parsedHeaders];
  headerParsed = YES;
  RNLog(@"index = %d", index);
  return index;
}

- (void)dealloc {
  [headers dealloc];
  if (metadata != NULL) free(metadata);
  
  [super dealloc];
}

@end
