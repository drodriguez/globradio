//
//  NSString+VersionTest.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 06/04/09.
//  Copyright 2009 Daniel Rodríguez y Javier Quevedo. All rights reserved.
//

#import "NSString+VersionTest.h"

#import "NSString+Version.h"

@implementation NSStringVersionTest

- (void)testNormalizeWithOneComponentVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", nil];
  normalizeVersion(a2);
  
  STAssertEqualObjects(a1, a2,
                       @"A [1] version should be normalized to [1]");
}

- (void)testNormalizeWithOneEndingZeroVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"0", nil];
  normalizeVersion(a2);
  
  STAssertEqualObjects(a1, a2,
                       @"A [1, 0] version should be normalized to [1]");
}

- (void)testNormalizeWithManyEndingZerosVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"0", @"0", nil];
  normalizeVersion(a2);
  
  STAssertEqualObjects(a1, a2,
                       @"A [1, 0, 0] version should be normalized to [1]");
}

- (void)testNormalizeWithOnlyZerosVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"0", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"0", @"0", @"0", nil];
  normalizeVersion(a2);
  
  STAssertEqualObjects(a1, a2,
                       @"A [0, 0, 0] version should be normalized to [0]");
}

- (void)testCompareVersionsFirstIsLongerAndGreater {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"1", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"1", nil];
  
  STAssertEquals(1, compareVersions(a1, a2),
                 @"[1, 1] should be greater than [1]");
}

- (void)testCompareVersionsSecondIsLongerAndGreater {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"1", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"1", nil];
  
  STAssertEquals(-1, compareVersions(a2, a1),
                 @"[1] should be lower than [1, 1]");
}

- (void)testCompareVersionsFirstIsLongerAndLower {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"1", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"2", nil];
  
  STAssertEquals(-1, compareVersions(a1, a2),
                 @"[1, 1] should be greater than [1]");
}

- (void)testCompareVersionsSecondIsLongerAndLower {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"1", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"2", nil];
  
  STAssertEquals(1, compareVersions(a2, a1),
                 @"[1] should be lower than [1, 1]");
}

- (void)testCompareVersionsFirstIsGreater {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"2", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"1", @"1", nil];
  
  STAssertEquals(1, compareVersions(a1, a2),
                 @"[1, 2] should be greater than [1, 1]");
}

- (void)testCompareVersionsSecondIsGreater {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"2", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"1", @"1", nil];
  
  STAssertEquals(-1, compareVersions(a2, a1),
                 @"[1, 1] should be lower than [1, 2]");
}

- (void)testCompareVersionsBothAreEqual {
  NSArray *a1 = [NSArray arrayWithObjects:@"1", @"3", nil];
  NSArray *a2 = [NSArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertEquals(0, compareVersions(a1, a2),
                 @"[1, 3] should be equal to [1, 3]");
}



- (void)testVersionEqualsWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionEquals(a1, a2),
               @"[1, 3] should be equal than [1, 3]");
}

- (void)testVersionEqualsWithDifferentVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertFalse(versionEquals(a1, a2),
                @"[1, 3] should not be equal than [1, 4]");
}



- (void)testVersionDifferentWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionDifferent(a1, a2),
                @"[1, 3] should not be different than [1, 3]");
}

- (void)testVersionDifferentWithDifferentVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertTrue(versionDifferent(a1, a2),
               @"[1, 3] should be differnet than [1, 4]");
}



- (void)testVersionGoEWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionGreaterOrEquals(a1, a2),
               @"[1, 3] should be greater or equal than [1, 3]");
}

- (void)testVersionGoEWithFirstGreaterVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionGreaterOrEquals(a1, a2),
               @"[1, 4] should be greater or equal than [1, 3]");
}

- (void)testVersionGoEWithFirstLowerVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertFalse(versionGreaterOrEquals(a1, a2),
                @"[1, 3] should be not greater or equal than [1, 4]");
}



- (void)testVersionLoEWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionLowerOrEquals(a1, a2),
               @"[1, 3] should be lower or equal than [1, 3]");
}

- (void)testVersionLoEWithFirstLowerVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertTrue(versionLowerOrEquals(a1, a2),
               @"[1, 3] should be lower or equal than [1, 4]");
}

- (void)testVersionLoEWithFirstGreaterVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionLowerOrEquals(a1, a2),
                @"[1, 4] should be not lower or equal than [1, 3]");
}



- (void)testVersionGreaterWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionGreater(a1, a2),
                @"[1, 3] should not be greater than [1, 3]");
}

- (void)testVersionGreaterWithFirstLowerVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertFalse(versionGreater(a1, a2),
                @"[1, 3] should not be greater than [1, 4]");
}

- (void)testVersionGreaterWithFirstGreaterVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionGreater(a1, a2),
               @"[1, 4] should be greater than [1, 3]");
}



- (void)testVersionLowerWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionLower(a1, a2),
                @"[1, 3] should not be lower than [1, 3]");
}

- (void)testVersionLowerWithFirstLowerVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertTrue(versionLower(a1, a2),
               @"[1, 3] should be lower than [1, 4]");
}

- (void)testVersionLowerWithFirstGreaterVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionLower(a1, a2),
                @"[1, 4] should not be lower than [1, 3]");
}



- (void)testVersionCompatibleWithEqualVersions {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionCompatible(a1, a2),
               @"[1, 3] should be compatible to [1, 3]");
}

- (void)testVersionCompatibleWithFirstLowerVersion {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  
  STAssertFalse(versionCompatible(a1, a2),
                @"[1, 3] should not be comptible to [1, 4]");
}

- (void)testVersionCompatibleWithFirstGreaterVersionAndLowerThanVersionBump {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"1", @"4", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertTrue(versionCompatible(a1, a2),
               @"[1, 4] should be compatible to [1, 3]");
}

- (void)testVersionCompatibleWithFirstGreaterVersionAndGreaterThanVersionBump {
  NSMutableArray *a1 = [NSMutableArray arrayWithObjects:@"2", @"1", nil];
  NSMutableArray *a2 = [NSMutableArray arrayWithObjects:@"1", @"3", nil];
  
  STAssertFalse(versionCompatible(a1, a2),
                @"[2, 1] should not be compatible to [1, 3]");
}



- (void)testCompatibleWithWithoutSymbolsAndEqualVersions {
  STAssertTrue([@"1.1" compatibleWith:@"1.1"],
               @"'1.1' should be compatible with '1.1'");
}

- (void)testCompatibleWithWithoutSymbolsAndDifferentVersions {
  STAssertFalse([@"1.1" compatibleWith:@"1.2"],
                @"'1.1' should not be compatible with '1.2'");
}

- (void)testCompatibleWithWithEqualAndEqualVersions {
  STAssertTrue([@"1.1" compatibleWith:@"=1.1"],
               @"'1.1' should be compatible with '1.1'");
}

- (void)testCompatibleWithWithEqualAndDifferentVersions {
  STAssertFalse([@"1.1" compatibleWith:@"=1.2"],
                @"'1.1' should not be compatible with '=1.2'");
}

- (void)testCompatibleWithWithEqualAndSpaceAndEqualVersions {
  STAssertTrue([@"1.1" compatibleWith:@"= 1.1"],
               @"'1.1' should be compatible with '= 1.1'");
}

- (void)testCompatibleWithWithDifferent {
  STAssertTrue([@"1.1" compatibleWith:@"!=1.0"],
               @"'1.1' should be compatible with '!=1.0'");
}

- (void)testCompatibleWithWithGoE {
  STAssertTrue([@"1.1" compatibleWith:@">=1.0"],
               @"'1.1' should be compatible with '>=1.0'");
}

- (void)testCompatibleWithWithLoE {
  STAssertTrue([@"1.1" compatibleWith:@"<=2.0"],
               @"'1.1' should be compatible with '<=2.0'");
}

- (void)testCompatibleWithWithGreater {
  STAssertTrue([@"1.1" compatibleWith:@">1.0.1"],
               @"'1.1' should be compatible with '>1.0.1'");
}

- (void)testCompatibleWithWithLower {
  STAssertTrue([@"1.1" compatibleWith:@"<1.9"],
               @"'1.1' should be compatible with '<1.9'");
}

- (void)testCompatibleWithWithSimilar {
  STAssertTrue([@"1.1" compatibleWith:@"~>1.0"],
               @"'1.1' should be compatible with '~>1.0'");
}

@end
