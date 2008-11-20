#import <UIKit/UIKit.h>
#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

#define kNumAQBufs 3   // number of audio queue buffers we allocate
#define kAQMaxPacketDescs 128
#define kAQBufSize 64 * 1024

@interface Player : NSObject
{
 @private
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
}

@property(nonatomic, assign, readonly) BOOL isPlaying;
@property(nonatomic, assign, readonly) BOOL failed;

// designated constructor
- (id)initWithURL:(NSURL *)newUrl;

- (id)initWithString:(NSString *)urlString;

- (void)start;

- (void)stop;

- (void)pause;

- (void)setGain:(Float32)gain;

- (void)dealloc;

@end

@protocol PlayerDelegate<NSObject>

 @optional

- (void)playerDidEstablishConnection:(Player *)player;

@end


