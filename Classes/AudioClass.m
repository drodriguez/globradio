#import "AudioClass.h"

NSString *PlayerDidStopNotification = @"PlayerDidStopNotification";
NSString *PlayerAudioDidEndedPlayingNotification =
  @"PlayerAudioDidEndedPlayingNotification";
NSString *PlayerDidFinishedPlayingNotification =
  @"PlayerDidFinishedPlayingNotification";
NSString *PlayerDidEstablishConnection = @"PlayerDidEstablishConnection";
NSString *PlayerProducedAnErrorNotification =
  @"PlayerProducedAnErrorNotification";

// Private implementation
@interface Player ()

- (void)startPrivate;

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID
                  flags:(UInt32*)flags;

- (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
     numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions;

// - (void)playBackIsRunningStateChanged;

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

@synthesize delegate;

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
    // TODO: Warn the delegate?
    NSLog(@"AudioFileStreamOpen err %d", err);
    return;
  }
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  do {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                       0.25,
                       false);
    
    if (failed) {
      [self stop];
      
      // TODO: Warn the delegate?
      break;
    }
  } while (!finished || isPlaying);
  
  err = AudioFileStreamClose(audioFileStream);
  if (err) {
    NSLog(@"AudioFileStreamClose err %d", err);
    // TODO: warn the delegate?
    return;
  }
  
  if (started) {
    err = AudioQueueDispose(audioQueue, true);
    if (err) {
      NSLog(@"AudioQueueDispose err %d", err);
      // TODO: warn the delegate?
      return;
    }
  }
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PlayerDidStopNotification
                  object:self]
  
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
      NSLog(@"AudioQueueStop failed");
      // TODO: warn the delegate?
      return;
    }
    
    pthread_mutex_lock(&mutex);
    pthread_cond_signal(&cond);
    pthread_mutex_unlock(&mutex);
  } else {
    // FIX:?
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
- (void)connection:(NSURLConnection *)inconnection
didReceiveResponse:(NSURLResponse *)response {
  // TODO:
  // FIX: we suppose nobody is going to use multipart/x-mixed-replace
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
        NSLog(@"AudioFileStreamParseBytes err %d", err);
        failed = YES;
      }
    } else {
      OSStatus err = AudioFileStreamParseBytes(audioFileStream,
                                               [data length],
                                               [data bytes],
                                               0);
      if (err) {
        NSLog(@"AudioFileStreamParseBytes err %d", err);
        failed = YES;
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
      NSLog(@"AudioQueueFlush err %d", err);
      // TODO: warn the delegate?
      return;
    }
    
    err = AudioQueueStop(audioQueue, false);
    if (err) {
      NSLog(@"AudioQueueStop err %d", err);
      // TODO: warn the delegate?
      return;
    }
  } else if (!started) {
    failed = YES;
    [self stop];
    return;
  }
  
  [connection release];
  connection = nil;
}

// NSConnection delegate method
- (void)connection:(NSURLConnection *)inConnection
  didFailWithError:(NSError *)error {
  [self stop];
  // TODO: warn the delegate?
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
        NSLog(@"get kAudioFileStreamProperty_DataFormat failed");
        failed = true;
        // TODO: warn the delegate?
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
        NSLog(@"AudioQueueNewOutput err %d", err);
        failed = true;
        // TODO: warn the delegate?
        break;
      }
      
      err = AudioQueueAddPropertyListener(audioQueue,
                                          kAudioQueueProperty_IsRunning,
                                          MyAudioQueueIsRunningCallback,
                                          self);
      if (err) {
        NSLog(@"AudioQueueAddPropertyListener err %d", err);
        failed = true;
        // TODO: warn the delegate;
        break;
      }
			
      for (unsigned int i = 0; i < kNumAQBufs; ++i) {
        err = AudioQueueAllocateBuffer(audioQueue,
                                       kAQBufSize,
                                       &audioQueueBuffer[i]);
        
        if (err) {
          NSLog(@"AudioQueueAllocateBuffer err %d", err);
          failed = true;
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
        NSLog(@"info kAudioFileStreamProperty_MagicCookieData %d", err);
        break;
      }
      
      void *cookieData = calloc(1, cookieSize);
      
      if (!cookieData) {
        NSLog(@"calloc cookieData");
        break;
      }
      
      err = AudioFileStreamGetProperty(audioFileStream,
                                       kAudioFileStreamProperty_MagicCookieData,
                                       &cookieSize,
                                       cookieData);
      
      if (err) {
        NSLog(@"get kAudioFileStreamProperty_MagicCookieData %d", err);
        free(cookieData);
        break;
      }
      
      err = AudioQueueSetProperty(audioQueue,
                                  kAudioQueueProperty_MagicCookie,
                                  cookieData,
                                  cookieSize);
      free(cookieData);
      
      if (err) {
        NSLog(@"set kAudioQueueProperty_MagicCookie %d", err);
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
    NSLog(@"AudioQueueEnqueueBuffer failed %d", err);
    failed = YES;
    // TODO: warn the delegate?
    return;
  }
	
	
	if (!started) {
    // FIX: ??
		err = AudioQueueStart(audioQueue, NULL);
		
    if (err) {
      NSLog(@"AudioQueueStart failed");
      failed = YES;
      // TODO: warn the delegate?
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
  isPlaying = !isPlaying;
  
  if (!isPlaying) {
    finished = true;
    [self release];
    return;
  }
}

- (void)postTrackFinishedPlayingNotification:(id)object {
	[[NSNotificationCenter defaultCenter]
   postNotificationName:PlayerDidFinishedPlayingNotification object:self];
}

/* - (void)playBackIsRunningStateChanged {
	if (ended) {
		// go ahead and close the track now
		closed = YES;
		AudioQueueDispose(audioQueue, YES);
		AudioFileStreamClose(audioFileStream);
		NSLog(@"audioQueueBuffer before freeing: %p",audioQueueBuffer);
		free(audioQueueBuffer);
		audioQueueBuffer = (AudioQueueBufferRef*)0x0;
		[self performSelectorOnMainThread:@selector(postTrackFinishedPlayingNotification:)
                           withObject:nil
                        waitUntilDone:NO];
	}
} */

@end

