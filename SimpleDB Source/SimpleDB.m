//  Created by Aaron Bratcher on 9/27/13.

#import "SimpleDB.h"
#import "ABSQLiteDB.h"
#import "ABDatabase.h"

@implementation SimpleDB

static id <ABDatabase> db;
static dbStatus status;
static NSDictionary* jsonValue_dict;
static NSString* jsonValue_key;
static NSString* jsonValue_table;
static NSTimer* autoDeleteTimer;
static NSMutableArray *tables;

static NSDateFormatter* stringValueFormatter;

#pragma mark - Keys

+(BOOL) hasKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	if (![self openDB]) {
		status = CannotOpenDB;
		return NO;
	}
	if (![tables containsObject:table]) {
		return NO;
	}
	
	BOOL exists = NO;
	NSString* sql = [NSString stringWithFormat:@"select key from %@ where key = '%@'",table,[self sqlEscapeString:key]];
	id<ABRecordset> results = [db sqlSelect:sql];
	if (![results eof]) {
		exists = YES;
	}
	[results close];
	results = nil;
	
	return exists;
}

+(NSArray*) keysInTable:(NSString*) table {
	NSAssert(table && table.length > 0,@"table must be provided");
	NSMutableArray *keys = [NSMutableArray array];
	if (![self openDB]) {
		status = CannotOpenDB;
		return nil;
	}
	if (![tables containsObject:table]) {
		return keys;
	}
	
	NSString *sql = [NSString stringWithFormat:@"select key from %@",table];
	id<ABRecordset> results = [db sqlSelect:sql];
	while (![results eof]) {
		[keys addObject:[[results fieldAtIndex:0] stringValue]];
		[results moveNext];
	}
	[results close];
	results = nil;
	
	return keys;
}

+(NSArray*) keysInTable:(NSString*) table orderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(TestBlock) testBlock {
	NSAssert(table && table.length > 0,@"table must be provided");
	NSMutableArray *keys = [NSMutableArray array];
	NSMutableArray *sort = [NSMutableArray array];
	NSArray *testKeys = [self keysInTable:table];
	for (NSString *key in testKeys) {
		BOOL include = YES;
		NSDictionary *entry = [self entryForKey:key inTable:table];
		if (testBlock) {
			include = testBlock(key, entry[@"value"],entry[@"dateAdded"],entry[@"dateModified"]);
		}
		
		if (include && jsonOrderKey) {
			NSString *jsonValue = [self jsonValueForKey:jsonOrderKey tableKey:key inTable:table];
			if (!jsonValue) {
				jsonValue = @"";
			}
			[sort addObject:@{key:jsonValue}];
		} else if (include) {
			[keys addObject:key];
		}
	}
	
	if (jsonOrderKey) {
		// sort the dict array according to the values
		[sort sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSDictionary *dict1 = obj1;
			NSDictionary *dict2 = obj2;
			
			NSString *key1 = [dict1 allKeys][0];
			NSString *value1 = [dict1 valueForKey:key1];
			NSString *key2 = [dict2 allKeys][0];
			NSString *value2 = [dict2 valueForKey:key2];
			
			return [value1 compare:value2 options:NSCaseInsensitiveSearch];
		}];
		
		// add entries from dict array into keys
		for (NSDictionary *sortedDict in sort) {
			[keys addObject:[sortedDict allKeys][0]];
		}
	}
	
	return keys;
}

#pragma mark - Values

+(NSString*) valueForKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	if (![self openDB]) {
		status = CannotOpenDB;
		return nil;
	}
	if (![tables containsObject:table]) {
		return nil;
	}
	
	NSString* sql = [NSString stringWithFormat:@"select value from %@ where key = '%@'",table,[self sqlEscapeString:key]];
	id<ABRecordset> results = [db sqlSelect:sql];
	if ([results eof]) {
		[results close];
		results = nil;
		status = KeyNotFound;
		
		// see if key was previously deleted
		sql = [NSString stringWithFormat:@"select autoDelete from deletedRows where tableName = '%@' and key = '%@'",table,[self sqlEscapeString:key]];
		results = [db sqlSelect:sql];
		if (![results eof]) {
			if ([[results fieldAtIndex:0] booleanValue]) {
				status = KeyAutoDeleted;
			} else {
				status = KeyDeleted;
			}
		}
		[results close];
		results = nil;
		
		return nil;
	}
	
	NSString* value = [[results fieldAtIndex:0] stringValue];
	[results close];
	results = nil;
	
	status = NoError;
	return value;
}

+(NSDictionary*) dictionaryValueForKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	NSString *json = [self valueForKey:key inTable:table];
	if (!json) {
		return nil;
	}
	
	NSData* dataValue = [json dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:dataValue options:0 error:NULL];
	return responseDict;
	
}

+(id) jsonValueForKey:(NSString*) jsonKey tableKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(jsonKey && jsonKey.length > 0,@"jsonKey must be provided");
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	
	if (key == jsonValue_key && table == jsonValue_table && jsonValue_dict) {
		return jsonValue_dict[jsonKey];
	}
	
	jsonValue_key = key;
	jsonValue_table = table;
	jsonValue_dict = [self dictionaryValueForKey:key inTable:table];
	
	id results;
	if (jsonValue_dict) {
		results = jsonValue_dict[jsonKey];
	}
	
	return results;
}

+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table {
	[self setValue:value forKey:key inTable:table autoDeleteAfter:nil];
}

+(void) setValue:(NSString *)value forKey:(NSString*) key inTable:(NSString*) table autoDeleteAfter:(NSDate*) date {
	NSAssert(value && value.length > 0, @"value must be provided");
	NSAssert([NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL],@"Value must be JSON string");
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	
	if (![self openDB]) {
		status = CannotOpenDB;
		return;
	}
	
	if (![self createTable:table]) {
		status = WriteError;
		return;
	}
	
	NSString* autoDeleteDate = [self stringValueForDate:date];
	NSString* now = [self stringValueForDate:[NSDate date]];
	NSString* sql = [NSString stringWithFormat:@"select key from %@ where key = '%@'",table,key];
	id<ABRecordset> results = [db sqlSelect:sql];
	
	if ([results eof]) {
		if (date) {
			sql = [NSString stringWithFormat:@"insert into %@(key,value,autoDeleteDateTime,addedDateTime,updatedDateTime) values('%@','%@','%@','%@','%@')",table,[self sqlEscapeString:key],[self sqlEscapeString:value],autoDeleteDate,now,now];
		} else {
			sql = [NSString stringWithFormat:@"insert into %@(key,value,addedDateTime,updatedDateTime) values('%@','%@','%@','%@')",table,[self sqlEscapeString:key],[self sqlEscapeString:value],now,now];
		}
	} else {
		if (date) {
			sql = [NSString stringWithFormat:@"update %@ set value='%@',updatedDateTime='%@',autoDeleteDateTime='%@' where key = '%@'",table,[self sqlEscapeString:value],now,autoDeleteDate,[self sqlEscapeString:key]];
		} else {
			sql = [NSString stringWithFormat:@"update %@ set value='%@',updatedDateTime='%@' where key = '%@'",table,[self sqlEscapeString:value],now,[self sqlEscapeString:key]];
		}
	}
	
	[results close];
	results = nil;
	
	[db sqlExecute:sql];
	if ([db lastErrorCode] && [db lastErrorCode] < 100) {
		status = WriteError;
	} else {
		status = NoError;
	}
}

#pragma mark - Delete

+(void) deleteForKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	if (![self openDB]) {
		status = CannotOpenDB;
		return;
	}
	
	if (![self createTable:table]) {
		status = WriteError;
		return;
	}
	
	NSString* sql = [NSString stringWithFormat:@"delete from %@ where key = '%@'",table,[self sqlEscapeString:key]];
	[db sqlExecute:sql];
	
	if ([db lastErrorCode]  && [db lastErrorCode] < 100) {
		status = WriteError;
		return;
	} else {
		status = NoError;
	}
	
	
	NSString* now = [self stringValueForDate:[NSDate date]];
	sql = [NSString stringWithFormat:@"insert into deletedRows(tableName,key,deleteDateTime,autoDelete) values('%@','%@','%@',0)",table,[self sqlEscapeString:key],now];
	[db sqlExecute:sql];
	
	if ([db lastErrorCode] && [db lastErrorCode] < 100) {
		status = WriteError;
	} else {
		status = NoError;
	}
}

+(void) dropTable:(NSString *)table {
	NSAssert(table && table.length > 0,@"table must be provided");
	
	if (![self openDB]) {
		status = CannotOpenDB;
		return;
	}
	
	[db sqlExecute:[NSString stringWithFormat:@"drop table %@",table]];
	[db sqlExecute:[NSString stringWithFormat:@"delete from deletedRows where tableName='%@'",table]];
	[tables removeObject:table];
}

+(void) dropAllTables {
	if (![self openDB]) {
		status = CannotOpenDB;
		return;
	}
	
	for (NSString *table in tables) {
		[db sqlExecute:[NSString stringWithFormat:@"drop table %@",table]];
	}
	[db sqlExecute: @"delete from deletedRows"];
	
	[tables removeAllObjects];
}

#pragma mark - Misc

+(dbStatus) status {
	return status;
}

+(NSString *)guid {
	// create a new UUID which you own
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	
	// create a new CFStringRef (toll-free bridged to NSString) that you own
	NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
	
	// release the UUID
	CFRelease(uuid);
	
	return uuidString;
}


#pragma mark - private methods
+(NSDictionary*) entryForKey:(NSString*) key inTable:(NSString*) table {
	NSAssert(key && key.length > 0,@"key must be provided");
	NSAssert(table && table.length > 0,@"table must be provided");
	
	NSString* sql = [NSString stringWithFormat:@"select value,addedDateTime,updatedDateTime from %@ where key = '%@'",table,[self sqlEscapeString:key]];
	id<ABRecordset> results = [db sqlSelect:sql];

	NSString* value = [[results fieldAtIndex:0] stringValue];
	NSDate* dateAdded = [self dateValueForString:[[results fieldAtIndex:1] stringValue]];
	NSDate* dateModified = [self dateValueForString:[[results fieldAtIndex:2] stringValue]];
	[results close];
	results = nil;
	
	return @{@"value":value,@"dateAdded":dateAdded,@"dateModified":dateModified};
}

+(BOOL) openDB {
	if (db) {
		return YES;
	}
	
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentFolderPath = searchPaths[0];
	NSString *dbFilePath = [documentFolderPath stringByAppendingPathComponent: @"SimpleDB.db"];
	
	BOOL myPathIsDir;
	BOOL fileExists = [[NSFileManager defaultManager]  fileExistsAtPath: dbFilePath isDirectory: &myPathIsDir];
	db = [[ABSQLiteDB alloc] init];
	if(![db connect:dbFilePath]) {
		db = nil;
		return NO;
	}
	
	if (!fileExists) {
		[self makeDB];
	}
	
	[self checkSchema];
	autoDeleteTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow:1] interval:60 target:[SimpleDB class] selector:@selector(autoDelete:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:autoDeleteTimer forMode:NSDefaultRunLoopMode];
	
	return YES;
}

+(void) makeDB {
	NSString* sql = @"create table simpleDBSettings(key text, value text)";
	[db sqlExecute:sql];
	
	sql = @"insert into simpleDBSettings(key,value) values('schema',1)";
	[db sqlExecute:sql];
	
	sql = @"create table deletedRows(tableName text, key text, deleteDateTime datetime, autoDelete int)";
	[db sqlExecute:sql];
	sql = @"create index idx_deletedRows on deletedRows(tableName,key)";
	[db sqlExecute:sql];
}

+(void) checkSchema {
	tables = [NSMutableArray array];
	id<ABRecordset> tableList = [db tableSchema];
	while (![tableList eof]) {
		NSString *table = [[tableList fieldWithName:@"name"] stringValue];
		
		if (![self specialTable:table]) { // don't include special tables
			[tables addObject:table];
		}
		[tableList moveNext];
	}
	[tableList close];
	tableList = nil;

	// use this to update the schema value and to update any other tables that need updating with the new schema
}

+(void) autoDelete:(NSTimer *)timer {
	NSString *now = [self stringValueForDate:[NSDate date]];
	for (NSString *table in tables) {
		if (![self specialTable:table]) { // don't include special tables
			NSString* sql = [NSString stringWithFormat:@"select key from %@ where autoDeleteDateTime < '%@'",table,now];
			id<ABRecordset> results = [db sqlSelect:sql];
			while (![results eof]) {
				NSString *key = [[results fieldAtIndex:0] stringValue];
				sql = [NSString stringWithFormat:@"delete from %@ where key = '%@'",table,key];
				[db sqlExecute:sql];
				sql = [NSString stringWithFormat:@"insert into deletedRows(tableName,key,deleteDateTime,autoDelete) values('%@','%@','%@',1)",table,[self sqlEscapeString:key],now];
				[db sqlExecute:sql];
				
				[results moveNext];
			}
			
			[results close];
			results = nil;
		}
	}
	[db sqlExecute:@"ANALYZE"];
}

+(BOOL) createTable:(NSString*) table {
	if ([tables containsObject:table]) {
		return YES;
	}
	
	if ([table isEqualToString:@"simpleDBSettings"] || [table isEqualToString:@"deletedRows"]) {
		status = WriteError;
		return NO;
	}
	
	NSString *sql = [NSString stringWithFormat:@"create table %@(key text, value text, autoDeleteDateTime datetime, addedDateTime datetime, updatedDateTime datetime)",table];
	[db sqlExecute:sql];
	
	if ([db lastErrorCode] && [db lastErrorCode] < 100) {
		return NO;
	}
	sql = [NSString stringWithFormat:@"create index idx_%@_key on %@(key)",table,table];
	[db sqlExecute:sql];
	
	if ([db lastErrorCode] && [db lastErrorCode] < 100) {
		[db sqlExecute:[NSString stringWithFormat:@"drop table %@",table]];
		return NO;
	}
	
	sql = [NSString stringWithFormat:@"create index idx_%@_autoDeleteDateTime on %@(autoDeleteDateTime)",table,table];
	[db sqlExecute:sql];
	if ([db lastErrorCode] && [db lastErrorCode] < 100) {
		[db sqlExecute:[NSString stringWithFormat:@"drop table %@",table]];
		return NO;
	}
	
	[tables addObject:table];
	
	return YES;
}

+(BOOL) specialTable:(NSString*) table {
	return [table isEqualToString:@"simpleDBSettings"]
	|| [table isEqualToString:@"deletedRows"]
	|| [table isEqualToString:@"sqlite_stat1"];
}

+(NSString*) stringValueForDate:(NSDate*) date {
	if (!stringValueFormatter) {
		stringValueFormatter = [[NSDateFormatter alloc] init];
		[stringValueFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'.'SSSZZZZZ"];
	}
	
	NSString *strDate = [stringValueFormatter stringFromDate:date];
	
	return strDate;
}

+(NSDate*) dateValueForString:(NSString*) string {
	if (!stringValueFormatter) {
		stringValueFormatter = [[NSDateFormatter alloc] init];
		[stringValueFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'.'SSSZZZZZ"];
	}
	
	NSDate *date = [stringValueFormatter dateFromString:string];
	
	return date;
}

+(NSString*)sqlEscapeString:(NSString *) string {
	return [string stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

@end
