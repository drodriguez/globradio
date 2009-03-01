//
//  FITrackInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FITrackInfo.h"
#import "FIArtistInfo.h"
#import "FIAlbumInfo.h"
#import "TouchXML.h"

static NSString *kStatus = @"status";
static NSString *kStatusOk = @"ok";

static NSString *kLfmNodeName = @"lfm";
static NSString *kTrackNodeName = @"track";

static NSString *kIdNodeXPath = @"id";
static NSString *kNameNodeXPath = @"name";
static NSString *kMbidNodeXPath = @"mbid";
static NSString *kArtistNodeXPath = @"artist";
static NSString *kAlbumNodeXPath = @"album";

@implementation FITrackInfo

@synthesize lastFMId = lastFMId_;
@synthesize name = name_;
@synthesize mbid = mbid_;
@synthesize artist = artist_;
@synthesize album = album_;

- (id)initWithData:(NSData *)xmlData {
  if (self = [super init]) {
    CXMLDocument *doc = [[CXMLDocument alloc] initWithData:xmlData
                                                   options:0
                                                     error:nil];
    if (!doc) {
      RNLog(@"Track info document can't not be parsed");
      self = nil;
      return self;
    }
    
    CXMLElement *rootElement = [doc rootElement];
    
    if ([[rootElement name] isEqualToString:kLfmNodeName]) {
      CXMLNode *statusAttribute = [rootElement attributeForName:kStatus];
      if (![[statusAttribute stringValue] isEqualToString:kStatusOk]) {
        RNLog(@"Track info not found?");
        [doc release];
        self = nil;
        return self;
      }
      rootElement = [[rootElement elementsForName:kTrackNodeName] objectAtIndex:0];
    }
    
    CXMLNode *idNode = [[rootElement nodesForXPath:kIdNodeXPath error:nil] objectAtIndex:0];
    NSAssert(idNode, @"Track info id node not found!");
    lastFMId_ = [[idNode stringValue] intValue];
    
    CXMLNode *nameNode = [[rootElement nodesForXPath:kNameNodeXPath error:nil] objectAtIndex:0];
    NSAssert(nameNode, @"Track info name node not found!");
    self.name = [nameNode stringValue];
    
    CXMLNode *mbidNode = [[rootElement nodesForXPath:kMbidNodeXPath error:nil] objectAtIndex:0];
    NSAssert(mbidNode, @"Track info mbid node not found!");
    self.mbid = [mbidNode stringValue];
    
    CXMLNode *artistNode = [[rootElement nodesForXPath:kArtistNodeXPath error:nil] objectAtIndex:0];
    NSAssert(artistNode, @"Track info artist node not found!");
    self.artist = [[[FIArtistInfo alloc] initWithString:[artistNode XMLString]] autorelease];
    
    CXMLNode *albumNode = [[rootElement nodesForXPath:kAlbumNodeXPath error:nil] objectAtIndex:0];
    NSAssert(albumNode, @"Track info album node not found!");
    self.album = [[[FIAlbumInfo alloc] initWithString:[albumNode XMLString]] autorelease];
    
    [doc release];
  }
  
  return self;
}

- (NSURL *)image {
  return [album_ image];
}

@end
