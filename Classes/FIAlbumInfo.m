//
//  FIAlbumInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/03/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import "FIAlbumInfo.h"
#import "TouchXML.h"

static NSString *kAlbumNodeName = @"album";

static NSString *kIdNodeXPath = @"id";
static NSString *kNameNodeXPath = @"name";
static NSString *kArtistNodeXPath = @"artist";
static NSString *kMbidNodeXPath = @"mbid";
static NSString *kImageNodeXPath = @"image";

static NSString *kSizeAttribute = @"size";

static NSArray *imageSizePreference;

@implementation FIAlbumInfo

@synthesize lastFMId = lastFMId_;
@synthesize name = name_;
@synthesize artist = artist_;
@synthesize mbid = mbid_;
@synthesize images = images_;

+ (void)initialize {
  imageSizePreference = [[NSArray alloc] initWithObjects:@"large",
                         @"medium",
                         @"small"];
}

- (id)initWithString:(NSString *)xmlString {
  if (self = [super init]) {
    CXMLDocument *doc = [[CXMLDocument alloc] initWithXMLString:xmlString
                                                        options:0
                                                          error:nil];
    if (!doc) {
      RNLog(@"Album info element can't not be parsed");
      self = nil;
      return self;
    }
    
    CXMLElement *rootElement = [doc rootElement];
    
    CXMLNode *idNode = [[rootElement nodesForXPath:kIdNodeXPath error:nil] objectAtIndex:0];
    if (idNode) {
      lastFMId_ = [[idNode stringValue] intValue];
    } else {
      RNLog(@"Album info id node not found!");
    }
    
    CXMLNode *nameNode = [[rootElement nodesForXPath:kNameNodeXPath error:nil] objectAtIndex:0];
    NSAssert(nameNode, @"Album info name node not found!");
    self.name = [nameNode stringValue];
    
    CXMLNode *artistNode = [[rootElement nodesForXPath:kArtistNodeXPath error:nil] objectAtIndex:0];
    NSAssert(nameNode, @"Album info artist node not found!");
    self.artist = [artistNode stringValue];
    
    CXMLNode *mbidNode = [[rootElement nodesForXPath:kMbidNodeXPath error:nil] objectAtIndex:0];
    NSAssert(mbidNode, @"Album info mbid node not found!");
    self.mbid = [mbidNode stringValue];
    
    NSArray *images = [rootElement nodesForXPath:kImageNodeXPath error:nil];
    for (CXMLElement *image in images) {
      NSString *size = [[image attributeForName:kSizeAttribute] stringValue];
      NSURL *url = [NSURL URLWithString:[image stringValue]];
      [images_ setValue:url forKey:size];
    }
    
    [doc release];
  }
  
  return self;
}

- (NSURL *)image {
  NSURL *result;
  for (NSString *size in imageSizePreference) {
    if (result = [images_ objectForKey:size]) {
      return result;
    }
  }
  
  return nil;
}

@end
