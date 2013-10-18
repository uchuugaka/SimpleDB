SimpleDB
========

SimpleDB is a key-value persistent database that makes it very easy to store and retrieve data for your application.

Because the values stored must be JSON, sorting can be accomplished and specific parts of the data can be returned. This is the initial upload that depends on my ABSQLite access classes. I will be phasing out the dependency of these classes over time. I will also add a sample project. Please provide any and all feedback.

## Special Features
- Very easy to use - NO SQL REQUIRED!
- Auto-Delete option for entries after specified date
- No direct database interaction required to use the class - it does it all
- All methods are class level methods, so no instance of the class required
- Thread safe

## Getting Started
- Add the SimpleDB Source folder to your project
- Include the SQLite library in the linking area of XCode
- Start saving and retrieving data

``` objective-c
[SimpleDB setValue:userInfoJSON forKey:userKey inTable:@"Users"];
NSArray *users = [SimpleDB keysInTable:@"Users"];
NSDictionary *userDict = [SimpleDB dictionaryValueForKey:users[0] inTable:@"Users"];
```

## API
``` objective-c
+(BOOL) hasKey:(NSString*) key inTable:(NSString*) table;
+(NSArray*) keysInTable:(NSString*) table;
+(NSArray*) keysInTable:(NSString*) table orderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(BOOL (^)(NSString* key, NSString* value, NSDate* dateAdded, NSDate* dateModified));

+(NSString*) valueForKey:(NSString*) key inTable:(NSString*) table;
+(NSDictionary*) dictionaryValueForKey:(NSString*) key inTable:(NSString*) table;
+(id) jsonValueForKey:(NSString*) jsonKey tableKey:(NSString*) key inTable:(NSString*) table;

+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table;
+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table autoDeleteAfter:(NSDate*) date;

+(void) deleteForKey:(NSString*) key inTable:(NSString*) table;

+(void) dropTable:(NSString*) table;

+(dbStatus) status;
+(NSString*) guid;
```

## ARC
The enclosed classes require ARC

## License

SimpleDB is available under the MIT license. See included license file
