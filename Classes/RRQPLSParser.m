//
//  RRQPLSParser.m
//  radio3
//
//  Created by Javier Quevedo on 1/17/09.
//  Copyright Daniel Rodríguez and Javier Quevedo 2009. All rights reserved.
//

#import "RRQPLSParser.h"


@implementation RRQPLSParser

- (id)init {
	return [self initWithContents:nil];
}

- (id)initWithContents:(NSString *)c {
	self = [super init];
	if (self) {
		[self setContents:c];
	}
	return self;
}

- (void)dealloc {
	[self setContents:nil];
	[super dealloc];
}

+ (NSArray *)parse:(NSString *)c {
	RRQPLSParser *parser =
    [[[RRQPLSParser alloc] initWithContents:c] autorelease];
	
	return [parser parse];
}

- (NSArray *)parse {
	NSMutableArray *results = [[[NSMutableArray alloc] initWithCapacity:1] autorelease];
	
	NSArray *lines =
    [contents componentsSeparatedByCharactersInSet:
     [NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		NSString *cleanLine =
			[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([cleanLine length] > 0) {
      NSRange fileRange = [cleanLine rangeOfString:@"File"];
      if (fileRange.location != NSNotFound) {        
        NSString *fileURL = [cleanLine substringFromIndex:fileRange.length+fileRange.location+2];	
        [results addObject:fileURL];
			}
		}
	}
	
	return results;
}

@synthesize contents;
@end