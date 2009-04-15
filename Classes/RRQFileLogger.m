//
//  RRQFileLogger.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 17/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RRQFileLogger.h"

@interface RRQFileLogger ()

- (id)init;
- (void)closeFile;

@property (nonatomic, retain) NSFileHandle *fileHandle;
@property (nonatomic, copy, readwrite) NSString *logFile;

@end

@implementation RRQFileLogger

@synthesize fileHandle, logFile;

+ (id)sharedLogger {
  static id singleton = NULL;
  @synchronized(self) {
    if (!singleton) {
      singleton = [self alloc];
      [singleton init];
    }
  }
  
  return singleton;
}

- (id)init {
  id logger = [super init];
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  self.logFile = [documentsDirectory stringByAppendingPathComponent:@"app.log"];
  if (![fileManager fileExistsAtPath:logFile]) {
    if (![fileManager createFileAtPath:logFile contents:nil attributes:nil]) {
      NSLog(@"Could not create file at %@", logFile);
    }
  }
  [self closeFile];
  self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
  [fileHandle truncateFileAtOffset:0];
  
  return logger;
}

- (void)logFile:(char *)sourceFile
     lineNumber:(int)lineNumber
         format:format, ... {
  va_list ap;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *file = [[NSString alloc] initWithBytes:sourceFile
                                            length:strlen(sourceFile)
                                          encoding:NSUTF8StringEncoding];  
  va_start(ap, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end(ap);
  NSString *print = [[NSString alloc] initWithFormat:@"%@ %@:%d %@\n",
                     [[NSDate date] description],
                     [file lastPathComponent],
                     lineNumber,
                     msg];
  
  [fileHandle writeData:[print dataUsingEncoding:NSUTF8StringEncoding]];
  
  [print release];
  [msg release];
  [file release];
  [pool release];
}

- (void)closeFile {
  [fileHandle closeFile];
  self.fileHandle = nil;
}

- (void)dealloc {
  self.logFile = nil;
  if (self.fileHandle) {
    [self closeFile];
  }
  self.fileHandle = nil; // Just to be sure.
  
  [super dealloc];
}

@end
