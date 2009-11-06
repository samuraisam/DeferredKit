//
//  DKDeferred+JSON.m
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import "DKDeferred+JSON.h"

/**
 * == DKDeferredURLConnection Decode Functions
 */
id _decodeJSON(id results) {
	if (results && ! (results == [NSNull null])) {
		NSString *objstr = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
		NSError *error = nil;
		id ret = [[[SBJSON alloc] init]
							objectWithString:objstr error:&error];
		if (!ret && error) {
			return error;
		}
		[objstr release];
		return ret;
	}
	return nil;
}

id _decodeJSONResonse(id results) {
	if (results && ! (results == [NSNull null]) && 
			[results isKindOfClass:[NSDictionary class]]) {
		id error = [results objectForKey:@"error"];
		if (! error || error == [NSNull null]) {
			return results;
		}
		return [NSError errorWithDomain:DKDeferredURLErrorDomain 
															 code:DKDeferredURLError 
													 userInfo:dict_(error, @"error")];
	}
	return [NSError errorWithDomain:DKDeferredErrorDomain code:DKDeferredURLError userInfo:EMPTY_DICT];
}


@implementation DKDeferred (JSONAdditions)

+ (id)loadJSONDoc:(NSString *)aUrl {
	return [[[DKDeferredURLConnection alloc] 
					initWithRequest:[NSURLRequest 
													 requestWithURL:[NSURL URLWithString:aUrl]]
					pauseFor:0.0f
          decodeFunction:callbackP(_decodeJSON)] autorelease];
}

+ (id)jsonService:(NSString *)aUrl name:(NSString *)serviceName {
	return [[[DKJSONServiceProxy alloc] 
          initWithURL:aUrl serviceName:serviceName] autorelease];
}

+ (id)jsonService:(NSString *)aUrl {
  return [self jsonService:aUrl name:@""];
}

@end

@implementation DKJSONServiceProxy

- (id)initWithURL:(NSString *)aUrl {
	return [self initWithURL:aUrl serviceName:nil];
}

- (id)initWithURL:(NSString *)aUrl serviceName:(NSString *)aService {
	if ((self = [super init])) {
		serviceURL = [aUrl retain];
		serviceName = [aService retain];
	}
	return self;
}

- (void)dealloc {
  [serviceURL release];
  [serviceName release];
  [super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<DKJSONServiceProxy url=%@ service=%@>", 
					serviceURL, serviceName];
}

- (id):(NSArray *)args {
	NSDictionary *methodCall = dict_(serviceName, @"method", args, @"params", _uuid1(), @"id");
	//NSLog(@"methodCall:%@", methodCall);
	NSString *post = [[[SBJSON alloc] init] stringWithObject:methodCall];
	NSMutableURLRequest *req = [[NSMutableURLRequest alloc] 
															initWithURL:[NSURL URLWithString:serviceURL]];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
	DKDeferred *d = [[DKDeferredURLConnection alloc] 
									 initWithRequest:req pauseFor:0.0f
									 decodeFunction:[callbackP(_decodeJSONResonse) 
																	 composeWith:callbackP(_decodeJSON)]];
	return d;
}

- (id)callWithName:(NSString *)name args:(NSArray *)args {
  if (serviceName)
    [serviceName release];
	serviceName = [name retain];
	return [self :args];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	NSMethodSignature *ret = nil;
	if (! (ret = [super methodSignatureForSelector:aSelector])) { 
		ret = [NSMethodSignature signatureWithObjCTypes:"@:@@@"];
	}
	return ret;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	NSString *mName = [[NSString stringWithUTF8String:sel_getName([invocation selector])]
										 stringByReplacingOccurrencesOfString:@":" withString:@""];
	NSString *method;
	if (! (serviceName == nil)) {
		method = [NSString stringWithFormat:@"%@.%@", serviceName, mName];
	} else {
		method = mName;
	}
	id callingArg = nil;
	[invocation getArgument:&callingArg atIndex:2];
	if (! (callingArg == nil) && [callingArg isKindOfClass:[NSArray class]]) {
		[invocation setSelector:@selector(callWithName:args:)];
		[invocation setArgument:&method atIndex:2];
		[invocation setArgument:&callingArg atIndex:3];
		[invocation invokeWithTarget:self];
		return;
	}
	[invocation setSelector:@selector(initWithURL:serviceName:)];
	[invocation setArgument:&serviceURL atIndex:2];
	[invocation setArgument:&method atIndex:3];
	[invocation invokeWithTarget:[DKJSONServiceProxy alloc]];
}

@end
