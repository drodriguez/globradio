//
//  AudioClass.h
//  radio3
//
//  Created by Javier Quevedo on 11/9/08.
//  Copyright Daniel Rodríguez and Javier Quevedo 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

#define kNumAQBufs 3          // number of audio queue buffers we allocate, at
                              // least three: one downloading, one playing, and
                              // one idle.
#define kAQMaxPacketDescs 128 // number of packet descriptions in our array.
#define kAQBufSize 64 * 1024  // number of bytes in each audio queue buffer.



@interface Player : NSObject
{
 @private
  AudioFileTypeID audioHint; // Audio type hint provided by the user.
  AudioQueueRef audioQueue; // Audio queue.
  AudioQueueBufferRef audioQueueBuffer[kNumAQBufs]; // Audio queue buffers.
  // Packets description for enqueuing audio.
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];
		
	UInt64 fillBufferIndex; // The index of the audioQueueBuffer that is being
                          // filled.
	UInt32 bytesFilled;	// How many bytes have been filled in the buffer.
	UInt32 packetsFilled; // How many packets have been filled.
		
	BOOL inuse[kNumAQBufs]; // Flags to indicate that buffer is still in use
  
  BOOL isPlaying;
	BOOL started; // Flag to indicate that the queue has been started.
  
  pthread_mutex_t mutex; // A mutex to protect the inuse flags.
  pthread_cond_t cond; // A condition variable for handling inuse flags.
  
  pthread_mutex_t audioQueueBufferMutex; // A mutex to protect audioQueueBuffer.
  
 @protected
  AudioFileStreamID audioFileStream; // Audio file stream parser.

  NSURL *url;
	NSURLConnection *connection;

  NSError *error;

  BOOL finished; // Flag to indicate that termination is requested. The audio
                 // queue is not necessarily complete until isPlaying is also
                 // false.  
  BOOL failed; // Flag to indicate an error ocurred. 
  BOOL discontinuous; // Flag to trigger discontinuous mode.
}

@property(nonatomic, assign, readonly) BOOL isPlaying;
@property(nonatomic, assign, readonly) BOOL failed;
@property(nonatomic, retain, readonly) NSError *error;

// designated constructor
- (id)initWithURL:(NSURL *)newUrl audioTypeHint:(AudioFileTypeID)newAudioHint;

- (id)initWithURL:(NSURL *)newUrl;

- (id)initWithString:(NSString *)urlString;

- (id)initWithString:(NSString *)urlString audioTypeHint:(AudioFileTypeID)newAudioHint;

- (void)start;

- (void)stop;

- (void)pause;

- (void)setGain:(Float32)gain;

- (void)dealloc;

@end



