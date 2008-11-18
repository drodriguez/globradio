#import "AudioClass.h"

NSString *PlayerDidStopNotification = @"PlayerDidStopNotification";
NSString *PlayerDidCloseNotification = @"PlayerDidCloseNotification";
NSString *PlayerAudioDidEndedPlayingNotification = @"PlayerAudioDidEndedPlayingNotification";
NSString *PlayerDidFinishedPlayingNotification = @"PlayerDidFinishedPlayingNotification";
NSString *PlayerDidStablishConnection = @"PlayerDidStablishConnection";

void MyPropertyListenerProc(void *inClientData, AudioFileStreamID inAudioFileStream,AudioFileStreamPropertyID	inPropertyID, UInt32 * ioFlags)
{
	Player *player = (Player*)inClientData;
	//NSLog(@"MyPropertyListenerProc");
	[player propertyChanged:inPropertyID flags:ioFlags];
}

void MyPacketsProc(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription	*inPacketDescriptions)
{
	Player *player = (Player*)inClientData;
	[player packetData:inInputData  numberOfPackets:inNumberPackets numberOfBytes:inNumberBytes packetDescriptions:inPacketDescriptions];
}

void MyAudioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
	Player *player = (Player*)inClientData;
	[player outputCallbackWithBufferReference:inBuffer];
}


@implementation Player

- (void)setDelegate:(id)val
{
    delegate = val;
}

- (id)delegate
{
    return delegate;
}

-(BOOL) PlayerDidStablishConnection{
	return YES;
}

- (void)init {
	
	bytesFilled = 0;
	packetsFilled = 0;
	emptieddBuffer = 0;
	enqueuedBuffer = 0;
	audioQueue = 0;
	started = false;
	closed = false;
	ended = false;
	ckeckIFEnded = 0;
	
	
}

- (void)LoadUrl:(NSString*)url
{
	
	bytesFilled = 0;
	packetsFilled = 0;
	emptieddBuffer = 0;
	enqueuedBuffer = 0;
	audioQueue = 0;
	started = false;
	closed = false;
	ended = false;
	ckeckIFEnded = 0;
	
	NSLog(@"playUrl");
	OSStatus err = AudioFileStreamOpen(self, MyPropertyListenerProc, MyPacketsProc, 0, &audioFileStream);
	if (!err) NSLog(@"AudioFileStreamOpen ok");
	//else NSLog(@"AudioFileStreamOpen nok");
	
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection)
	{
		NSLog(@"connection created");
		if ( [delegate respondsToSelector:@selector(PlayerDidStablishConnection:)] ) 
		{
			//[delegate PlayerDidStablishConnection];
		//[[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidStablishConnection object:self];
		}
	}
	else
		NSLog(@"connection failed");
	NSLog(@"address inData:%p", (void *)self);
}


- (void)pause {
	if (closed)
		return;
	AudioQueuePause(audioQueue);
}

- (void)setGain:(Float32)gain {
	if (closed)
		return;
	AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, gain);
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
	OSStatus err = AudioFileStreamParseBytes(audioFileStream, [data length], [data bytes], 0);
	if (err) NSLog(@"AudioFileStreamParseBytes failed");
}

- (void)propertyChanged:(AudioFileStreamPropertyID)propertyID flags:(UInt32*)flags {
	//NSLog(@"found property '%c%c%c%c'\n", (propertyID>>24)&255, (propertyID>>16)&255, (propertyID>>8)&255, propertyID&255);
	
	OSStatus err = noErr;
	
	switch (propertyID)
	{
		case kAudioFileStreamProperty_ReadyToProducePackets:
		{
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			
			err = AudioFileStreamGetProperty(audioFileStream,  kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err) NSLog(@"get kAudioFileStreamProperty_DataFormat failed");
			
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, self, NULL, NULL, 0, &audioQueue);
			if (err) NSLog(@"AudioQueueNewOutput failed");
			
			/*
			 for (unsigned int i = 0; i < kNumAQBufs; i++)
			 err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
			 */
			
			fillBufferCount = 1;
			//NSLog(@"setting fillBufferCount value:%d", fillBufferCount);
			NSLog(@"allocating audioQueueBuffer from:%p", audioQueueBuffer);
			audioQueueBuffer = (AudioQueueBufferRef*)calloc(fillBufferCount, sizeof(AudioQueueBufferRef));
			NSLog(@"allocated audioQueueBuffer to:%p", audioQueueBuffer);
			//NSLog(@"allocating inuse from:%p", inuse);
			inuse = (BOOL *)calloc(fillBufferCount, sizeof(BOOL));
			//NSLog(@"allocated inuse to:%p", inuse);
			for (unsigned int i = 0; i < fillBufferCount; i++)
			{
				//NSLog(@"allocating audioQueue");
				err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[i]);
				if (err) NSLog(@"AudioQueueAllocateBuffer failed");
				inuse[i] = false;
			}
			
			break;
		}
			
	}
}

- (void)packetData:(const void*)data numberOfPackets:(UInt32)numPackets numberOfBytes:(UInt32)numBytes packetDescriptions:(AudioStreamPacketDescription*)packetDescriptions
{
	//NSLog(@"got data. bytes: %d, packets: %d", numBytes, numPackets);
	//ckeckIFEnded = 0; //if data still arrive, track is not Finished!
	//NSLog(@"bytesFilled: %d, packetsFilles: %d", bytesFilled, packetsFilled);
	
	for (int i = 0; i < numPackets; i++)
	{
		SInt64 packetOffset = packetDescriptions[i].mStartOffset;
		//NSLog(@"packetOffset in packetData:%d", packetOffset);
		SInt64 packetSize = packetDescriptions[i].mDataByteSize;
		//NSLog(@"packetSize in packetData:%d", packetSize);
		size_t bufSpaceRemaining = kAQBufSize - bytesFilled;
		//NSLog(@"bufSpaceRemaining in packetData:%d", bufSpaceRemaining);
		
		if (bufSpaceRemaining < packetSize) [self enqueueBuffer];
		
		//NSLog(@"fillBufferIndex in packetData:%d", fillBufferIndex);
		AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
		//NSLog(@"using fillBuf at:%x", audioQueueBuffer[fillBufferIndex]);
		
		//for debug, to display only once (in for loop)
		if(i == 0)
		{
			NSLog(@"data (const char*) is at %p", data);
			NSLog(@"fillBuf->mAudioData is at:%p", fillBuf->mAudioData);
		}
		
		//DURING THE SECOND PLAY, AFTER THE FIRST PLAY FINISHED, GOT AN ERROR HERE.
		//I THINK THERE IS A MISALLOCATION FOR fillBuf->mAudioData OR FOR data
		//I DON'T KNOW HOW TO FIX IT, NOT SURE ALSO IF THE ERROR COMES FROM HERE 
		memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)data + packetOffset, packetSize);
		packetDescs[packetsFilled] = packetDescriptions[i];
		packetDescs[packetsFilled].mStartOffset = bytesFilled;
		bytesFilled += packetSize;
		packetsFilled += 1;
		
		size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
		if (packetsDescsRemaining == 0) [self enqueueBuffer];
	}
}
- (void)enqueueBuffer
{
	enqueuedBuffer++;
	NSLog(@"enqueueBuffer:%d.", enqueuedBuffer);
	OSStatus err = noErr;
	//NSLog(@"fillBufferIndex value:%d", fillBufferIndex);
	inuse[fillBufferIndex] = true;
	//NSLog(@"inuse[%d] value:%d", fillBufferIndex, inuse[fillBufferIndex]);
	
	
	AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
	fillBuf->mAudioDataByteSize = bytesFilled;
	err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
	if (err) NSLog(@"AudioQueueEnqueueBuffer failed");
	
	
	if (!started)
	{
		err = AudioQueueStart(audioQueue, NULL);
		if (err) NSLog(@"AudioQueueStart failed");
		started = true;
		NSLog(@"started.");
	}
	
	
	bool isone = false;
	for (unsigned int i = 0; i < fillBufferCount; i++)
	{
		//NSLog(@"fillBufferCount value:%d", fillBufferCount);
		//NSLog(@"i value:%d", i);
		//NSLog(@"inuse[%d] value:%d", i, inuse[i]);
		if (!inuse[i])
		{
			fillBufferIndex = i;
			isone = true;
			//NSLog(@"found!");
			break;
		}
	}
	
	if (!isone)
	{
		//NSLog(@"not found!");
		fillBufferCount++;
		//NSLog(@"fillBufferCount value:%d", fillBufferCount);
		fillBufferIndex = fillBufferCount - 1;
		//NSLog(@"fillBufferIndex value:%d", fillBufferIndex);
		
		audioQueueBuffer = (AudioQueueBufferRef*)realloc(audioQueueBuffer, sizeof(AudioQueueBufferRef) * fillBufferCount);
		//NSLog(@"audioQueueBuffer reallocated!");
		inuse = (BOOL *)realloc(inuse, sizeof(BOOL) * fillBufferCount);
		//NSLog(@"inuse reallocated!");
		
		err = AudioQueueAllocateBuffer(audioQueue, kAQBufSize, &audioQueueBuffer[fillBufferIndex]);
		if (err) NSLog(@"AudioQueueAllocateBuffer failed");
		////else NSLog(@"AudioQueueAllocateBuffer OK");
		
		//NSLog(@"setting inuse[%d]: value:%d",fillBufferIndex, false);
		inuse[fillBufferIndex] = false;
	}	
	
	bytesFilled = 0;
	packetsFilled = 0;
}

- (int)findQueueBuffer:(AudioQueueBufferRef)inBuffer
{
	//NSLog(@"findQueueBuffer!");
	emptieddBuffer++;
	NSLog(@"emptieddBuffer:%d.", emptieddBuffer);
	//for (unsigned int i = 0; i < kNumAQBufs; i++)
	
	for (unsigned int i = 0; i < fillBufferCount; i++)
	{
		if (inBuffer == audioQueueBuffer[i]) 
		{
			//NSLog(@"inBuffer (%d) = audioQueueBuffer[%d]:",inBuffer, i);
			return i;
		}
	}
	return -1;
}

- (void)outputCallbackWithBufferReference:(AudioQueueBufferRef)buffer
{
	
	if(closed  || ended)
		return;
	
	//NSLog(@"Check if Ended or stall error: ckeckIFEnded: %d",ckeckIFEnded);
	//NSLog(@"fillBufferIndex -1: %d",fillBufferIndex-1);
	unsigned int bufIndex = [self findQueueBuffer:buffer];
	if(bufIndex != -1)
	{
		inuse[bufIndex] = false;
		//NSLog(@"bufIndex: %d",bufIndex);
		
		if(enqueuedBuffer == emptieddBuffer) //we are at the end of the file if the file as a length. 
		{
			//ended
			//NSLog(@"stopping AudioQueue!");
			AudioQueueStop(audioQueue, NO);
			//NSLog(@"setting ended to yes!");
			ended = YES;
			//NSLog(@"calling playBackIsRunningStateChanged!");
			[self playBackIsRunningStateChanged];
		}		
	}
	
}


- (void)postTrackFinishedPlayingNotification:(id)object
{
	[[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidFinishedPlayingNotification object:self];
}

- (void)playBackIsRunningStateChanged
{
	if (ended)
	{
		// go ahead and close the track now
		closed = YES;
		AudioQueueDispose(audioQueue, YES);
		AudioFileStreamClose(audioFileStream);
		NSLog(@"audioQueueBuffer before freeing: %p",audioQueueBuffer);
		free(audioQueueBuffer);
		audioQueueBuffer = (AudioQueueBufferRef*)0x0;
		[self performSelectorOnMainThread:@selector(postTrackFinishedPlayingNotification:) withObject:nil waitUntilDone:NO];
	}
}

- (void)stop
{
	if (audioQueue != 0)
	{
		if (connection)
		{
			[connection cancel];
			[connection release];
			connection = nil;
		}
		OSStatus err = noErr;
		//OSStatus err;
		err = AudioQueueStop(audioQueue, true);
		if (err) NSLog(@"AudioQueueStop failed");
		err = AudioFileStreamClose(audioFileStream);
		if (err) NSLog(@"AudioFileStreamClose failed");
		err = AudioQueueDispose(audioQueue, true);
		if (err) NSLog(@"AudioQueueDispose failed");
		free(audioQueueBuffer);
		if (packetDescs != nil)
			free(packetDescs);
		[[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidStopNotification object:self];
	}
}

- (void)close
{
	
	if (closed) return;
	
	if (audioQueue != 0)
	{
		if (connection)
		{
			[connection cancel];
			[connection release];
			connection = nil;
		}
		OSStatus err = noErr;
		//err = AudioQueueStop(audioQueue, true);
		if (err) NSLog(@"AudioQueueStop failed");
		err = AudioFileStreamClose(audioFileStream);
		if (err) NSLog(@"AudioFileStreamClose failed");
		err = AudioQueueDispose(audioQueue, true);
		if (err) NSLog(@"AudioQueueDispose failed");
		free(audioQueueBuffer);
		[[NSNotificationCenter defaultCenter] postNotificationName:PlayerDidCloseNotification object:self];
	}
}


- (void)PlayerDidStablishConnection:(Player *)player{
	nil;	
}// cal



- (void)dealloc
{
	//free(audioQueueBuffer);
	//if (packetDescs != nil)
	//	free(packetDescs);
	[super dealloc];
}

@end

