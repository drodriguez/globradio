#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AudioToolbox.h>


#define kNumAQBufs	3			// number of audio queue buffers we allocate
#define kAQMaxPacketDescs   128
#define kAQBufSize			64 * 1024

typedef enum {
	EAudioStateClosed,
	EAudioStateStopped,
	EAudioStatePlaying,
	EAudioStatePaused,
	EAudioStateSeeking
} EAudioState;

@protocol PlayerDelegate;

@interface Player : NSObject
{
	id								delegate;
	AudioFileStreamID				audioFileStream;
	AudioQueueRef					audioQueue;
	//AudioQueueBufferRef				audioQueueBuffer[kNumAQBufs];
	AudioQueueBufferRef				*audioQueueBuffer;
	AudioStreamPacketDescription	packetDescs[kAQMaxPacketDescs];
	
	NSURLConnection					*connection;
	NSURLRequest					*request;
	
	UInt64							fillBufferIndex;
	UInt64							fillBufferCount;
	UInt64							enqueuedBuffer;
	UInt64							emptieddBuffer;
	UInt32							bytesFilled;	
	UInt32							packetsFilled;
	
	UInt64							packetIndex;
	UInt32							numPacketsToRead;
	UInt32							ckeckIFEnded;
	
	//BOOL							inuse[kNumAQBufs];	
	BOOL							*inuse;	
	BOOL							started;			
	BOOL							failed;	
	BOOL							repeat;
	BOOL							closed;
	BOOL							ended;	
	
	
	EAudioState						audioState;

}

	- (BOOL) PlayerDidStablishConnection;
- (void)setDelegate:(id)val;
- (id)delegate;

//- (void)init;
- (void)LoadUrl:(NSString*)url;
- (void)stop;
- (void)pause;
- (void)setGain:(Float32)gain;
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags;
- (void)packetData:(const void*)data
   numberOfPackets:(UInt32)numPackets
	 numberOfBytes:(UInt32)numBytes
packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions;
- (void)playBackIsRunningStateChanged;
- (void)enqueueBuffer;
- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer;
- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer;
- (void)close;
- (void)dealloc;

@end

@protocol PlayerDelegate<NSObject>

@optional

- (void)PlayerDidStablishConnection:(Player *)player;      // called when scrolling animation finished. may be called immediately if already at top

@end


