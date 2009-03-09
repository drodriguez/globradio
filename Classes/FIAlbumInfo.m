//
//  FIAlbumInfo.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 01/03/09.
//  Copyright 2009 Javier Quevedo y Daniel Rodríguez. All rights reserved.
//

#import "FIAlbumInfo.h"
#import "FIAlbumInfo+Private.h"
#import "TouchXML.h"

static NSString *kStatus = @"status";
static NSString *kStatusOk = @"ok";

static NSString *kLfmNodeName = @"lfm";
static NSString *kAlbumNodeName = @"album";

static NSString *kIdNodeXPath = @"id";
static NSString *kNameNodeXPath = @"name";
static NSString *kTitleNodeXPath = @"title";
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

- (id)initWithXMLElement:(CXMLElement *)rootElement {
  if (self = [super init]) {
    if ([[rootElement name] isEqualToString:kLfmNodeName]) {
      CXMLNode *statusAttribute = [rootElement attributeForName:kStatus];
      if (![[statusAttribute stringValue] isEqualToString:kStatusOk]) {
        RNLog(@"Album info not found?");
        self = nil;
        return self;
      }
      NSArray *albumNodes = [rootElement elementsForName:kAlbumNodeName];
      if ([albumNodes count] > 0) {
        rootElement = [albumNodes objectAtIndex:0];
      } else {
        RNLog(@"Album info node not found!");
        self = nil;
        return self;
      }
    }
    
    NSArray *idNodes = [rootElement nodesForXPath:kIdNodeXPath error:nil];
    if ([idNodes count] > 0) {
      CXMLNode *idNode = [idNodes objectAtIndex:0];
      lastFMId_ = [[idNode stringValue] intValue];
    } else {
      RNLog(@"Album info id node not found!");
    }
    
    // In album.getInfo there is name, in track.getInfo there is title.
    NSArray *nameNodes = [rootElement nodesForXPath:kNameNodeXPath error:nil];
    if ([nameNodes count] > 0) {
      CXMLNode *nameNode = [nameNodes objectAtIndex:0];
      self.name = [nameNode stringValue];
    } else {
      RNLog(@"Album info name node not found! Searching for title node.");
      NSArray *titleNodes = [rootElement nodesForXPath:kTitleNodeXPath error:nil];
      if ([nameNodes count] > 0) {
        CXMLNode *titleNode = [titleNodes objectAtIndex:0];
        self.name = [titleNode stringValue];
      } else {
        RNLog(@"Album info title node not found!");
      }
    }
    
    NSArray *artistNodes = [rootElement nodesForXPath:kArtistNodeXPath error:nil];
    if ([artistNodes count] > 0) {
      CXMLNode *artistNode = [artistNodes objectAtIndex:0];
      self.artist = [artistNode stringValue];
    } else {
      RNLog(@"Album info artist node not found!");
    }
    
    NSArray *mbidNodes = [rootElement nodesForXPath:kMbidNodeXPath error:nil];
    if ([mbidNodes count] > 0) {
      CXMLNode *mbidNode = [mbidNodes objectAtIndex:0];
      self.mbid = [mbidNode stringValue];
    } else {
      RNLog(@"Album info mbid node not found!");
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
      // HACK: Let's try to obtain also the original image
      // Can't not work, because the images are not always from last.fm.
      /* NSURL *image = self.image;
      NSString *path = image.path;
      NSMutableArray *pathComponents =
        [NSMutableArray arrayWithArray:path.pathComponents];
      [pathComponents replaceObjectAtIndex:[pathComponents count] - 2
                                withObject:@"_"];
      path = [NSString pathWithComponents:pathComponents];
      image = [[NSURL alloc] initWithScheme:image.scheme
                                       host:image.host
                                       path:path];
      [images_ setValue:image forKey:@"original"];
      [image release]; */
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
  self.artist = nil;
  self.mbid = nil;
  if (images_)
    [images_ release];
  
  [super dealloc];
}

@end
