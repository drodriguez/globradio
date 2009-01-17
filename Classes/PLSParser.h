//
//  PLSParser.h
//  radio3
//
//  Created by Javier Quevedo on 1/17/09.
//  Copyright Daniel Rodríguez and Javier Quevedo 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLSParser : NSObject {
@private
	NSString *contents;
}

- (id)init;
- (id)initWithContents:(NSString *)c;

+ (NSArray *)parse:(NSString *)c;

- (NSArray *)parse;

@property(nonatomic, copy) NSString *contents;

@end
