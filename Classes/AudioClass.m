//
//  AudioClass.m
//  radio3
//
//  Created by Javier Quevedo on 11/9/08.
//  Copyright Daniel Rodríguez and Javier Quevedo 2008. All rights reserved.
//

#import "AudioClass.h"

// Private implementation
@interface Player ()

@property(nonatomic, assign, readwrite) BOOL isPlaying;
@property(nonatomic, assign, readwrite) BOOL failed;
@property(nonatomic, retain, readwrite) NSError *error;

- (void)startPrivate;

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID
                  flags:(UInt32*)flags;

- (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
     numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions;

- (void)enqueueBuffer;

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer;

- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer;

- (void)isRunning;

@end


// Callbacks
void MyPropertyListenerProc(void *inClientData,
                            AudioFileStreamID inAudioFileStream,
                            AudioFileStreamPropertyID	inPropertyID,
                            UInt32 * ioFlags) {
	Player *player = (Player *)inClientData;
	[player propertyChanged:inPropertyID flags:ioFlags];
}

void MyPacketsProc(void *inClientData,
                   UInt32 inNumberBytes,
                   UInt32 inNumberPackets,
                   const void *inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions) {
	Player *player = (Player *)inClientData;
	[player packetData:inInputData
     numberOfPackets:inNumberPackets
       numberOfBytes:inNumberBytes
  packetDescriptions:inPacketDescriptions];
}

void MyAudioQueueOutputCallback(void *inClientData,
                                AudioQueueRef inAQ,
                                AudioQueueBufferRef inBuffer)
{
	Player *player = (Player *)inClientData;
	[player outputCallbackWithBufferReference:inBuffer];
}

void MyAudioQueueIsRunningCallback(void *inClientData,
                                   AudioQueueRef inAQ,
                                   AudioQueuePropertyID inID) {
  Player *player = (Player *)inClientData;
  [player isRunning];
}



@implementation Player

@synthesize isPlaying, failed, error;

- (id)initWithString:(NSString *)urlString {
  return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL *)newUrl {
	self = [super init];
  if (self != nil) {
    url = [newUrl retain];
  }
  
  return self;
}

- (void)dealloc {
  [url release];
  [connection release];
	[super dealloc];
}

- (void)start {
  [NSThread detachNewThreadSelector:@selector(startPrivate)
                           toTarget:self
                         withObject:nil];
}

- (void)startPrivate {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  AudioFileTypeID fileTypeHint = 0;
  NSString *fileExtension = [[url path] pathExtension];
  
  if ([fileExtension compare:@"mp3"
                     options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileMP3Type;
  } else if ([fileExtension compare:@"wav"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileWAVEType;
  } else if ([fileExtension compare:@"aifc"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileAIFCType;
  } else if ([fileExtension compare:@"aiff"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileAIFFType;
  } else if ([fileExtension compare:@"m4a"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileM4AType;
  } else if ([fileExtension compare:@"mp4"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileMPEG4Type;
  } else if ([fileExtension compare:@"caf"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileCAFType;
  } else if ([fileExtension compare:@"aac"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    fileTypeHint = kAudioFileAAC_ADTSType;
  }
  
  pthread_mutex_init(&mutex, NULL);
  pthread_cond_init(&cond, NULL);
  
  OSStatus err = AudioFileStreamOpen(self,
                                     MyPropertyListenerProc,
                                     MyPacketsProc,
                                     fileTypeHint,
                                     &audioFileStream);
  
  if (err) {
    RNLog(@"AudioFileStreamOpen err %d", err);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    self.failed = YES;
    return;
  }
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:30];
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  do {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                       0.25,
                       false);
    
    if (failed) {
      [self stop];
      
      break;
    }
  } while (!finished || isPlaying);
  
  err = AudioFileStreamClose(audioFileStream);
  if (err) {
    RNLog(@"AudioFileStreamClose err %d", err);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    // FIX: self.failed = true ?
    return;
  }
  
  if (started) {
    err = AudioQueueDispose(audioQueue, true);
    if (err) {
      RNLog(@"AudioQueueDispose err %d", err);
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      // FIX: self.failed = true ?
      return;
    }
  }
    
  [pool release];
}

- (void)stop {
  if (connection) {
    [connection cancel];
    [connection release];
    connection = nil;
  }
  
  if (started && !finished) {
    finished = YES;
    
		OSStatus err = AudioQueueStop(audioQueue, true);
		if (err) {
      RNLog(@"AudioQueueStop failed");
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      // FIX: self.failed = true ?
      return;
    }
    
    pthread_mutex_lock(&mutex);
    pthread_cond_signal(&cond);
    pthread_mutex_unlock(&mutex);
  } else {
    self.isPlaying = YES;
    self.isPlaying = FALSE;
    finished = YES;
  }
}

- (void)pause {
	if (!isPlaying)
		return;
	AudioQueuePause(audioQueue);
}

- (void)setGain:(Float32)gain {
	if (!isPlaying)
		return;
	AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, gain);
}



// NSConnection delegate method
- (NSCachedURLResponse *)connection:(NSURLConnection *)inConnection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
}

// NSConnection delegate method
- (void)connection:(NSURLConnection*)inConnection didReceiveData:(NSData*)data {
  if (failed)
    return;
  
  if (!finished) {
    if (discontinuous) {
      OSStatus err = AudioFileStreamParseBytes(audioFileStream,
                                               [data length],
                                               [data bytes],
                                               kAudioFileStreamParseFlag_Discontinuity);
      if (err) {
        RNLog(@"AudioFileStreamParseBytes 1 err %d", err);
        self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:err
                                     userInfo:nil];
        self.failed = YES;
      }
    } else {
      OSStatus err = AudioFileStreamParseBytes(audioFileStream,
                                               [data length],
                                               [data bytes],
                                               0);
      if (err) {
        RNLog(@"AudioFileStreamParseBytes 2 err %d", err);
        self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:err
                                     userInfo:nil];
        self.failed = YES;
      }
    }
  }
}

// NSConnection delegate method
- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection {
  if (failed) {
    return;
  }
  
  if (!finished && started) {
    if (bytesFilled) {
      [self enqueueBuffer];
    }
    
    OSStatus err = AudioQueueFlush(audioQueue);
    if (err) {
      RNLog(@"AudioQueueFlush err %d", err);
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      // FIX: self.failed = true ?
      return;
    }
    
    err = AudioQueueStop(audioQueue, false);
    if (err) {
      RNLog(@"AudioQueueStop err %d", err);
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      // FIX: self.failed = true ?
      return;
    }
  } else if (!started) {
    self.failed = YES;
    [self stop];
    return;
  }
  
  [connection release];
  connection = nil;
}

// NSConnection delegate method
- (void)connection:(NSURLConnection *)inConnection
  didFailWithError:(NSError *)inError {
  RNLog(@"Connection did fail error %@", inError.localizedDescription);
  self.error = inError;
  self.failed = YES;
  [self stop];
}


// Private methods
- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID
                  flags:(UInt32*)flags {
	OSStatus err = noErr;
	
	switch (propertyID) {
		case kAudioFileStreamProperty_ReadyToProducePackets:
		{
      discontinuous = YES;
      
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			
			err = AudioFileStreamGetProperty(audioFileStream,
                                       kAudioFileStreamProperty_DataFormat,
                                       &asbdSize,
                                       &asbd);
			if (err) {
        RNLog(@"get kAudioFileStreamProperty_DataFormat failed");
        self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:err
                                     userInfo:nil];
        self.failed = YES;
        break;
      }
			
			err = AudioQueueNewOutput(&asbd,
                                MyAudioQueueOutputCallback,
                                self,
                                NULL,
                                NULL,
                                0,
                                &audioQueue);
			if (err) {
        RNLog(@"AudioQueueNewOutput err %d", err);
        self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:err
                                     userInfo:nil];
        self.failed = YES;
        break;
      }
      
      err = AudioQueueAddPropertyListener(audioQueue,
                                          kAudioQueueProperty_IsRunning,
                                          MyAudioQueueIsRunningCallback,
                                          self);
      if (err) {
        RNLog(@"AudioQueueAddPropertyListener err %d", err);
        self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:err
                                     userInfo:nil];
        self.failed = YES;
        break;
      }
			
      for (unsigned int i = 0; i < kNumAQBufs; ++i) {
        err = AudioQueueAllocateBuffer(audioQueue,
                                       kAQBufSize,
                                       &audioQueueBuffer[i]);
        
        if (err) {
          RNLog(@"AudioQueueAllocateBuffer err %d", err);
          self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                           code:err
                                       userInfo:nil];
          self.failed = YES;
          break; // FIX: break for or break case?
        }
      }
      
			UInt32 cookieSize;
      Boolean writable;
      err = AudioFileStreamGetPropertyInfo(audioFileStream,
                                           kAudioFileStreamProperty_MagicCookieData,
                                           &cookieSize,
                                           &writable);
      
      if (err) {
        RNLog(@"info kAudioFileStreamProperty_MagicCookieData %d", err);
        break;
      }
      
      void *cookieData = calloc(1, cookieSize);
      
      if (!cookieData) {
        RNLog(@"calloc cookieData");
        break;
      }
      
      err = AudioFileStreamGetProperty(audioFileStream,
                                       kAudioFileStreamProperty_MagicCookieData,
                                       &cookieSize,
                                       cookieData);
      
      if (err) {
        RNLog(@"get kAudioFileStreamProperty_MagicCookieData %d", err);
        free(cookieData);
        break;
      }
      
      err = AudioQueueSetProperty(audioQueue,
                                  kAudioQueueProperty_MagicCookie,
                                  cookieData,
                                  cookieSize);
      free(cookieData);
      
      if (err) {
        RNLog(@"set kAudioQueueProperty_MagicCookie %d", err);
        break;
      }
      
			break;
		}
			
	}
}

- (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
     numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions {
  
  discontinuous = NO;
  
  if (packetDescriptions) {
    for (int i = 0; i < numPackets; i++) {
      SInt64 packetOffset = packetDescriptions[i].mStartOffset;
      SInt64 packetSize = packetDescriptions[i].mDataByteSize;
      
      size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
      if (bufSpaceRemaining < packetSize) {
        [self enqueueBuffer];
      }
      
      if (finished) {
        return;
      }
      
      AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
      memcpy((char*) fillBuf->mAudioData + bytesFilled,
             (const char*) data + packetOffset,
             packetSize);
      packetDescs[packetsFilled] = packetDescriptions[i];
      packetDescs[packetsFilled].mStartOffset = bytesFilled;
      bytesFilled += packetSize;
      packetsFilled += 1;
      
      size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
      if (packetsDescsRemaining == 0) {
        [self enqueueBuffer];
      }
    }
	} else {
    size_t offset = 0;
    while (numBytes) {
      size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
      if (bufSpaceRemaining < numBytes) {
        [self enqueueBuffer];
      }
      
      if (finished) {
        return;
      }
      
      AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
      bufSpaceRemaining = kAQBufSize - bytesFilled;
      size_t copySize =
        (bufSpaceRemaining < numBytes) ? bufSpaceRemaining : numBytes;
      memcpy((char *) fillBuf->mAudioData + bytesFilled,
             (const char *) (data + offset),
             copySize);
      
      bytesFilled += copySize;
      packetsFilled = 0;
      numBytes -= copySize;
      offset += copySize;
    }
  }
}

- (void)enqueueBuffer {
	OSStatus err = noErr;
	inuse[fillBufferIndex] = YES;
	
	AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
	fillBuf->mAudioDataByteSize = bytesFilled;

	if (packetsFilled) {
    err = AudioQueueEnqueueBuffer(audioQueue,
                                  fillBuf,
                                  packetsFilled,
                                  packetDescs);
  } else {
    err = AudioQueueEnqueueBuffer(audioQueue,
                                  fillBuf,
                                  0,
                                  NULL);
  }
  
	if (err) {
    RNLog(@"AudioQueueEnqueueBuffer failed %d", err);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    self.failed = YES;
    return;
  }
	
	
	if (!started) {
    [self retain];
		err = AudioQueueStart(audioQueue, NULL);
		
    if (err) {
      RNLog(@"AudioQueueStart failed");
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      self.failed = YES;
      return;
    }
    
		started = YES;
	}	
	
  if (++fillBufferIndex >= kNumAQBufs) {
    fillBufferIndex = 0;
  }
  bytesFilled = 0;
  packetsFilled = 0;
  
  pthread_mutex_lock(&mutex);
  while (inuse[fillBufferIndex] && !finished) {
    pthread_cond_wait(&cond, &mutex);
    
    if (finished) {
      break;
    }
  }
  pthread_mutex_unlock(&mutex);
}

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer {
	for (unsigned int i = 0; i < kNumAQBufs; i++) {
		if (inBuffer == audioQueueBuffer[i]) {
			return i;
		}
	}
	return -1;
}

- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer {
	
  unsigned int bufIndex = [self findQueueBuffer:buffer];
  
  pthread_mutex_lock(&mutex);
  inuse[bufIndex] = NO;
  pthread_cond_signal(&cond);
  pthread_mutex_unlock(&mutex);
}

- (void)isRunning {
  RNLog(@"isRunning callback invoked");
  self.isPlaying = !self.isPlaying;
  
  if (!isPlaying) {
    finished = YES;
    [self release];
    return;
  }
}

@end

