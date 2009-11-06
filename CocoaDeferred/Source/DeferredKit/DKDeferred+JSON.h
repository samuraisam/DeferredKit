//
//  DKDeferred+JSON.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import <Foundation/Foundation.h>
#import "JSON/JSON.h"
#import "DKDeferred.h"

@interface DKDeferred (JSONAdditions)

+ (id)loadJSONDoc:(NSString *)aUrl;
+ (id)jsonService:(NSString *)aUrl;
+ (id)jsonService:(NSString *)aUrl name:(NSString *)serviceName;

@end

/**
 * = DKJSONServiceProxy =
 * 
 * Adds some syntatic sugar to interacting with a JSON-RPC Service
 *		
 *		id _fromJSONResponse(id result) { // result will be an NSDictionary or NSArray
 *			// do some stuff
 *			return nil;
 *		}
 *		id _fromJSONResponseError(id result) { 
 *			// result will be an NSError(userInfo={error:NSDictionary(jsonRPCError)})
 *			NSLog(@"JSON Service Error: %@", [[result userInfo] objectForKey:@"error"]);
 *			// do some stuff
 *			return nil;
 *		}
 *
 *		id service = [DKDeferred jsonService:@"http://url.net/j" name:@""];
 *		[[[service someNamespace] someMethod]
 *		 addCallbacks:callbackP(_fromJSONResponse) :callbackP(_fromJSONResponseError)];
 */
@interface DKJSONServiceProxy : NSObject
{
	NSString *serviceURL;
	NSString *serviceName;
}

- (id)initWithURL:(NSString *)url;
- (id)initWithURL:(NSString *)aUrl serviceName:(NSString *)aService;
- (id):(NSArray *)args; // returns deferred

@end