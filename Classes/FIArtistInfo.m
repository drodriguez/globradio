//
//  FIArtistInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/03/09.
//  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
//

#import "FIArtistInfo.h"
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

@interface FIArtistInfo ()

- (id)initWithXMLElement:(CXMLElement *)rootElement;

@end


@implementation FIArtistInfo

@synthesize lastFMId = lastFMId_;
@synthesize name = name_;
@synthesize mbid = mbid_;
@synthesize images = images_;

+ (void)initialize {
  imageSizePreference = [[NSArray alloc] initWithObjects:@"large",
                         @"medium",
                         @"small"];
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
      rootElement = [[rootElement elementsForName:kArtistNodeName] objectAtIndex:0];
    }
    
    CXMLNode *idNode = [[rootElement nodesForXPath:kIdNodeXPath error:nil] objectAtIndex:0];
    if (idNode) {
      lastFMId_ = [[idNode stringValue] intValue];
    } else {
      RNLog(@"Artist info id node not found!");
    }
    
    CXMLNode *nameNode = [[rootElement nodesForXPath:kNameNodeXPath error:nil] objectAtIndex:0];
    NSAssert(nameNode, @"Artist info name node not found!");
    self.name = [nameNode stringValue];
    
    CXMLNode *mbidNode = [[rootElement nodesForXPath:kMbidNodeXPath error:nil] objectAtIndex:0];
    NSAssert(mbidNode, @"Artist info mbid node not found!");
    self.mbid = [mbidNode stringValue];
    
    NSArray *images = [rootElement nodesForXPath:kImageNodeXPath error:nil];
    for (CXMLElement *image in images) {
      NSString *size = [[image attributeForName:kSizeAttribute] stringValue];
      NSURL *url = [NSURL URLWithString:[image stringValue]];
      [images_ setValue:url forKey:size];
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

@end
