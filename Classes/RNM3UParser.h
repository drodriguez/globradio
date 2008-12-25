//
//  RNM3UParser.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 14/11/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RNM3UParser : NSObject {
 @private
  NSString *contents;
}

- (id)init;
- (id)initWithContents:(NSString *)c;

+ (NSArray *)parse:(NSString *)c;

- (NSArray *)parse;

@property(nonatomic, copy) NSString *contents;

@end

#ifdef TESTING
NSString *extractLastComponent(NSString *path);
void parseEXTINF
  (NSString *info, NSString **artist, NSString **name, NSInteger *duration);
#endif

