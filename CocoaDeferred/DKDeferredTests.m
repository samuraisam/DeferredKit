//
//  DKDeferredTests.m
//  DeferredKit
//
//  Created by Samuel Sutch on 9/1/09.
//

#import "DKDeferredTests.h"
#import <DeferredKit/DeferredKit.h>


@interface DKDeferredTests : GTMTestCase {
  // pause 
  id _pauseTestResult;
  // pool 
  id<DKKeyedPool> _pool;
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
- (void)testPausedURL;
- (void)testInline;
- (void)testInlineError;
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

- (void)testMappedPriorityQueue;
- (void)testMappedPriorityQueueWithDeferreds;
- (void)testDeferredPausedPool;

@end


@implementation DKDeferredTests

- (void)testCallback {
  id _deferredCallback(id r) {
    NSLog(@"hello hello hello");
    STAssertEqualStrings(r, @"this is a callback mother chicken pluckerer", @"callback content", nil);
    return nil;
  }
  DKDeferred *d = [DKDeferred deferred];
  [d addCallback:callbackP(_deferredCallback)];
  [d callback:@"this is a callback mother chicken pluckerer"];
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
  STAssertEqualStrings(r, @"this is a callback mother chicken pluckerer", @"callback content", nil);
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
  [d callback:@"this is a callback mother chicken pluckerer"];
  STAssertEqualStrings(_pauseTestResult, @"this has been altered", @"paused state change content", nil);
  [d resume];
  STAssertEqualStrings(_pauseTestResult, @"this is a callback mother chicken pluckerer", @"after resume change content", nil);
}

- (void)testPausedURL {
  id _cb(id r) {
    NSLog(@"_cb:%@", [[r description] substringToIndex:100]);
    if (isDeferred(r))
      return [r addBoth:callbackP(_cb)];
    return r;
  }
  NSLog(@"creating url deferred..");
  DKDeferred *d = [DKDeferred loadURL:@"http://google.com/" paused:YES];
  [d addBoth:callbackP(_cb)];
  NSLog(@"added url deferred callbacks");
  [d performSelector:@selector(callback:) withObject:nil afterDelay:2.0f];
  id res = waitForDeferred([DKDeferredList deferredList:array_(d)]);
  NSLog(@"res... %@", [[res description] substringToIndex:100]);
}

- (void)testInline {
  id _printSomething(id r) {
    NSLog(@"i am being called");
    STAssertEqualStrings(r, @"omgwtf", @"callback", nil);
    r = [NSString stringWithFormat:@"something:%@", r];
    return r;
  }
  DKDeferred *d = [DKDeferred wait:5.0f value:@"omgwtf"];
  [d addCallback:callbackP(_printSomething)];
  //id r = [[[DKWaitForDeferred alloc] initWithDeferred:d] result]; //waitForDeferred(d);
  id r = waitForDeferred(d);
  STAssertEqualStrings(r, @"something:omgwtf", @"after inline callback", nil);
}

- (void)testInlineError {
}

- (void)testChained {}

- (void)testDeferredList {
  id _cbDeferredList(id r) {
    //NSLog(@"deferredList:%@", r);
    STAssertTrue([r isKindOfClass:[NSArray class]], @"deferred list type", nil);
//    STAssertEqualStrings(r, @"this is a callback mother chicken pluckerer", @"callback content", nil);
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

- (void)testMappedPriorityQueue {
  id<MappedPriorityQueue> q = [[[DKMappedPriorityQueue alloc] init] autorelease];
  NSArray *dat = array_(@"bmw", @"audi", @"vespa", @"volkswagen", @"face", @"mazda", @"nissan", @"hando");
  for (NSString *k in dat) {
    [q enqueue:k key:k];
  }
  NSMutableArray *alphabetical = [NSMutableArray array];
  NSArray *obj;
  while ((obj = [q dequeue])) {
    [alphabetical addObject:[obj objectAtIndex:0]];
  }
  q = [[[DKMappedPriorityQueue alloc] init] autorelease];
  for (NSString *k2 in dat) {
    [q enqueue:k2 key:k2];
  }
  STAssertEquals([q count], 8, @"priority queue count", nil);
  STAssertEqualStrings([alphabetical objectAtIndex:0], @"audi", @"first element", nil);
  STAssertEqualStrings([q peek], @"audi", @"peek at priority queue", nil);
  for (NSString *s in alphabetical) {
    obj = [q dequeue];
    STAssertEqualStrings(s, [obj objectAtIndex:0], @"dequeue sanity object", nil);
    STAssertEqualStrings(s, [obj objectAtIndex:1], @"dequeue sanity key", nil);
  }
  
  NSMutableArray *dates = [NSMutableArray array];
  for (int i = 0; i < 10; i++) {
    [dates addObject:[NSDate dateWithTimeIntervalSinceNow:-(rand() % 100 + 1)]];
  }
  NSArray *systemSortedDates = [dates sortedArrayUsingSelector:@selector(compare:)];
  q = [[[DKMappedPriorityQueue alloc] init] autorelease];
  for (NSDate *d in dates) {
    [q enqueue:d key:[NSString stringWithFormat:@"date-%i", [d timeIntervalSinceNow]]];
  }
  STAssertTrue(([q count] == 10), @"priority queue count", nil);
  NSMutableArray *sortedDates = [NSMutableArray array];
  while ((obj = [q dequeue])) {
    [sortedDates addObject:[obj objectAtIndex:0]];
  }
  for (int j = 0; j < [systemSortedDates count]; j++) {
    STAssertTrue([[systemSortedDates objectAtIndex:j] isEqualToDate:[sortedDates objectAtIndex:j]], @"date sort sanity", nil);
  }
}

- (void)testMappedPriorityQueueWithDeferreds {
//  id<MappedPriorityQueue> q = [[[DKMappedPriorityQueue alloc] init] autorelease];
//  id _cb(id r) {
//    NSLog(@"omg, wtf!!");
//    return r;
//  }
//  id _waitSomeTime(id r) {
//    sleep((rand() % 10 + 1));
//    return r;
//  }
//  id _gotGoogle(id r) {
//    id ret = [[@"gotGoogle: " stringByAppendingString:[r description]] substringToIndex:100];
//    NSLog(ret);
//    return ret;
//  }
//  DKDeferred *d;
//  for (int i = 0; i < 15; i++) {
//    d = [DKDeferred deferInThread:callbackP(_waitSomeTime) withObject:@"omg hello!"];
////    [d pause];
//    d.started = [NSDate dateWithTimeIntervalSinceNow:-(rand() % 100 + 1)];
//    [q enqueue:d key:[@"hello-" stringByAppendingFormat:@"%i", i] prioritySelector:@selector(compareDates:)];
//    NSLog(@"adding started %@", d.started);
//  }
//  NSArray *obj;
//  NSMutableArray *ordered = [NSMutableArray array];
//  while ((obj = [q dequeue])) {
//    NSLog(@"resuming started %@", [[obj objectAtIndex:0] started]);
////    [[obj objectAtIndex:0] resume];
//    [ordered addObject:[obj objectAtIndex:0]];
//  }
//  id res = waitForDeferred([DKDeferredList deferredList:ordered]);
//  NSLog(@"got... %@", res);
//  NSArray *dat = array_(@"bmw", @"audi", @"vespa", @"volkswagen", @"dodge", @"crysler", @"chevorlet", @"monkeys",
//                        @"face", @"mazda", @"nissan", @"honda", @"rolling%20stones", @"chili%20peppers", @"more%20monkeys");
//  q = [[[DKMappedPriorityQueue alloc] init] autorelease];
//  for (NSString *k in dat) {
//    d = [DKDeferred loadURL:[@"http://google.com/search?q=" stringByAppendingString:k] paused:YES];
//    d.started = [NSDate dateWithTimeIntervalSinceNow:-(rand() % 100 + 1)];
//    [d addCallback:callbackP(_gotGoogle)];
//    [q enqueue:d key:k prioritySelector:@selector(compareDates:)];
//  }
//  STAssertTrue([q count] == 15, @"queue urls count", nil);
//  ordered = [NSMutableArray array];
//  while ((obj = [q dequeue])) {
////    STAssertTrue([[obj objectAtIndex:0] paused], @"url adding paused", nil);
////    [[obj objectAtIndex:0] resume];
//    [ordered addObject:[obj objectAtIndex:0]];
//  }
//  res = waitForDeferred([DKDeferredList deferredList:ordered]);
//  STAssertTrue([res count] == 15, @"results urls count", nil);
//  NSLog(@"got again ... %@", res);
}

- (id)_gotPooledGoogleResult:(NSString *)key :(id)result {
  if (isDeferred(result))
    return [result addBoth:curryTS(self, @selector(_gotPooledGoogleResult::), key)];
  if ([result isKindOfClass:[NSError class]]) {
    NSLog(@"%@ ERROR %@", key, result);
  } else {
    NSLog(@"%@ GOT %i BYTES", key, [(NSData *)result length]);
  }
  return [[result description] substringToIndex:100];
}

- (void)testDeferredPausedPool {
  _pool = [[[DKDeferredPool alloc] init] retain];
  NSArray *dat = array_(@"bmw", @"audi", @"vespa", @"volkswagen", @"dodge", @"crysler", @"chevorlet", @"monkeys",
                        @"face", @"mazda", @"nissan", @"honda", @"rolling%20stones", @"chili%20peppers", @"more%20monkeys");
  NSMutableArray *ds = [NSMutableArray array];
  NSString *q;
  DKDeferred *d;
  for (NSString *s in dat) {
    q = [@"http://google.com/search?q=" stringByAppendingString:s];
    d = [DKDeferred loadURL:q paused:YES];
    [d addBoth:curryTS(self, @selector(_gotPooledGoogleResult::), s)];
    d.started = [NSDate dateWithTimeIntervalSinceNow:-(rand() % 100 + 1)];
    [ds addObject:d];
    [_pool add:d key:s];
  }
  id r = waitForDeferred([DKDeferredList deferredList:ds]);
  NSLog(@"got... %@", r);
}

@end
