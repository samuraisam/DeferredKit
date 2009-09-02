//
//  DKDeferredTests.m
//  DeferredKit
//
//  Created by Samuel Sutch on 9/1/09.
//

#import "DKDeferredTests.h"
#import <DeferredKit/DeferredKit.h>


@interface DKDeferredTests : GTMTestCase

- (void)testCallback;
- (void)testErrback;
- (void)testSuccess;
- (void)testFail;
- (void)testWait;
- (void)testGatherResults;
- (void)testCancel;
- (void)testCanceller;
- (void)testPause;
- (void)testChained;
- (void)testDeferredList;
- (void)testDeferredListError;
- (void)testDeferredListFireOnOne;
- (void)testDeferredURL;
- (void)testDeferredURLDecodeF;
- (void)testDeferredJSONProxy;
- (void)testThreadedDeferred;
- (void)testThreadedDeferredList;
- (void)testThreadedDeferredCancel;
- (void)testThreadedDeferredPause;
- (void)testThreadedDeferredCallback;
- (void)testThreadedDeferredErrback;
- (void)testThreadedDeferredChained;

@end


@implementation DKDeferredTests

- (void)testCallback {
	id _deferredCallback(id r) {
		STAssertEqualStrings(r, @"this is a callback mother fucker", @"callback content", nil);
		return nil;
	}
	DKDeferred *d = [DKDeferred deferred];
	[d addCallback:callbackP(_deferredCallback)];
	[d callback:@"this is a callback mother fucker"];
}

- (void)testErrback {
	id _deferredCallback(id r) { return r; }
	id _deferredErrback(id err) {
		STAssertTrue([err isKindOfClass:[NSError class]], @"error type", nil);
		STAssertEqualStrings([(NSError *)err domain], @"doomain", @"errback content", nil);
		STAssertNil([[(NSError *)err userInfo] objectForKey:@"noKey"], @"error dict", nil);
		return nil;
	}
	DKDeferred *d = [DKDeferred deferred];
	[d addErrback:callbackP(_deferredErrback)];
	[d addCallback:callbackP(_deferredCallback)];
	[d errback:[NSError errorWithDomain:@"doomain" code:420 userInfo:EMPTY_DICT]];
}

- (void)testSuccess {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testFail {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testWait {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testGatherResults { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testCallLater { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testCancel {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testCanceller {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testPause { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testChained {
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testDeferredList {
	id _cbDeferredList(id r) {
		//NSLog(@"deferredList:%@", r);
		STAssertTrue([r isKindOfClass:[NSArray class]], @"deferred list type", nil);
//		STAssertEqualStrings(r, @"this is a callback mother fucker", @"callback content", nil);
		return nil;
	}
	id _cbReturnValue(id results) {
		STAssertFalse(results == [NSNull null], @"nsnull results", nil);
		return results;
	}
	
	DKDeferred *d1 = [DKDeferred deferred];
	DKDeferred *d2 = [DKDeferred deferred];
	DKDeferredList *ll = [DKDeferredList deferredList:array_(d1, d2)];
	[d1 addCallback:callbackP(_cbReturnValue)];
	[d2 addCallback:callbackP(_cbReturnValue)];
	[d1 callback:@"deferred one"];
	[d2 callback:@"deferred two"];
	[ll addCallback:callbackP(_cbDeferredList)];
}

- (void)testDeferredListError { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testDeferredListFireOnOne { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testDeferredURL { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testDeferredURLDecodeF { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testDeferredJSONProxy { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferred { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredList { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredCancel { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredPause { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredCallback { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredErrback { 
	STAssertTrue(NO, @"not implemented", nil);
}

- (void)testThreadedDeferredChained { 
	STAssertTrue(NO, @"not implemented", nil);
}


@end
