//
//  FITrackInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 27/02/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FITrackInfo.h"
#import "FIArtistInfo.h"
#import "FIArtistInfo+Private.h"
#import "FIAlbumInfo.h"
#import "FIArtistInfo+Private.h"
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
    
    NSArray *idNodes = [rootElement nodesForXPath:kIdNodeXPath error:nil];
    if ([idNodes count] > 0) {
      CXMLNode *idNode = [idNodes objectAtIndex:0];
      lastFMId_ = [[idNode stringValue] intValue];
    } else {
      RNLog(@"Track info id node not found!");
    }
    
    NSArray *nameNodes = [rootElement nodesForXPath:kNameNodeXPath error:nil];
    if ([nameNodes count] > 0) {
      CXMLNode *nameNode = [nameNodes objectAtIndex:0];
      self.name = [nameNode stringValue];
    } else {
      RNLog(@"Track info name node not found!");
    }
        
    NSArray *mbidNodes = [rootElement nodesForXPath:kMbidNodeXPath error:nil];
    if ([mbidNodes count] > 0) {
      CXMLNode *mbidNode = [mbidNodes objectAtIndex:0];
      self.mbid = [mbidNode stringValue];
    } else {
      RNLog(@"Track info mbid node not found!");
    }
    
    NSArray *artistNodes = [rootElement nodesForXPath:kArtistNodeXPath error:nil];
    if ([artistNodes count] > 0) {
      CXMLNode *artistNode = [artistNodes objectAtIndex:0];
      self.artist = [[[FIArtistInfo alloc] initWithXMLElement:(CXMLElement *)artistNode] autorelease];
    } else {
      RNLog(@"Track info artist node not found!");
    }
    
    NSArray *albumNodes = [rootElement nodesForXPath:kAlbumNodeXPath error:nil];
    if ([albumNodes count] > 0) {
      CXMLNode *albumNode = [albumNodes objectAtIndex:0];
      self.album = [[[FIAlbumInfo alloc] initWithXMLElement:(CXMLElement *)albumNode] autorelease];
    } else {
      RNLog(@"Track info album node not found!");
    }
    
    [doc release];
  }
  
  return self;
}

- (NSURL *)image {
  return [album_ image];
}

- (void)dealloc {
  self.name = nil;
  self.mbid = nil;
  self.artist = nil;
  self.album = nil;
  
  [super dealloc];
}

@end
