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

#define kNumAQBufs 3   // number of audio queue buffers we allocate
#define kAQMaxPacketDescs 128
#define kAQBufSize 64 * 1024

@protocol RNConnectionFilter
@optional
- (NSURLRequest *)modifyRequest:(NSURLRequest *)request;
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response;
- (NSData *)connection:(NSURLConnection *)connection
        filterData:(NSData *)data;
@end

@interface Player : NSObject
{
 @private
  AudioFileTypeID audioHint;
	AudioFileStreamID audioFileStream;
	AudioQueueRef audioQueue;
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];
	
  NSURL *url;
	NSURLConnection *connection;
	
	UInt64 fillBufferIndex;
	UInt32 bytesFilled;	
	UInt32 packetsFilled;
	
	UInt64 packetIndex;
	UInt32 numPacketsToRead;
	UInt32 ckeckIFEnded;
	
	BOOL inuse[kNumAQBufs];
  
  BOOL isPlaying;
	BOOL started;
  BOOL failed;
  BOOL finished;
  BOOL discontinuous;
  
  pthread_mutex_t mutex;
  pthread_cond_t cond;
  
  NSThread *controlThread;
  
  NSError *error;
  
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



