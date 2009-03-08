//
//  FIArtistInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/03/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FIArtistInfo.h"
#import "FIArtistInfo+Private.h"
#import "TouchXML.h"

static NSString *kStatus = @"status";
static NSString *kStatusOk = @"ok";

static NSString *kLfmNodeName = @"lfm";
static NSString *kArtistNodeName = @"artist";

static NSString *kIdNodeXPath = @"id";
static NSString *kNameNodeXPath = @"name";
static NSString *kMbidNodeXPath = @"mbid";
static NSString *kImageNodeXPath = @"image";

static NSString *kSizeAttribute = @"size";

static NSArray *imageSizePreference;

@implementation FIArtistInfo

@synthesize lastFMId = lastFMId_;
@synthesize name = name_;
@synthesize mbid = mbid_;
@synthesize images = images_;

+ (void)initialize {
  imageSizePreference = [[NSArray alloc] initWithObjects:@"large",
                         @"medium",
                         @"small", nil];
}

- (id)initWithString:(NSString *)xmlString {
  CXMLDocument *doc = [[[CXMLDocument alloc] initWithXMLString:xmlString
                                                       options:0
                                                         error:nil] autorelease];
  if (!doc) {
    RNLog(@"Artist info element can't not be parsed");
    self = nil;
    return self;
  }
  
  CXMLElement *rootElement = [doc rootElement];
  
  return [self initWithXMLElement:rootElement];
}

- (id)initWithData:(NSData *)xmlData {
  CXMLDocument *doc = [[[CXMLDocument alloc] initWithData:xmlData
                                                  options:0
                                                    error:nil] autorelease];
  if (!doc) {
    RNLog(@"Artist info element can't not be parsed");
    self = nil;
    return self;
  }
  
  CXMLElement *rootElement = [doc rootElement];
  
  return [self initWithXMLElement:rootElement];
}

- (id)initWithXMLElement:(CXMLElement *)rootElement {
  if (self = [super init]) {
    if ([[rootElement name] isEqualToString:kLfmNodeName]) {
      CXMLNode *statusAttribute = [rootElement attributeForName:kStatus];
      if (![[statusAttribute stringValue] isEqualToString:kStatusOk]) {
        RNLog(@"Artist info not found?");
        self = nil;
        return self;
      }
      NSArray *artistNodes = [rootElement elementsForName:kArtistNodeName];
      if ([artistNodes count] > 0) {
        rootElement = [artistNodes objectAtIndex:0];
      } else {
        RNLog(@"Artist info node not found!");
        self = nil;
        return self;
      }
    }
    
    NSArray *idNodes = [rootElement nodesForXPath:kIdNodeXPath error:nil];
    if ([idNodes count] > 0) {
      CXMLNode *idNode = [idNodes objectAtIndex:0];
      lastFMId_ = [[idNode stringValue] intValue];
    } else {
      RNLog(@"Artist info id node not found!");
    }
    
    NSArray *nameNodes = [rootElement nodesForXPath:kNameNodeXPath error:nil];
    if ([nameNodes count] > 0) {
      CXMLNode *nameNode = [nameNodes objectAtIndex:0];
      self.name = [nameNode stringValue];
    } else {
      RNLog(@"Artist info name node not found!");
    }
    
    NSArray *mbidNodes = [rootElement nodesForXPath:kMbidNodeXPath error:nil];
    if ([mbidNodes count] > 0) {
      CXMLNode *mbidNode = [mbidNodes objectAtIndex:0];
      self.mbid = [mbidNode stringValue];
    } else {
      RNLog(@"Artist info mbid node not found!");
    }
    
    NSArray *images = [rootElement nodesForXPath:kImageNodeXPath error:nil];
    if ([images count] > 0) {
      images_ = [[NSMutableDictionary alloc] initWithCapacity:[images count]];
      for (CXMLElement *image in images) {
        NSString *size = [[image attributeForName:kSizeAttribute] stringValue];
        NSString *urlStr = [image stringValue];
        if (urlStr) {
          NSURL *url = [NSURL URLWithString:[image stringValue]];
          [images_ setValue:url forKey:size];
        }
      }
    }    
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

- (void)dealloc {
  self.name = nil;
  self.mbid = nil;
  if (images_)
    [images_ release];
  
  [super dealloc];
}

@end
