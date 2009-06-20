//
//  RRQSQLiteInstanceManager+Migrator.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 20/06/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SQLiteInstanceManage (RRQMigrator)

- (BOOL)migrate:(NSUInteger)version;

@end
