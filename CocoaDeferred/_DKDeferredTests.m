#import "DKDeferredTests.h"

@implementation DKDeferredTest

- (id)_testCallback2:(id)result {
  NSLog(@"_testCallback2:%@", result);
  return nil;
}

- (id)_testCallback3:(id)result {
  NSLog(@"_testCallback3:%@", result);
  return nil;
}

- (id)_testCallback:(id)result {
  NSLog(@"_testCallback:%@", result);
  DKDeferred *d = [DKDeferred deferred];
  [d addCallbacks:functionTS(self, _testCallback2:) 
                 :functionTS(self, _testErrback:)];
  [d performSelector:@selector(callback:) 
          withObject:@"the second result bitch" 
          afterDelay:5.0f];
  return d;
}

- (id)_testErrback:(id)result {
  NSLog(@"_testErrback:%@", result);
  return nil;
}

- (void)testDeferred {
  DKDeferred *d = [DKDeferred deferred];
  [d addCallbacks:functionTS(self, _testCallback:)
                 :functionTS(self, _testErrback:)];
  sleep(5);
  [d callback:@"tha result bitch"];
  //[d errback:@"now error bitch"];
}

- (void)testDeferredList {
  DKDeferred *d1 = [DKDeferred deferred];
  [d1 addCallback:functionTS(self, _testCallback:)];
  [d1 addErrback:functionTS(self, _testErrback:)];
  DKDeferred *d2 = [DKDeferred deferred];
  [d2 addCallbacks:functionTS(self, _testCallback2:) 
                  :functionTS(self, _testErrback:)];
  DKDeferredList *ll = [DKDeferredList deferredList:NSARRAY(d1, d2)];
  [ll addBoth:functionTS(self, _testCallback3:)];
  sleep(2);
  [ll callback:@"hello mother chicken pluckerers!"];
}

- (id)waitCallback:(id)result {
  NSLog(@"waitCallback");
  return nil;
}

- (void)testWait {
  DKDeferred *d = [DKDeferred wait:3 value:nil];
  [d addBoth:functionTS(self, waitCallback:)];
}

- (id)callLaterFunc:(id)result {
  NSLog(@"callLaterFunc");
  return nil;
}

- (void)testCallLater {
  [DKDeferred callLater:3 func:functionTS(self, callLaterFunc:)];
}

- (id)someBlockingOperation:(id)arg {
  NSLog(@"Starting blocking op");
  //sleep([arg intValue]);
  sleep(2);
  NSLog(@"Done op");
  return @"Sonova bitch it works";
}

- (id)blockingCallback:(id)result {
  NSLog(@"blockingCallback: %@", result);
  return nil;
}

- (void)testThreadedDeferred {
  DKDeferred *d = [DKDeferred deferInThread:functionTS(self, someBlockingOperation:)  
                                 withObject:[NSNumber numberWithInt:5]];
  [d addBoth:functionTS(self, blockingCallback:)];
}

- (id)blockingListCallback:(id)result {
  NSLog(@"blockingListCallback:%@", result);
  return nil;
}

- (void)testThreadedDeferredList {
  DKDeferred *d1 = [DKDeferred deferInThread:functionTS(self, someBlockingOperation:) 
                                  withObject:[NSNumber numberWithInt:2]];
  DKDeferred *d2 = [DKDeferred deferInThread:functionTS(self, someBlockingOperation:)
                                  withObject:[NSNumber numberWithInt:3]];
  DKDeferred *ll = [DKDeferred gatherResults:NSARRAY(d1, d2)];
  [ll addBoth:functionTS(self, blockingListCallback:)];
}

- (id)deferredURLCallback:(id)result {
  NSLog(@"deferredURLCallback:%@", [NSString stringWithUTF8String:[(NSData *)result bytes]]);
  return nil;
}

- (id)deferredJSONCallback:(id)result {
  NSLog(@"deferredJSONCallback:%@", result);
  return nil;
}

- (id)deferredJSONErrback:(NSError *)result {
  NSLog(@"deferredJSONErrback:%@ %@", result, [result userInfo]);
  return nil;
}

- (void)testDeferredURL {
  DKDeferred *d = [DKDeferred loadURL:@"http://google.com/"];
  [d addBoth:functionTS(self, deferredURLCallback:)];
}

- (void)testDeferredJSON {
  DKDeferred *d = [DKDeferred loadJSONDoc:@"http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=pants"];
  [d addBoth:functionTS(self, deferredJSONCallback:)];
}

- (void)testDeferredJSONProxy {
  id service = [DKDeferred jsonService:@"http://devsam.com/json/" name:@"craigsfish"];
  DKDeferred *d = [[service registerDeviceToken] sexyTime:NSARRAY(@"sam", @"sam", @"sam")];
  [d addCallback:functionTS(self, deferredJSONCallback:)];
  [d addErrback:functionTS(self, deferredJSONErrback:)];
}

@end

//  [[[DKDeferredTest alloc] init] testDeferred];
//  [[[DKDeferredTest alloc] init] testDeferredList];
//  [[[DKDeferredTest alloc] init] testWait];
//  [[[DKDeferredTest alloc] init] testCallLater];
//  [[[DKDeferredTest alloc] init] testThreadedDeferred];
//  [[[DKDeferredTest alloc] init] testThreadedDeferredList];
//  [[[DKDeferredTest alloc] init] testDeferredURL];
//  [[[DKDeferredTest alloc] init] testDeferredJSON];
//  [[[DKDeferredTest alloc] init] testDeferredJSONProxy];