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

## Sample Class and Use

##Gift.h
``` objective-c
#import <Foundation/Foundation.h>
#import "SimpleDB.h"

extern NSString *const kGiftTable;

@interface Gift : NSObject<SimpleDBSerialization>

@property (copy) NSString *event_id;
@property (copy) NSString *gift_id;
@property (strong) NSDate *date;
@property (copy) NSString *name;
@property (copy) NSString *email;
@property int giftAmount;
@property BOOL acknowledged;

+(instancetype) instanceForKey:(NSString *)key;
-(void) save;
-(instancetype) initWithDictionary:(NSDictionary *)template;
-(instancetype) initWithJSON:(NSString *)json;
-(NSDictionary *) dictionaryValue;

@end
```


##Gift.m
``` objective-c
#import "Gift.h"

NSString *const kGiftTable = @"Gifts";

@implementation Gift

+(instancetype) instanceForKey:(NSString *)key {
	return [SimpleDB instanceOfClassForKey:key inTable:kGiftTable];
}

-(void) save {
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    
	[comps setYear:[comps year] + 1];
	NSDate *nextYear = [gregorian dateFromComponents:comps];
    
	[SimpleDB setValueOfObject:self inTable:kGiftTable autoDeleteAfter:nextYear];
}

-(instancetype) initWithDictionary:(NSDictionary *)gift {
	if (self = [super init]) {
		self.event_id = gift[@"event_id"];
		self.gift_id = gift[@"id"];
        self.date = [SimpleDB dateValueForString:gift[@"date"]];
		self.giftAmount = [gift[@"giftAmount"] intValue];
		self.acknowledged = [gift[@"acknowledged"] boolValue];
		self.name = gift[@"name"];
		self.email = gift[@"email"];
		return self;
	}
    
	return nil;
}

-(instancetype) initWithJSON:(NSString *)json {
	NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataValue] options:0 error:NULL];
    
	return [self initWithDictionary:dict];
}

-(NSDictionary *) dictionaryValue {
	NSMutableDictionary *gift = [NSMutableDictionary dictionaryWithDictionary:@{ @"id": self.gift_id
	                                                                             , @"contactId": self.contact_id
	                                                                             , @"date": [SimpleDB stringValueForDate:self.date]
	                                                                             , @"recognitionName": self.recognitionName
	                                                                             , @"giftAmount": @(self.giftAmount)
	                                                                             , @"acknowledged": (self.acknowledged ? @"YES" : @"NO") }];
    
	if (self.event_id) {
		gift[@"event_id"] = self.event_id;
	}
    
	if (self.name) {
		gift[@"name"] = self.name;
	}
    
	if (self.email) {
		gift[@"email"] = self.email;
	}
    
	return gift;
}

-(NSString *) jsonValue {
	NSDictionary *dict = [self dictionaryValue];    
	return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

-(NSString *) keyValue {
	return self.gift_id;
}

-(BOOL) isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) return NO;
    
	Gift *testObject = object;
	return [testObject.gift_id isEqualToString:self.gift_id];
}

-(NSUInteger) hash {
	return [self.gift_id hash];
}

@end
```

#Using the class
``` objective-c

Gift *gift = [Gift instanceForKey:@"testKey"];
if (gift) {
  gift.acknowledged = YES;
}

[gift save];
