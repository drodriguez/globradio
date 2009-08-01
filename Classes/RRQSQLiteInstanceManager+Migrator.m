//
//  RRQSQLiteInstanceManager+Migrator.m
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 20/06/09.
//  Copyright 2009 Daniel Rodríguez Troitiño. All rights reserved.
//

#import "RRQSQLiteInstanceManager+Migrator.h"

@interface SQLiteInstanceManager (RRQMigratorPrivate)

- (BOOL)isDatabaseInPlace;
- (BOOL)copyDatabaseFromBundle;
- (NSInteger)dbSchemaVersion;
- (BOOL)runMigrationsFrom:(NSUInteger)from to:(NSUInteger)to;

@end



const static NSString *kSelectDBSchemaVersion =
  @"SELECT \"version\" FROM \"db_schema\" LIMIT 1";

@implementation SQLiteInstanceManager (RRQMigrator)

- (BOOL)migrate:(NSUInteger)version {
  /* if ([self isDatabaseInPlace]) {
    NSInteger schemaVersion = [self dbSchemaVersion];
    if (schemaVersion < 0) {
      NSLog(@"Can not found database schema version! Aborting migration");
      
      return NO;
    }
    
    if (version > schemaVersion) {
      return [self runMigrationsFrom:schemaVersion to:version];
    } else if (version < schemaVersion) {
      NSLog(@"Warning! Database schema version was greater than supported");
      
      return NO;
    }
  } else { */
    NSLog(@"Copying database from executable bundle");
    
    return [self copyDatabaseFromBundle];
  /* } */
  
  return YES;
}

- (BOOL)isDatabaseInPlace {
  return [[NSFileManager defaultManager] fileExistsAtPath:
          [self databaseFilepath]];
}

- (BOOL)copyDatabaseFromBundle {
  NSString *dbPath = [self databaseFilepath];
  NSString *appResources = [[NSBundle mainBundle] resourcePath];
  NSString *bundledDb = [appResources stringByAppendingPathComponent:
                         [dbPath lastPathComponent]];
  
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  NSError *error;
  
  if ([fileMgr fileExistsAtPath:dbPath]) {
    if (![fileMgr removeItemAtPath:dbPath error:&error]) {
      NSLog(@"Can not delete old database file with error (%d) '%@'",
            [error code], [error description]);
      return NO;
    }
  }
  
  if (![fileMgr copyItemAtPath:bundledDb toPath:dbPath error:&error]) {
    NSLog(@"Can not copy database file with error (%d) '%@'",
          [error code], [error description]);
    
    return NO;
  }
  
  return YES;
}

- (NSInteger)dbSchemaVersion {
  NSInteger version = -1;
  
  sqlite3_stmt *stmt;
  if (sqlite3_prepare_v2([self database],
                         [kSelectDBSchemaVersion UTF8String],
                         -1, &stmt, nil) == SQLITE_OK) {
    if (sqlite3_step(stmt) == SQLITE_ROW) {
      version = sqlite3_column_int(stmt, 0);
    }
    sqlite3_finalize(stmt);
  }
  
  return version;
}

- (BOOL)runMigrationsFrom:(NSUInteger)from to:(NSUInteger)to {
  NSFileManager *fileMgr = [NSFileManager defaultManager];
  NSString *appResources = [[NSBundle mainBundle] resourcePath];
  NSString *migrationPattern = [appResources stringByAppendingPathComponent:
                                @"migration-%04d.sql"];
  
  char *errorMsg;
  for (int migrationNumber = from+1; migrationNumber <= to; migrationNumber++) {
    NSString *migrationName = [NSString stringWithFormat:migrationPattern,
                               migrationNumber];
    if ([fileMgr fileExistsAtPath:migrationName]) {
      if (sqlite3_exec([self database],
                       [[NSString stringWithContentsOfFile:migrationName] UTF8String] ,
                       NULL, NULL, &errorMsg) != SQLITE_OK) {
        NSString *errorMessage =
          [NSString stringWithFormat:@"Migration %04d failed with message '%s'.",
           migrationNumber, errorMsg];
        NSLog(errorMessage);
        sqlite3_free(errorMsg);
        return NO;
      }
    } else {
      NSLog([NSString stringWithFormat:
             @"Warning! Migration %04d do not exist. Skipping",
             migrationNumber]); 
    }
  }
  
  return YES;
}

@end
