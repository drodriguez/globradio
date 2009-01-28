//
//  ShoutcastAudioClass.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 23/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ShoutcastAudioClass.h"

@interface ShoutcastPlayer ()

@property(nonatomic, assign, readwrite) BOOL failed;
@property(nonatomic, retain, readwrite) NSError *error;
@property(nonatomic, retain, readwrite) NSDictionary *headers;

- (void)filterMetadataFrom:(NSData *)data;
- (void)parseMetadata;
- (int)parseHeader:(NSData *)data;

@end

/** States for the state-machine in readHeader */
enum ReadHeaderState {
  RHStateReadingName  = (1 << 1),
  RHStateReadingValue = (1 << 2),
  RHStateReadingCRLF  = (1 << 3),
  RHStateDone         = (1 << 4)
};

/** States for the state-machine in readMetadata */
enum ReadMetadataState {
  RMStateReadingName              = (1 << 1),
  RMStateReadingDelimitedValue    = (1 << 2),
  RMStateReadingNonDelimitedValue = (1 << 3),
  RMStateReadingApostrophe        = (1 << 4),
  RMStateReadingSemicolon         = (1 << 5)
};

/**
 * readHeader
 *
 * Read a HTTP-like header from data at index and returns the header name and
 * value in the two out-parameters.
 */
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

@implementation ShoutcastPlayer

@synthesize headers = headers_;

@dynamic failed;
@dynamic error;

/**
 * connectionForURL
 *
 * Creates a new NSConnection for the given URL.
 */
- (NSConnection *)connectionForURL:(NSURL *)connectionUrl {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:connectionUrl
                                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                     timeoutInterval:30];
  [request addValue:@"1" forHTTPHeaderField:@"Icy-Metadata"];
  return [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

- (void)audioFileStream:(AudioFileStreamID)afs
             parseBytes:(const void *)bytes
                 length:(UInt32)length {
  
  OSStatus err = AudioFileStreamParseBytes(afs, length, bytes,
                                           (discontinuous ? kAudioFileStreamParseFlag_Discontinuity : 0));
  if (err) {
    RNLog(@"AudioFileStreamParseBytes err %d (%d)", err, discontinuous);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    self.failed = YES;
  }
}  

/**
 * connection:didReceiveData:
 *
 * Sends the data to the AudioFileStream parser.
 */
- (void)connection:(NSURLConnection*)inConnection didReceiveData:(NSData*)data {
  if (failed)
    return;
  
  if (!finished) {
    [self filterMetadataFrom:data];
  }
}

/**
 * filterMetadataFrom
 *
 * Should read headers, specially Icy-metaint header and store the value
 * Then it starts counting from the end of the headers until a block has
 * ended, read the metadata block length, and then the metadata. And again
 * starts counting for the block end.
 */
- (void)filterMetadataFrom:(NSData *)data {
  int start = 0;
  if (!headerParsed) start = [self parseHeader:data];
  
  if (metadataInterval == -1) {
    [self audioFileStream:audioFileStream
               parseBytes:[data bytes]
                   length:[data length]];
    return;
  }
  
  int left, length;
  length = [data length];
  left = length - start;
  const void *bytes = [data bytes];
  
  if (metadata != NULL) { // Metadata wasn't fully read
    int copyLength = MIN(metadataLength - metadataCounter, left);
    memcpy(metadata+metadataCounter, bytes, copyLength);
    left -= copyLength;
    metadataCounter += copyLength;
    [self parseMetadata];
  }
  
  while (left > 0) {
    if (byteCounter + left > metadataInterval) {
      left -= metadataInterval - byteCounter;
      int metadataStart = length - left;
      metadataLength = ((unsigned char *) bytes)[metadataStart] * 16;
      int copyLength = MIN(metadataLength, left);
      left -= copyLength+1;
      byteCounter = 0;
      
      metadata = malloc(sizeof(unsigned char) * metadataLength);
      if (metadata) {
        memcpy(metadata, bytes+metadataStart+1, copyLength);
        metadataCounter += copyLength;
        [self parseMetadata];        
      }
      
      [self audioFileStream:audioFileStream
                 parseBytes:bytes+metadataStart+1+copyLength
                     length:left];
    } else {
      [self audioFileStream:audioFileStream
                 parseBytes:bytes+(length-left)
                     length:left];
      byteCounter += left;
      break;
    }
  }
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
  NSString *tagName = nil, *tagValue = nil;
  
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
        RNLog(@"Tag found: name '%@', value '%@'", tagName, tagValue);
        [tagName release];
        [tagValue release];
        tagName = tagValue = nil;
        
        start = metadata+index+1;
        state = RMStateReadingName;
      }
    } else if (state & RMStateReadingSemicolon) {
      if (bytes[index] == ';') {
        // We have already stored tagValue
        
        // TODO
        RNLog(@"Tag found: name '%@', value '%@'", tagName, tagValue);
        [tagName release];
        [tagValue release];
        tagName = tagValue = nil;
        
        start = metadata+index+1;
        state = RMStateReadingName;
      }
    }
    
    index++;
  }
  
  if (tagName) [tagName release];
  if (tagValue) [tagValue release];
  
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
        metadataInterval = [headerValue intValue];
        RNLog(@"metaint = %d", metadataInterval);
      }
    } else if (headerName != nil) {
      RNLog(@"status line: %@", headerName);
    } else {
      RNLog(@"should not happen");
    }
    headerName = nil;
    headerValue = nil;
  }
  
  self.headers = [NSDictionary dictionaryWithDictionary:parsedHeaders];
  [parsedHeaders release];
  headerParsed = YES;
  RNLog(@"index = %d", index);
  return index;
}

- (void)dealloc {
  self.headers = nil;
  if (metadata != NULL) free(metadata);
  
  [super dealloc];
}

@end
