//  Created by Aaron Bratcher on 9/27/13.

#import <Foundation/Foundation.h>

typedef enum {
    NoError,
    KeyNotFound,
	KeyDeleted,
	KeyAutoDeleted,
    ReadError,
    WriteError,
    CannotOpenDB
} dbStatus;

typedef BOOL(^TestBlock)(NSString* key, NSString* value, NSDate* dateAdded, NSDate* dateModified);


/*! This protocol must be supported to use the instanceOfClass:forKey:inTable and setValueOfObject:forKey:inTable calls  */
@protocol SimpleDBSerialization <NSObject>

-(id)initWithJSON:(NSString*)json;
-(NSString*) jsonValue;
-(NSString*) keyValue;

@end

@interface SimpleDB : NSObject

#pragma mark - Keys
/*! Returns BOOL value if table contains key
 * \param key Key to lookup in table. This parameter is required.
 * \param table Table to search for key. This parameter is required.
 */
+(BOOL) hasKey:(NSString*) key inTable:(NSString*) table;


/*! Returns NSArray of unique keys in given table. If no keys exist, array will be empty.
 * \param table Name of the table to return keys for. This parameter is required.
 */
+(NSArray*) keysInTable:(NSString*) table;


/*! Returns NSArray of unique keys in given table optionally ordered by a value in the JSON and optionally including only those allowed by the TestBlock.
 * \param table Name of the table to return keys for. This parameter is required.
 * \param jsonOrderKey Name of the JSON key in the table's value. Returned keys will be accordingly ordered by the value that corresponds to this key. If the key does not exist, an empty value is used for sorting purposes. This parameter is optional.
 * \param testBlock A block that must return a BOOL value for whether or not to include the key. The key and value passed to the block are the original key and value passed to the database. This parameter is optional.
 */
+(NSArray*) keysInTable:(NSString*) table orderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(TestBlock) testBlock;


/*! Returns NSArray of unique keys in given table optionally reverse ordered by a value in the JSON and optionally including only those allowed by the TestBlock.
 * \param table Name of the table to return keys for. This parameter is required.
 * \param jsonOrderKey Name of the JSON key in the table's value. Returned keys will be accordingly ordered by the value that corresponds to this key. If the key does not exist, an empty value is used for sorting purposes. This parameter is optional.
 * \param testBlock A block that must return a BOOL value for whether or not to include the key. The key and value passed to the block are the original key and value passed to the database. This parameter is optional.
 */
+(NSArray*) keysInTable:(NSString*) table reverseOrderByJSONValueForKey:(NSString*)jsonOrderKey passingTest:(TestBlock) testBlock;

#pragma mark - Values
/*! Returns the value for key in table as NSString. If the key does not exist, then nil is returned and the status is updated to KeyNotFound, KeyDeleted, or KeyAutoDeleted.
 * \param key Key to lookup in table. This parameter is required.
 * \param table Table to search for key and return value for. This parameter is required.
 */
+(NSString*) valueForKey:(NSString*) key inTable:(NSString*) table;


/*! Returns the value for key in table as NSDictionary. If the key does not exist, then nil is returned and the status is updated to KeyNotFound, KeyDeleted, or KeyAutoDeleted.
 * \param key Key to lookup in table. This parameter is required.
 * \param table Table to search for key and return value for. This parameter is required.
 */
+(NSDictionary*) dictionaryValueForKey:(NSString*) key inTable:(NSString*) table;


/*! Returns the value contained in the JSON for the jsonKey given as NSString. The value is retrieved from table with given key and then parsed to retrieve the JSON value. If the either key is not found, then nil is returned.
 * \param jsonKey The key to use when parsing the value originally passed to the database. This parameter is required.
 * \param key The key to lookup in table. This parameter is required.
 * \param table Table to search for key and retrieve value for parsing of the JSON. This parameter is required.
 */
+(id) jsonValueForKey:(NSString*) jsonKey tableKey:(NSString*) key inTable:(NSString*) table;



/*! Returns an instance of the named class initialized with the JSON value for the given key. If the key does not exist, then nil is returned and the status is updated to KeyNotFound, KeyDeleted, or KeyAutoDeleted.
 * \param className The name of the class to be instantiated. It must conform to the SimpleDBSerialization protocol. This parameter is required.
 * \param key The key to lookup in table. This parameter is required.
 * \param table Table to search for key and retrieve value for parsing of the JSON. This parameter is required.
 */

+(id)instanceOfClass:(NSString*)className forKey:(NSString*) key inTable:(NSString*) table;


/*! Sets the value in table for the given key. If the key already exists, then the value is updated.
 * \param value The value to save into the table. This parameter is required.
 * \param key The unique key associated with the value in the given table. This parameter is required.
 * \param table The table to store the key/value pair into. This parameter is required.
 */
+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table;

/*! Sets the value in table for the given key to be automatically removed after the given date. If the key already exists, then the value is updated.
 * \param value The value to save into the table. This parameter is required.
 * \param key The unique key associated with the value in the given table. This parameter is required.
 * \param table The table to store the key/value pair into. This parameter is required.
 * \param date The date/time after which the given key/value pair are to be automatically removed from the given table. This parametr is optional.
 */
+(void) setValue:(NSString*) value forKey:(NSString*) key inTable:(NSString*) table autoDeleteAfter:(NSDate*) date;


/*! Sets the value of the object in table for the given key. If the key already exists, then the value is updated.
 * \param object The object to save  the value of into the table. This parameter is required.
 * \param table The table to store the key/value pair into. This parameter is required.
 */
+(void) setValueOfObject:(id)object inTable:(NSString*) table;


/*! Sets the value of the object in table for the given key to be automatically removed after the given date. If the key already exists, then the value is updated.
 * \param object The object to save  the value of into the table. This parameter is required.
 * \param table The table to store the key/value pair into. This parameter is required.
 * \param date The date/time after which the given key/value pair are to be automatically removed from the given table. This parametr is optional.
 */
+(void) setValueOfObject:(id)object inTable:(NSString*) table autoDeleteAfter:(NSDate*) date;

#pragma mark - Delete
/*! Deletes the key/value pair in the given table. Deletions are recorded so the status can be updated when retrieving values.
 * \param key The unique key associated with the value in the given table. This parameter is required.
 * \param table The table that the key/value pair is stored in. This parameter is required.
 */
+(void) deleteForKey:(NSString*) key inTable:(NSString*) table;


/*! Removes the table from the database. Any recorded deletions are also removed.
 * \param table The table used to store key/value pairs. This parameter is required.
 */
+(void) dropTable:(NSString*) table;

/*! Removes all tables from the database. Any recorded deletions are also removed. */
+(void) dropAllTables;

#pragma mark - Misc

/*! Returns the status of the last operation.
 NoError,
 KeyNotFound,
 KeyDeleted,
 KeyAutoDeleted,
 ReadError,
 WriteError,
 CannotOpenDB
 */
+(dbStatus) status;

/*! Returns a unique identifier as a string that can safely be used as a key. */
+(NSString *)guid;
@end
