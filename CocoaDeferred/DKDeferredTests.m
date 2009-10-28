//
//  DKDeferredTests.m
//  DeferredKit
//
//  Created by Samuel Sutch on 9/1/09.
//

#import "DKDeferredTests.h"
#import <DeferredKit/DeferredKit.h>


@interface DKDeferredTests : GTMTestCase {
	id _pauseTestResult;
}

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
		NSLog(@"hello hello hello");
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

- (void)testSuccess {}
- (void)testFail {}
- (void)testWait {}
- (void)testGatherResults {}
- (void)testCallLater {}
- (void)testCancel {}
- (void)testCanceller {}

- (id)_pauseTestCallback:(id)r {
	NSLog(@"pauseTestCallback");
	STAssertEqualStrings(r, @"this is a callback mother fucker", @"callback content", nil);
	STAssertEqualStrings(_pauseTestResult, @"this has been altered", @"paused state change content", nil);
	[_pauseTestResult release];
	_pauseTestResult = [r retain];
	return nil;
}

- (void)testPause {
	DKDeferred *d = [DKDeferred deferred];
	[d pause];
	[d addCallback:callbackTS(self, _pauseTestCallback:)];
	STAssertNil(_pauseTestResult, @"", nil);
	_pauseTestResult = [@"this has been altered" retain];
	[d callback:@"this is a callback mother fucker"];
	STAssertEqualStrings(_pauseTestResult, @"this has been altered", @"paused state change content", nil);
	[d resume];
	STAssertEqualStrings(_pauseTestResult, @"this is a callback mother fucker", @"after resume change content", nil);
}

- (void)testChained {}

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

- (void)testDeferredListError {}
- (void)testDeferredListFireOnOne {}
- (void)testDeferredURL {}
- (void)testDeferredURLDecodeF {}
- (void)testDeferredJSONProxy {}
- (void)testThreadedDeferred {}
- (void)testThreadedDeferredList {}
- (void)testThreadedDeferredCancel {}
- (void)testThreadedDeferredPause {}
- (void)testThreadedDeferredCallback {}
- (void)testThreadedDeferredErrback {}
- (void)testThreadedDeferredChained {}


@end
