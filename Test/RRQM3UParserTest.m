//
//  RRQM3UParserTest.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 15/11/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import "RRQM3UParserTest.h"
#import "RRQM3UParser.h"


@implementation RRQM3UParserTest

- (void)testExtractLastComponentWithFileName {
  NSString *r = extractLastComponent(@"/tmp/scratch.tiff");
  STAssertEqualObjects(@"scratch.tiff", r,
                       @"Should be 'scratch.tiff' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithDirectoryName {
  NSString *r = extractLastComponent(@"/tmp/scratch");
  STAssertEqualObjects(@"scratch", r,
                       @"Should be 'scratch' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithDirectoryNameWithSlash {
  NSString *r = extractLastComponent(@"/tmp/");
  STAssertEqualObjects(@"tmp", r,
                       @"Should be 'tmp' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithoutSlashes {
  NSString *r = extractLastComponent(@"scratch.tiff");
  STAssertEqualObjects(@"scratch.tiff", r,
                       @"Should be 'scratch.tiff' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithRoot {
  NSString *r = extractLastComponent(@"/");
  STAssertEqualObjects(@"/", r,
                       @"Should be '/' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithURLFile {
  NSString *r = extractLastComponent(@"http://www.example.com/tmp/scratch.tiff");
  STAssertEqualObjects(@"scratch.tiff", r,
                       @"Should be 'scratch.tiff' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithURLDirectory {
  NSString *r = extractLastComponent(@"http://www.example.com/tmp");
  STAssertEqualObjects(@"tmp", r,
                       @"Should be 'tmp' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithURLDirectoryWithSlash {
  NSString *r = extractLastComponent(@"http://www.example.com/tmp/");
  STAssertEqualObjects(@"tmp", r,
                       @"Should be 'tmp' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithURLWithServerOnly {
  NSString *r = extractLastComponent(@"http://www.example.com");
  STAssertEqualObjects(@"http://www.example.com", r,
                       @"Should be 'http://www.example.com' but it was '%@' instead",
                       r);
}

- (void)testExtractLastComponentWithURLWithServerAndSlash {
  NSString *r = extractLastComponent(@"http://www.example.com/");
  STAssertEqualObjects(@"http://www.example.com", r,
                       @"Should be 'http://www.example.com' but it was '%@' instead",
                       r);
}

- (void)testParseEXTINFWithOnlyDuration {
  NSString *name = nil;
  NSString *artist = nil;
  NSInteger duration = -1;
  
  NSString *info = @"123";
  parseEXTINF(info, &artist, &name, &duration);
  STAssertNil(name, @"name should be nil");
  STAssertNil(artist, @"artist should be nil");
  STAssertEquals(123, duration, @"duration should be 123");
}

- (void)testParseEXTINFWithBadDuration {
  NSString *name = nil;
  NSString *artist = nil;
  NSInteger duration = -1;
  
  NSString *info = @"abc123";
  parseEXTINF(info, &artist, &name, &duration);
  STAssertNil(name, @"name should be nil");
  STAssertNil(artist, @"artist should be nil");
  STAssertEquals(-1, duration, @"duration should be 123");
}

- (void)testParseEXTINFWithDurationAndSimpleName {
  NSString *name = nil;
  NSString *artist = nil;
  NSInteger duration = -1;
  
  NSString *info = @"123, Track name";
  parseEXTINF(info, &artist, &name, &duration);
  STAssertEqualObjects(@"Track name", name, @"name should be 'Track name'");
  STAssertNil(artist, @"artist should be nil");
  STAssertEquals(123, duration, @"duration should be 123");
}

- (void)testParseEXTINFWithDurationAndCompoundName {
  NSString *name = nil;
  NSString *artist = nil;
  NSInteger duration = -1;
  
  NSString *info = @"123, Artist - Track name";
  parseEXTINF(info, &artist, &name, &duration);
  STAssertEqualObjects(@"Track name", name, @"name should be 'Track name'");
  STAssertEqualObjects(@"Artist", artist, @"artist should be 'Artist'");
  STAssertEquals(123, duration, @"duration should be 123");
}

- (void)testParseEXTINFComplete {
  NSString *name = nil;
  NSString *artist = nil;
  NSInteger duration = -1;
  
  NSString *info = @"123, Artist, Track name";
  parseEXTINF(info, &artist, &name, &duration);
  STAssertEqualObjects(@"Track name", name, @"name should be 'Track name'");
  STAssertEqualObjects(@"Artist", artist, @"artist should be 'Artist'");
  STAssertEquals(123, duration, @"duration should be 123");
}

@end
