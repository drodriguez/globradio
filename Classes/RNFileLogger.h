//
//  RNFileLogger.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 17/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RNFileLogger : NSObject {
 @private
  NSString *logFile;
  NSFileHandle *fileHandle;
}

+ (id)sharedLogger;

- (void)logFile:(char *)sourceFile
     lineNumber:(int)lineNumber
         format:format, ...;

@property(nonatomic, copy, readonly) NSString *logFile;

@end
