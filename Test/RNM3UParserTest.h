//
//  RNM3UParserTest.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 15/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GTMSenTestCase.h"


@interface RNM3UParserTest : SenTestCase {
}

- (void)testExtractLastComponentWithFileName;
- (void)testExtractLastComponentWithDirectoryName;
- (void)testExtractLastComponentWithDirectoryNameWithSlash;
- (void)testExtractLastComponentWithoutSlashes;
- (void)testExtractLastComponentWithRoot;
- (void)testExtractLastComponentWithURLFile;
- (void)testExtractLastComponentWithURLDirectory;
- (void)testExtractLastComponentWithURLDirectoryWithSlash;
- (void)testExtractLastComponentWithURLWithServerOnly;
- (void)testExtractLastComponentWithURLWithServerAndSlash;

- (void)testParseEXTINFWithOnlyDuration;
- (void)testParseEXTINFWithBadDuration;
- (void)testParseEXTINFWithDurationAndSimpleName;
- (void)testParseEXTINFWithDurationAndCompoundName;
- (void)testParseEXTINFComplete;

@end
