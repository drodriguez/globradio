//
//  RRQShoutcastAudioPlayer.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 23/01/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RRQShoutcastAudioPlayer.h"

@interface RRQShoutcastAudioPlayer ()

@property(nonatomic, assign, readwrite) BOOL failed;
@property(nonatomic, retain, readwrite) NSError *error;
@property(nonatomic, retain, readwrite) NSDictionary *headers;

- (void)filterMetadataFrom:(NSData *)data;
- (void)parseMetadataAt:(unsigned int)offset;
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

@implementation RRQShoutcastAudioPlayer

@synthesize headers = headers_;
@synthesize delegate;

@dynamic failed;
@dynamic error;

/**
 * initWithURL:audioTypeHint:
 *
 * Overriden. Uses the URL, and also audio type hint.
 */
- (id)initWithURL:(NSURL *)newUrl audioTypeHint:(AudioFileTypeID)newAudioHint {
  if (self = [super initWithURL:newUrl audioTypeHint:newAudioHint]) {
    metadataInterval = -1;
  }
  
  return self;
}

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
  if (length <= 0) return;
  
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
    [self parseMetadataAt:0];
  }
  
  // RNLog(@"length %d", length);
  while (left > 0) {
    // RNLog(@"left %d", left);
    if (byteCounter + left > metadataInterval) {
      // RNLog(@"metadatos!");
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
        [self parseMetadataAt:metadataStart];
      }
      
      // RNLog(@"-left %d", left);
      int audioLength = left > metadataInterval ? metadataInterval : left;
      // RNLog(@"audioLength %d", audioLength);
      [self audioFileStream:audioFileStream
                 parseBytes:bytes+metadataStart+1+copyLength
                     length:audioLength];
      byteCounter += audioLength;
      left -= audioLength;
    } else {
      // RNLog(@"resto sin metadatos");
      [self audioFileStream:audioFileStream
                 parseBytes:bytes+(length-left)
                     length:left];
      byteCounter += left;
      break;
    }
  }
  // RNLog(@"no more left");
}

- (void)parseMetadataAt:(unsigned int)offset {
  if (metadataCounter < metadataLength) return;
    
  if (metadataLength > 0) {
    RNLog(@"metadata: %s", metadata);
  } else {
    goto cleanup;
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
        // Send the metadata to the delegate in a new thread
        RNLog(@"Tag found 1: name '%@', value '%@'", tagName, tagValue);
        NSDictionary *dictionary = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:tagValue, tagName, nil];
        [NSThread detachNewThreadSelector:@selector(updateMetadata:)
                                 toTarget:self
                               withObject:dictionary];
        [dictionary release];
        [tagName release];
        [tagValue release];
        tagName = tagValue = nil;
        
        start = metadata+index+1;
        state = RMStateReadingName;
      }
    } else if (state & RMStateReadingSemicolon) {
      if (bytes[index] == ';') {
        // We have already stored tagValue
        
        // Send the metadata to the delegate in a new thread
        RNLog(@"Tag found 2: name '%@', value '%@'", tagName, tagValue);
        NSDictionary *dictionary = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:tagValue, tagName, nil];
        [NSThread detachNewThreadSelector:@selector(updateMetadata:)
                                 toTarget:self
                               withObject:dictionary];
        [dictionary release];
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

cleanup:
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
  
  [NSThread detachNewThreadSelector:@selector(updateMetadata:)
                           toTarget:self
                         withObject:self.headers];
  
  headerParsed = YES;
  RNLog(@"index = %d", index);
  return index;
}

- (void)updateMetadata:(NSDictionary *)metadataDictionary {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  RNLog(@"updatedMetadata");
  // TODO: store the metadata locally?
  if ([delegate respondsToSelector:@selector(player:updatedMetadata:)]) {
    [delegate player:self updatedMetadata:metadataDictionary];
  }
  
  [pool release];
}

/* Override */
/* - (void)propertyChanged:(AudioFileStreamPropertyID)propertyID
                  flags:(UInt32*)flags {
  [super propertyChanged:propertyID flags:flags];
  
  switch (propertyID) {
    case kAudioFileStreamProperty_DataOffset:
      RNLog(@"hallo");
      SInt64 dataOffset;
      UInt32 dataOffsetSize = sizeof(SInt64);
      OSStatus err = AudioFileStreamGetProperty(audioFileStream,
      kAudioFileStreamProperty_DataOffset,
      &dataOffsetSize,
                                                &dataOffset);
      if (err) RNLog(@"error");
      else RNLog(@"dataOffset %d", dataOffset);
      break;
    default:
      break;
  }
} */

/* Override */
/* - (void)enqueueBuffer {
  bufferCounter++;
  [super enqueueBuffer];
}*/

/* Override */
/*- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer {
  RNLog(@"Processed %d bytes", processedBuffersCounter*kAQBufSize);
  [super outputCallbackWithBufferReference:buffer];
}*/

/* Overriden */
/* - (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
     numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions {
  RNLog(@"unparsing %d, %d bytes", unparsedBytesCounter, numBytes);
  unparsedBytesCounter++;
  [super packetData:data numberOfPackets:numPackets numberOfBytes:numBytes packetDescriptions:packetDescriptions];
} */

- (void)dealloc {
  self.headers = nil;
  if (metadata != NULL) free(metadata);
  
  [super dealloc];
}

@end
