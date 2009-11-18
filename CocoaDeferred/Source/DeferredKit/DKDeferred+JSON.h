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

/**
 * Returns a Deferred which will callback with the native representation
 * of the JSON document at <code>aUrl</code>
 */
+ (id)loadJSONDoc:(NSString *)aUrl;

/**
 * Returns a DKJSONServiceProxy which you can use to transparently call
 * JSON-RPC methods on your web service. 
 */
+ (id)jsonService:(NSString *)aUrl;

/**
 * Returns a DKJSONServiceProxy which you can use to transparently call
 * JSON-RPC methods on your web service located at <code>aUrl</code>. It will be 
 * preconfigured to use <code>serviceName</code> as the method.
 */
+ (id)jsonService:(NSString *)aUrl name:(NSString *)serviceName;

@end

/**
 * DKJSONServiceProxy
 *
 * Adds some syntatic sugar to interacting with a JSON-RPC Service
 *  <pre>
 *    id _fromJSONResponse(id result) { // result will be an NSDictionary or NSArray
 *      // do some stuff
 *      return nil;
 *    }
 *    id _fromJSONResponseError(id result) { 
 *      // result will be an NSError(userInfo={error:NSDictionary(jsonRPCError)})
 *      NSLog(@"JSON Service Error: %@", [[result userInfo] objectForKey:@"error"]);
 *      // do some stuff
 *      return nil;
 *    }
 *
 *    id service = [DKDeferred jsonService:@"http://url.net/j" name:@""];
 *    [[[service someNamespace] someMethod:array_(arg1, arg2)]
 *     addCallbacks:callbackP(_fromJSONResponse) :callbackP(_fromJSONResponseError)];
 *  </pre>
 */
@interface DKJSONServiceProxy : NSObject
{
  NSString *serviceURL;
  NSString *serviceName;
}

/**
 * Returns an initialized DKJSONServiceProxy which will direct method calls to 
 * <code>url</code>
 */
- (id)initWithURL:(NSString *)url;

/**
 * Returns an initialized DKJSONServiceProxy which will direct method calls to 
 * <code>url</code> with the method preconfigred to <code>serviceName</code>.
 */
- (id)initWithURL:(NSString *)aUrl serviceName:(NSString *)aService;

/**
 * Executes a JSON-RPC call on the server. Returns a deferred which will callback
 * with the native representation of the method results.
 */
- (id):(NSArray *)args;

@end