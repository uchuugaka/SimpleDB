SimpleDB
========

SimpleDB is a key-value persistent database that makes it very easy to store and retrieve data or object state for your application.

Because the values stored must be JSON, sorting can be accomplished and specific parts of the data can be returned. This currently depends on my ABSQLite access classes. I will be phasing out the dependency of these classes over time. I will also add a sample project. Please provide any and all feedback.

## Special Features
- Very easy to use - NO SQL REQUIRED!
- Auto-Delete option for entries after specified date
- No direct database interaction required to use the class - it does it all
- All methods are class level methods, so no instance of the class required
- Save and retrieve objects that conform to the SimpleDBSerialization protocol
- Thread safe

## Getting Started
- Add the SimpleDB_Classes and the ABSQLite_Classes folders to your project
	or use [CocoaPods](http://cocoapods.org)
	*pod 'SimpleDB', '~> 1.1'*

- Include the SQLite library in the linking area of XCode
- Start saving and retrieving data

``` objective-c
[SimpleDB setValue:userInfoJSON forKey:userKey inTable:@"Users"];
NSArray *users = [SimpleDB keysInTable:@"Users"];
NSDictionary *userDict = [SimpleDB dictionaryValueForKey:users[0] inTable:@"Users"];
```

## Full API
``` objective-c
@protocol SimpleDBSerialization <NSObject>
-(id)initWithJSON:(NSString*)json;
-(NSString*) jsonValue;
-(NSString*) keyValue;
@end

+(BOOL) hasKey:(NSString*) key inTable:(NSString*) table;
+(NSArray*) keysInTable:(NSString*) table;
+(NSArray*) keysInTable:(NSString*) table orderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(BOOL (^)(NSString* key, NSString* value, NSDate* dateAdded, NSDate* dateModified));
+(NSArray*) keysInTable:(NSString*) table reverseOrderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(BOOL (^)(NSString* key, NSString* value, NSDate* dateAdded, NSDate* dateModified));

+(NSString*) valueForKey:(NSString*) key inTable:(NSString*) table;
+(NSDictionary*) dictionaryValueForKey:(NSString*) key inTable:(NSString*) table;
+(id) jsonValueForKey:(NSString*) jsonKey tableKey:(NSString*) key inTable:(NSString*) table;
+(id) instanceOfClassForKey:(NSString*) key inTable:(NSString*) table;

+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table;
+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table autoDeleteAfter:(NSDate*) date;
+(void) setValueOfObject:(id)object inTable:(NSString*) table;
+(void) setValueOfObject:(id)object inTable:(NSString*) table autoDeleteAfter:(NSDate*) date;

+(void) deleteForKey:(NSString*) key inTable:(NSString*) table;

+(void) dropTable:(NSString*) table;
+(void) dropAllTables;

+(dbStatus) status;
+(NSString*) guid;
+(NSString*) stringValueForDate:(NSDate*) date;
+(NSDate*) dateValueForString:(NSString*) string;

```

## ARC
The enclosed classes require ARC

## License

SimpleDB is available under the MIT license. See included license file
