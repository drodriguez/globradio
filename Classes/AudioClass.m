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

#pragma mark Callbacks

/**
 * MyPropertyListenerProc
 *
 * See propertyChanged:flags:.
 */
void MyPropertyListenerProc(void *inClientData,
                            AudioFileStreamID inAudioFileStream,
                            AudioFileStreamPropertyID	inPropertyID,
                            UInt32 * ioFlags) {
	Player *player = (Player *)inClientData;
	[player propertyChanged:inPropertyID flags:ioFlags];
}

/**
 * MyPacketsProc
 *
 * See packetData:numberOfPackets:numberOfBytes:packetDescriptions:.
 */
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

/**
 * MyAudioQueueOutputCallback
 *
 * See outputCallbackWithBufferReference:.
 */
void MyAudioQueueOutputCallback(void *inClientData,
                                AudioQueueRef inAQ,
                                AudioQueueBufferRef inBuffer)
{
	Player *player = (Player *)inClientData;
	[player outputCallbackWithBufferReference:inBuffer];
}

/**
 * MyAudioQueueIsRunningCallback
 *
 * See isRunning.
 */
void MyAudioQueueIsRunningCallback(void *inClientData,
                                   AudioQueueRef inAQ,
                                   AudioQueuePropertyID inID) {
  Player *player = (Player *)inClientData;
  [player isRunning];
}



@implementation Player

@synthesize isPlaying, failed, error, connectionFilter;

/**
 * initWithString:
 *
 * Uses the string as URL, and no audio type hint.
 */
- (id)initWithString:(NSString *)urlString {
  return [self initWithURL:[NSURL URLWithString:urlString] audioTypeHint:0];
}

/**
 * initWithString:audioTypeHint:
 *
 * Uses the string as URL and also the audio type hint.
 */
- (id)initWithString:(NSString *)urlString audioTypeHint:(AudioFileTypeID)newAudioHint {
  return [self initWithURL:[NSURL URLWithString:urlString] audioTypeHint:newAudioHint];
}

/**
 * initWithURL:
 *
 * Uses the URL, and no audio type hint.
 */
- (id)initWithURL:(NSURL *)newUrl {
  return [self initWithURL:newUrl audioTypeHint:0];
}

/**
 * initWithURL:audioTypeHint:
 *
 * Uses the URL, and also audio type hint.
 */
- (id)initWithURL:(NSURL *)newUrl audioTypeHint:(AudioFileTypeID)newAudioHint {
	self = [super init];
  if (self != nil) {
    url = [newUrl retain];
    audioHint = newAudioHint;
  }
  
  return self;
}

/**
 * dealloc
 *
 * Releases resources.
 */
- (void)dealloc {
  [url release];
  [connection release];
	[super dealloc];
}

/**
 * guessAudioFormat
 *
 * Try to guess audio format based on the extension from the URL. If the audio
 * file hint is different than 0, this method does nothing. If the guess do not
 * work for the stream, and we have a fixed file type we can always create the
 * player with an audio type hint.
 *
 * Reading the MIME type from the NSURLConnection would be a better approach
 * since lots of URLs don't have the right extension.
 */
- (void)guessAudioFormat {
  // If user have set an audio hint, do not guess
  if (audioHint != 0) return;
  
  NSString *fileExtension = [[url path] pathExtension];
  
  if ([fileExtension compare:@"mp3"
                     options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileMP3Type;
  } else if ([fileExtension compare:@"wav"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileWAVEType;
  } else if ([fileExtension compare:@"aifc"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileAIFCType;
  } else if ([fileExtension compare:@"aiff"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileAIFFType;
  } else if ([fileExtension compare:@"m4a"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileM4AType;
  } else if ([fileExtension compare:@"mp4"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileMPEG4Type;
  } else if ([fileExtension compare:@"caf"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileCAFType;
  } else if ([fileExtension compare:@"aac"
                            options:NSCaseInsensitiveSearch] == NSOrderedSame) {
    audioHint = kAudioFileAAC_ADTSType;
  }
}

/**
 * start
 *
 * Start the audio playing in another thread. See startPrivate.
 */
- (void)start {
  [NSThread detachNewThreadSelector:@selector(startPrivate)
                           toTarget:self
                         withObject:nil];
}

/**
 * startPrivate
 *
 * This is the start method for the AudioStream thread. This thread is created
 * because it will be blocked when there are no audio buffers idle (and ready to
 * receive audio data).
 *
 * Activity in this thread (maybe it is not in this method):
 * - Creation and cleanup of all AudioFileStream and AudioQueue objects.
 * - Receives data from the NSURLConnection.
 * - AudioFileStream processing.
 * - Copying of data from AudioFileStream into audio buffers.
 * - Stopping of the thread because end-of-file.
 * - Stopping due to error or failure.
 *
 * Activity *not* in this thread:
 * - AudioQueue playback and notifications (happens in AudioQueue thread).
 * - Actual download of NSURLConnectio data (NSURLConnection's thread).
 * - Creation of the AudioStreamer (other, likely "main" thread).
 * - Invocation of -start method (other, likely "main" thread).
 * - User/manual invocation of -stop (other, likely "main" thread).
 *
 * This method contains bits of the "main" function from Apple's example in
 * AudioFileStreamExample.
 */
- (void)startPrivate {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Attempt to guess the file type.
  [self guessAudioFormat];
  
  // Initialize a mutex and condition so that we can block on buffers in use.
  pthread_mutex_init(&mutex, NULL);
  pthread_cond_init(&cond, NULL);
  pthread_mutex_init(&audioQueueBufferMutex, NULL);
  
  // Create an audio file stream parser.
  OSStatus err = AudioFileStreamOpen(self,
                                     MyPropertyListenerProc,
                                     MyPacketsProc,
                                     audioHint,
                                     &audioFileStream);
  
  if (err) {
    RNLog(@"AudioFileStreamOpen err %d", err);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    self.failed = YES;
    return;
  }
  
  // Create the request.
  NSURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:30];
  // Invoke the connection filter, so it can add headers or whatever.
  if ([connectionFilter respondsToSelector:@selector(modifyRequest:)]) {
    request = [connectionFilter modifyRequest:request];
  }
  
  connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  
  // FIXME: drodriguez: think this code is innecesary, but...
  OSStatus status = AudioSessionSetActive(true);
  if (status != kAudioSessionNoError) { RNLog(@"AudioSessionSetActive err %d", status); }
  
  // Process the run loop until playback is finished or failed.
  do {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                       0.25,
                       false);
    
    if (failed) {
      [self stop];
      
      break;
    }
  } while (!finished || isPlaying);
  
  // Close the audio file stream.
  err = AudioFileStreamClose(audioFileStream);
  if (err) {
    RNLog(@"AudioFileStreamClose err %d", err);
    self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                     code:err
                                 userInfo:nil];
    // FIX: self.failed = true ?
    return;
  }
  
  // Dispose the Audio Queue.
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

/**
 * stop
 *
 * This method can be called to stop downloading/playback before it completes.
 * It is automatically called when an error occurs.
 *
 * If playback has not started before this method is called, it will toggle the
 * "isPlaying" property so that it is guaranteed to transition to the true back
 * to false.
 */
- (void)stop {
  if (connection) {
    [connection cancel];
    [connection release];
    connection = nil;
  }
    
  if (started && !finished) {
    /*
     * Set finishes to true *before* we call stop. This is to handle our third
     * thread...
     * - This method is called from main (UI) thread.
     * - The AudioQueue thread (which owns the AudioQueue buffers and will
     *   delete them as soon as soon as we call AudioQueueStop).
     * - URL connection thread is copying data from AudioStream to AudioQueue
     *   buffer.
     * We set this flag to tell the URL connection thread to stop copying.
     */
    pthread_mutex_lock(&audioQueueBufferMutex);
    finished = YES;
    
		OSStatus err = AudioQueueStop(audioQueue, true);
		if (err) {
      RNLog(@"AudioQueueStop failed");
      self.error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                       code:err
                                   userInfo:nil];
      // FIX: self.failed = true ?
    }
    pthread_mutex_unlock(&audioQueueBufferMutex);
    
    pthread_mutex_lock(&mutex);
    pthread_cond_signal(&cond);
    pthread_mutex_unlock(&mutex);
  } else {
    self.isPlaying = YES;
    self.isPlaying = FALSE;
    finished = YES;
  }
}

/**
 * pause
 *
 * Pauses the AudioQueue, but do not pause the downloading thread. Should not be
 * used.
 */
- (void)pause {
	if (!isPlaying)
		return;
	AudioQueuePause(audioQueue);
}

/**
 * setGain:
 *
 * Set the gain of the AudioQueue (volume). Should not be used.
 */
- (void)setGain:(Float32)gain {
	if (!isPlaying)
		return;
	AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, gain);
}

#pragma mark NSURLConnection delegate methods

/**
 * connection:willCacheResponse:
 *
 * Do *not* cache the response.
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)inConnection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  return nil;
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
    
    // Filter the data in the connection filter.
    if ([connectionFilter respondsToSelector:@selector(connection:filterData:)]) {
      data = [connectionFilter connection:inConnection filterData:data];
    }
    
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

/**
 * connectionDidFinishLoading:
 *
 * Enqueue the last buffer (if necessary) and establish the state for closing
 * the AudioQueue.
 */
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

/**
 * connection:didFailWithError:
 *
 * Stops the player if some connection error happens.
 */
- (void)connection:(NSURLConnection *)inConnection
  didFailWithError:(NSError *)inError {
  RNLog(@"Connection did fail error %@", inError.localizedDescription);
  self.error = inError;
  self.failed = YES;
  [self stop];
}


#pragma mark Private methods

/**
 * propertyChanged:flags:
 *
 * See MyPropertyListener.
 *
 * Receives notification when AudioFileStream has audio packets to be
 * played. In response, this function creates the AudioQueue, getting it
 * ready to begin playback (playback won't begin until audio packets are
 * sent to the queue in enqueueBuffer).
 *
 * This function is adapted from Apple's example in AudioFileStreamExample with
 * kAudioQueueProperty_IsRunning listening added.
 */
- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID
                  flags:(UInt32*)flags {
	OSStatus err = noErr;
	
	switch (propertyID) {
		case kAudioFileStreamProperty_ReadyToProducePackets:
		{
      discontinuous = YES;
      
      // The file stream parser is not ready to produce packets.
      // Get the stream format.
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
			
      // Create the audio queue.
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
      
      // Listen to the "isRunning" property.
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
			
      // Allocate audio queue buffers
      // FIXME: Maybe we should make the buffer size dynamic depending on the
      // stream bitrate.
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
      
      // Get the cookie size.
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
      
      // Get the cookie data.
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
      
      // Set the cookie on the queue (if needed).
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

/**
 * packetData:numberOfPackets:numberOfBytes:packetDescriptions:
 *
 * See MyPacketsProc.
 *
 * When the AudioStream has packets to be played, this function gets and idle
 * audio buffer and copies the audio packets into it. The calls to enqueueBuffer
 * won't return until there are buffers available (or the playback has been
 * stopped).
 *
 * This function is adapted from Apple's example in AudioFileStreamExample with
 * CBR functionality added.
 */
- (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
     numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions {
  
  // We have sucessfully read the first packets from the audio stream, so clear
  // the "discontinuous" flag.
  discontinuous = NO;
  
  // First branch is for VBR data, the second branch is for CBR data.
  if (packetDescriptions) {
    for (int i = 0; i < numPackets; i++) {
      SInt64 packetOffset = packetDescriptions[i].mStartOffset;
      SInt64 packetSize = packetDescriptions[i].mDataByteSize;
      
      // If the audio was terminated before this point, then exit.
      if (finished) {
        return;
      }      
      
      // If the space remaining in the buffer is not enough for this packet,
      // then enqueue the buffer.
      size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
      if (bufSpaceRemaining < packetSize) {
        [self enqueueBuffer];
      }
      
      pthread_mutex_lock(&audioQueueBufferMutex);
      // If the audio was terminated while waiting for a buffer, then exit.
      if (finished) {
        pthread_mutex_unlock(&audioQueueBufferMutex);
        return;
      }
      
      // Copy data to the audio buffer queue.
      AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
      memcpy((char*) fillBuf->mAudioData + bytesFilled,
             (const char*) data + packetOffset,
             packetSize);
      pthread_mutex_unlock(&audioQueueBufferMutex);
      
      // Fill packet description.
      packetDescs[packetsFilled] = packetDescriptions[i];
      packetDescs[packetsFilled].mStartOffset = bytesFilled;
      // Keep track of buyes filled and packets filled.
      bytesFilled += packetSize;
      packetsFilled += 1;
      
      // If that was the last free packet description, then enqueue the buffer.
      size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
      if (packetsDescsRemaining == 0) {
        [self enqueueBuffer];
      }
    }
	} else {
    size_t offset = 0;
    while (numBytes) {
      // If the space remaining in the buffer is not enough for this packet,
      // the enqueue the buffer.
      size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
      if (bufSpaceRemaining < numBytes) {
        [self enqueueBuffer];
      }
      
      pthread_mutex_lock(&audioQueueBufferMutex);
      // If the audio was terminated while waiting for a buffer, then exit.
      if (finished) {
        pthread_mutex_unlock(&audioQueueBufferMutex);
        return;
      }
      
      // Copy data to the audio buffer queue.
      AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
      bufSpaceRemaining = kAQBufSize - bytesFilled;
      size_t copySize =
        (bufSpaceRemaining < numBytes) ? bufSpaceRemaining : numBytes;
      memcpy((char *) fillBuf->mAudioData + bytesFilled,
             (const char *) (data + offset),
             copySize);
      
      pthread_mutex_unlock(&audioQueueBufferMutex);
      
      // Keep track of bytes filled and packets filled.
      bytesFilled += copySize;
      packetsFilled = 0;
      numBytes -= copySize;
      offset += copySize;
    }
  }
}

/**
 * enqueueBuffer
 *
 * Called from packetData:numberOfPackets:numberOfBytes:packetDescriptions: and
 * connection:didFinishLoading to pass filled audio buffers (filled by
 * packetData:...) to the AudioQueue for playback. This function does not return
 * until a buffer is idle for further filling or the AudioQueue has stopped.
 *
 * This function is adapted from Apple's example in AudioFileStreamExample with
 * CBR functionality added.
 */
- (void)enqueueBuffer {
	OSStatus err = noErr;
	inuse[fillBufferIndex] = YES; // Set in use flag.
	
  // Enqueue buffer.
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
	
	
	if (!started) { // Start the queue if it has not been started already.
    [self retain]; // TODO: remove?
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
	
  // Go to next buffer.
  if (++fillBufferIndex >= kNumAQBufs) {
    fillBufferIndex = 0;
  }
  // Reset bytes and packets filled.
  bytesFilled = 0;
  packetsFilled = 0;
  
  // Wait until next buffer is not in use.
  pthread_mutex_lock(&mutex);
  while (inuse[fillBufferIndex] && !finished) {
    pthread_cond_wait(&cond, &mutex);
  }
  pthread_mutex_unlock(&mutex);
}

/**
 * findQueueBuffer:
 *
 * Returns the index of the specified buffer in the audioQueueBuffer array.
 *
 * This function is adapted from Apple's example in AudioFileStreamExample.
 */
- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer {
	for (unsigned int i = 0; i < kNumAQBufs; i++) {
		if (inBuffer == audioQueueBuffer[i]) {
			return i;
		}
	}
	return -1;
}

/**
 * outputCallbackWithBufferReference:
 *
 * See MyAudioQueueOutputCallback.
 *
 * Called from the AudioQueue when playback of the specific buffers completes.
 * This method signals from the AudioQueue thread to the AudioStream thread that
 * the buffer is idle and available for copying data.
 *
 * This function is adapted from Apple's example in AudioFileStreamExample.
 */
- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer {
	
  unsigned int bufIndex = [self findQueueBuffer:buffer];
  
  // Signal waiting thread that the buffer is free.
  pthread_mutex_lock(&mutex);
  inuse[bufIndex] = NO;
  pthread_cond_signal(&cond);
  pthread_mutex_unlock(&mutex);
}

/**
 * isRunning
 *
 * See MyAudioQueueIsRunningCallback.
 *
 * Called from the AudioQueue when playback is started or stopped. This
 * information is used to toggle the observable "isPlaying" property and set the
 * "finished" flag.
 */
- (void)isRunning {
  RNLog(@"isRunning callback invoked");
  // TODO: change?
  self.isPlaying = !self.isPlaying;
  
  if (!isPlaying) {
    finished = YES;
    [self release];
    return;
  }
}

@end

