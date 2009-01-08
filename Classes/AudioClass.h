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

/**
 * RNConnectionFilter
 *
 * Connection filter that can change the connection request and later filter the
 * connection data returned from the server.
 */
@protocol RNConnectionFilter
 @optional

/**
 * modifyRequest:
 *
 * Modify the request that the player will use to connect to the stream. 
 */
- (NSURLRequest *)modifyRequest:(NSURLRequest *)request;

/**
 * connection:filterData
 *
 * Filters the data receive by the connection.
 */
- (NSData *)connection:(NSURLConnection *)connection
        filterData:(NSData *)data;
@end

@interface Player : NSObject
{
 @private
  AudioFileTypeID audioHint; // Audio type hint provided by the user.
  AudioFileStreamID audioFileStream; // Audio file stream parser.
  AudioQueueRef audioQueue; // Audio queue.
  AudioQueueBufferRef audioQueueBuffer[kNumAQBufs]; // Audio queue buffers.
  // Packets description for enqueuing audio.
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];
	
  NSURL *url;
	NSURLConnection *connection;
	
	UInt64 fillBufferIndex; // The index of the audioQueueBuffer that is being
                          // filled.
	UInt32 bytesFilled;	// How many bytes have been filled in the buffer.
	UInt32 packetsFilled; // How many packets have been filled.
		
	BOOL inuse[kNumAQBufs]; // Flags to indicate that buffer is still in use
  
  BOOL isPlaying;
	BOOL started; // Flag to indicate that the queue has been started.
  BOOL failed; // Flag to indicate an error ocurred. 
  BOOL finished; // Flag to indicate that termination is requested. The audio
                 // queue is not necessarily complete until isPlaying is also
                 // false.
  BOOL discontinuous; // Flag to trigger discontinuous mode.
  
  pthread_mutex_t mutex; // A mutex to protect the inuse flags.
  pthread_cond_t cond; // A condition variable for handling inuse flags.
  
  pthread_mutex_t audioQueueBufferMutex; // A mutex to protect audioQueueBuffer.
    
  NSError *error;
  
  // Connection filter of this player. Can be nil.
  NSObject <RNConnectionFilter> *connectionFilter;
}

@property(nonatomic, assign, readonly) BOOL isPlaying;
@property(nonatomic, assign, readonly) BOOL failed;
@property(nonatomic, retain, readonly) NSError *error;
@property(nonatomic, retain) NSObject <RNConnectionFilter> *connectionFilter;

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



