//
//  NSString+Version.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 06/04/09.
//  Copyright 2009 Daniel Rodríguez. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Version)

- (BOOL)compatibleWith:(NSString *)version;

@end