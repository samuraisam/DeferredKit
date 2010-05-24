/*
 *  DKDeferred.m
 *  DeferredKit
 *
 *  Created by Samuel Sutch on 7/25/09.
 */

#import "DKDeferred.h"
#import <CommonCrypto/CommonDigest.h>


NSString* md5(NSString *str) {
  const char *cStr = [str UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(cStr, strlen(cStr), result);
  return [NSString 
          stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
          result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
          result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

id _gatherResultsCallback(id results) {
  NSMutableArray *ret = [NSMutableArray array];
  for (int i = 0; i < [results count]; i++) {
    [ret addObject:[[results objectAtIndex:i] objectAtIndex:1]];
  }
  return ret;
}


@implementation NSObject(DKDeferredCache)

+ (BOOL)canBeStoredInCache { return [self conformsToProtocol:@protocol(NSCoding)]; }

@end


@interface DKDeferred() // private methods
- (void)_resback:(id)result;
- (void)_check;
- (id)_continueChain:(id)result;
- (void)_fire;
@end


@implementation DKDeferred

@synthesize fired, paused, results, silentlyCancelled;
@synthesize deferredID, canceller, started; // RO
@synthesize chained, finalizer; //RW

+ (DKDeferred *)deferred {
  return [[[self class] alloc] initWithCanceller:nil];
}

+ (id)succeed:(id)result {
  DKDeferred *d = [DKDeferred deferred];
  [d callback:result];
  return d;
}

+ (id)fail:(id)result {
  DKDeferred *d = [DKDeferred deferred];
  [d errback:result];
  return d;
}

// used by +wait:value:
+ (id)_returnValueCallback:(id)value results:(id)results_ {
  return value;
}

+ (id)wait:(NSTimeInterval)seconds value:(id)value {
  DKDeferred *d = [DKDeferred deferred];
  if (! (value == nil))
    [d addCallback:curryTS((id)self, @selector(_returnValueCallback:results:), value)];
  [d performSelector:@selector(callback:)
          withObject:[NSNull null] 
          afterDelay:seconds];
  return d;
}

// used by +callLater:func:
+ (id)_callLaterCallback:(id<DKCallback>)cb results:(id)results_ {
  return [cb :results_];
}

+ (id)callLater:(NSTimeInterval)seconds func:(id<DKCallback>)func {
  
  return [[DKDeferred wait:seconds value:nil]
          addCallback:
           curryTS((id)self, @selector(_callLaterCallback:results:), [func retain])];
}

+ (id)maybeDeferred:(id<DKCallback>)maybeDeferredf withObject:(id)anObject {
  id result;
  id r = [maybeDeferredf :anObject];
  if ([r isKindOfClass:[DKDeferred class]])
    result = r;
  else if ([r isKindOfClass:[NSError class]])
    result = [self fail:r];
  else
    result = [self succeed:r];
  return result;
}

+ (id)deferInThread:(id<DKCallback>)func withObject:(id)arg {
  return [[DKThreadedDeferred alloc] initWithFunction:func withObject:arg];
}

+ (id)defer:(id<DKCallback>)func withObject:(id)arg inQueue:(NSOperationQueue *)queue {
  id ret = [DKDeferredOperation operation:func withObject:arg];
  [queue addOperation:[ret operation]];
  return ret;
}

+ (id)loadURL:(NSString *)aUrl cached:(BOOL)cached {
  return [self loadURL:aUrl cached:cached paused:NO];
}

+ (id)loadURL:(NSString *)aUrl cached:(BOOL)cached paused:(BOOL)_paused {
  id ret;
  if (cached) {
    ret = [[DKDeferredCache sharedCache] valueForKey:aUrl];
    if (_paused)
      ret = pauseDeferred(ret);
    [ret addBoth:curryTS((id)self, @selector(_cachedLoadURLCallback:results:), aUrl)];
  } else {
    ret = [self loadURL:aUrl paused:_paused];
  }
  return ret;
}

+ (id)_uncachedURLLoadCallback:(NSString *)url results:(id)_results {
  if (isDeferred(_results))
    return [_results addBoth:curryTS((id)self, @selector(_uncachedURLLoadCallback:results:), url)];
  if (_results == [NSNull null]) {
    return [[DKDeferredURLConnection loadURL:url]
            addBoth:curryTS((id)self, @selector(_uncachedURLLoadCallback:results:), url)];
  } else {
    return _results;
  }
  return nil;
}

+ (id)_cachedLoadURLCallback:(NSString *)url results:(id)_results {
  if (isDeferred(_results))
    return [_results addBoth:curryTS((id)self, @selector(_cachedLoadURLCallback:results:), url)];
  
  if (_results == [NSNull null]) {
    return [[DKDeferredURLConnection loadURL:url] 
            addBoth:curryTS((id)self, @selector(_cachedLoadURLCallback:results:), url)];
  } else {
    [[DKDeferredCache sharedCache] 
     setValue:_results forKey:url
     timeout:[[DKDeferredCache sharedCache] defaultTimeout]];
    return _results;
  }
  return nil;
}

+ (id)_cbStartConnection:(id)aUrl {
  return [DKDeferredURLConnection deferredURLConnection:aUrl];
}

+ (id)loadURL:(NSString *)aUrl paused:(BOOL)_paused { 
  return [[[DKDeferredURLConnection alloc] initWithURL:aUrl paused:_paused] autorelease];
}

+ (id)loadURL:(NSString *)aUrl {
  return [self loadURL:aUrl paused:NO];
}

+ (id)gatherResults:(NSArray *)list_ {
  DKDeferredList *d = 
  [[DKDeferredList alloc]
   initWithList:list_
   withCanceller:nil
   fireOnOneCallback:NO
   fireOnOneErrback:YES
   consumeErrors:NO];
  [d addCallback:callbackP(_gatherResultsCallback)];
  return d;
} 

- (id)initWithCanceller:(id<DKCallback>)cancellerFunc {
  if ((self = [super init])) {
    chain = [[NSMutableArray arrayWithCapacity:3] retain];
    deferredID = [_uuid1() retain];
    fired = -1;
    paused = 0;
    started = [[NSDate date] retain];
    results = [[NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], nil] retain];
    silentlyCancelled = NO;
    chained = NO;
    finalized = NO;
    canceller = [cancellerFunc retain];
    finalizer = nil;
  }
  return self;
}

- (void)dealloc {
  [chain release];
  [results release];
  [finalizer release];
  [canceller release];
  [started release];
  [super dealloc];
}
  

- (NSString *)description {
  return [NSString stringWithFormat:@"<DKDeferred id=%@ state=%i>", 
          deferredID, fired];
}

- (id)pause {
  paused += 1;
  return self;
}

- (void)resume {
  if (paused >= 0)
    paused -= 1;
  if (paused)
    return;
  if (fired >= 0)
    [self _fire];
}

- (void)cancel {
  if (fired == -1) {
    if (canceller) {
      [canceller :self];
    } else {
      silentlyCancelled = YES;
    }
    if (fired == -1) {
      [self errback:
       [NSError
        errorWithDomain:DKDeferredErrorDomain
        code:DKDeferredCanceledError 
        userInfo:dict_(self, DKDeferredDeferredKey)]];
    }
  } else if ((fired == 0) && 
             ([[results objectAtIndex:fired] 
               isKindOfClass:[self class]])) {
    [[results objectAtIndex:fired] cancel];
  }
}

- (void)_resback:(id)result {
  fired = ([result isKindOfClass:[NSError class]] ? 1 : 0);
  [results replaceObjectAtIndex:fired withObject:
   (result == nil ? [NSNull null] : result)];
  if (paused == 0) {
//    started = [[NSDate date] retain];
    [self _fire];
  }
}

- (void)_check {
  if (fired != -1) {
    if (!silentlyCancelled) {
      @throw [NSException 
              exceptionWithName:@"AlreadyCalledError"
              reason:@"Callback or errback can only happen if "
                     @"Deferred has not already fired." 
              userInfo:dict_(self, DKDeferredDeferredKey)];
    }
    silentlyCancelled = NO;
  }
}

- (void)callback:(id)result {
  [self _check];
  if ([result isKindOfClass:[self class]])
    @throw __CHAINED_DEFERRED_RESULT_ERROR;
  [self _resback:result];
}

- (void)errback:(id)result {
  [self _check];
  if ([result isKindOfClass:[self class]])
    @throw __CHAINED_DEFERRED_RESULT_ERROR;
  if (![result isKindOfClass:[NSError class]])
    result = [NSError 
              errorWithDomain:DKDeferredErrorDomain
              code:DKDeferredGenericError
              userInfo:dict_(self, DKDeferredResultKey)];
  [self _resback:result];
}

- (id)addBoth:(id<DKCallback>)fn {
  return [self addCallbacks:fn :fn];
}

- (id)addCallback:(id<DKCallback>)fn {
  return [self addCallbacks:fn :nil];
}

- (id)addErrback:(id<DKCallback>)fn {
  return [self addCallbacks:nil :fn];
}

- (id)addCallbacks:(id<DKCallback>)cb :(id<DKCallback>)eb {
  if (chained)
    @throw __CHAINED_DEFERRED_REUSE_ERROR;
  if (finalized)
    @throw __FINALIZED_DEFERRED_REUSE_ERROR;
  [chain addObject:array_(
    (cb == nil) ? [NSNull null] : (id)cb,
    (eb == nil) ? [NSNull null] : (id)eb)];
  if (fired >= 0)
    [self _fire];
  return self;
}

- (void)setFinalizer:(id<DKCallback>)fn {
  if (chained)
    @throw __CHAINED_DEFERRED_REUSE_ERROR;
  if (finalized)
    @throw __FINALIZED_DEFERRED_REUSE_ERROR;
  finalizer = [fn retain];
  if (fired >= 0)
    [self _fire];
}

- (id)_continueChain:(id)result {
  paused -= 1;
  [self _resback:result];
  return nil;
}

- (void)_fire {
  id<DKCallback> cb = nil;
  int _fired = fired;
  id result = [[[results objectAtIndex:_fired] retain] autorelease];
  while ([chain count] > 0 && paused == 0) {
    NSArray *pair = [[[chain objectAtIndex:0] retain] autorelease];
    [chain removeObjectAtIndex:0];
    id f = [[[pair objectAtIndex:_fired] retain] autorelease];
    if (f == [NSNull null])
      continue;
    id newResult = [(id<DKCallback>)f :result];
    result = (newResult == nil) ? [NSNull null] : newResult;
    _fired = [result isKindOfClass:[NSError class]] ? 1 : 0;
    if ([result isKindOfClass:[self class]]) {
      cb = callbackTS(self, _continueChain:);
      paused += 1;
    }
  }
  fired = _fired;
  [results replaceObjectAtIndex:fired withObject:result];
  if ([chain count] == 0 && paused == 0 && !(finalizer == nil)) {
    finalized = YES;
    [finalizer :result];
  }
  if (! (cb == nil) && paused) {
    [result addBoth:cb];
    [result setChained:YES];
  }
}

- (NSComparisonResult)compare:(DKDeferred *)otherDeferred {
  return [self.deferredID compare:otherDeferred.deferredID];
}

- (NSComparisonResult)compareDates:(DKDeferred *)otherDeferred {
  return -[self.started compare:otherDeferred.started];
}

- (NSComparisonResult)reverseCompareDates:(DKDeferred *)otherDeferred {
  return [self.started compare:otherDeferred.started];
}

@end


@implementation DKDeferredList

@synthesize fireOnOneCallback, fireOnOneErrback, consumeErrors, finishedCount;

+ (id)deferredList:(NSArray *)list_ {
  return [[[self class] alloc] 
          initWithList:list_
          withCanceller:nil
          fireOnOneCallback:NO 
          fireOnOneErrback:NO
          consumeErrors:NO];
}

+ (id)deferredList:(NSArray *)list_ withCanceller:(id<DKCallback>)cancelf {
  return [[[self class] alloc]
          initWithList:list_
          withCanceller:cancelf
          fireOnOneCallback:NO
          fireOnOneErrback:NO
          consumeErrors:NO];
}

- (id)initWithList:(NSArray *)list_
     withCanceller:(id<DKCallback>)cancelf
 fireOnOneCallback:(BOOL)fireoc
  fireOnOneErrback:(BOOL)fireoe
     consumeErrors:(BOOL)consume {
  if ((self = [super initWithCanceller:cancelf])) {
    list = [list_ retain];
    resultList = [[NSMutableArray array] retain];
    finishedCount = 0;
    self.fireOnOneCallback = fireoc;
    self.fireOnOneErrback = fireoe;
    self.consumeErrors = consume;
    
    for (int i = 0; i < [list count]; i++) {
      DKDeferred *d = [list objectAtIndex:i];
      [resultList addObject:[NSNull null]];
      NSNumber *I = [NSNumber numberWithInt:i];
      NSNumber *Y = [NSNumber numberWithInt:YES];
      NSNumber *N = [NSNumber numberWithInt:NO];
      [d addCallback:curryTS(self, @selector(_cbDeferred:succeeded:result:), I, Y)];
      [d addErrback:curryTS(self, @selector(_cbDeferred:succeeded:result:), I, N)];
    }
    
    if ([list count] == 0 && !fireOnOneCallback)
      [self callback:resultList];
  }
  
  return self;
}

- (void)dealloc {
  [list release];
  [resultList release];
  [super dealloc];
}

- (id)_cbDeferred:(id)index succeeded:(id)succeeded result:(id)result {
  if (isDeferred(result)) {
    return [result addBoth:curryTS(self, 
      @selector(_cbDeferred:succeeded:result:), index, succeeded)];
  }
  int _index = [(NSNumber *)index intValue];
  BOOL _succeeded = [(NSNumber *)succeeded boolValue];
  result = (result == nil) ? [NSNull null] : result;
  [resultList 
   replaceObjectAtIndex:_index 
   withObject:array_(succeeded, result)];
  finishedCount += 1;
  if (fired == -1) {
    if (_succeeded && fireOnOneCallback)
      [self callback:array_(index, result)];
    else if (!_succeeded && fireOnOneErrback)
      [self errback:result];
    else if (finishedCount == [list count])
      [self callback:[NSArray arrayWithArray:resultList]];
  }
  if (!_succeeded && consumeErrors)
    result = nil;
  return result;
}

@end


@implementation DKWaitForDeferred

@synthesize result, d;

- (id)initWithDeferred:(DKDeferred *)deferred {
  if ((self = [super init])) {
    d = [[deferred addBoth:callbackTS(self, _get:)] retain];
  }
  return self;
}

- (id)result {
  if (!result) {
    running = YES;
  }
  while (running) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
  }
  return result;
}

- (id)_get:(id)_result {
  if (isDeferred(_result)) {
    [d release];
    d = [[_result addBoth:callbackTS(self, _get:)] retain];
    return d;
  }
  running = NO;
  self.result = _result;
  return _result;
}

- (void)dealloc {
  [d release];
  [result release];
  [super dealloc];
}

@end


@implementation DKDeferredWrapper

- (id)initWithDeferred:(DKDeferred *)deferredToPause {
  if ((self = [super initWithCanceller:nil])) {
    d = [deferredToPause retain];
    [self addCallback:callbackTS(self, _cbStart:)];
  }
  return self;
}

- (id)_cbStart:(id)result {
  return [d autorelease];
}

- (void)dealloc {
  [d release];
  [super dealloc];
}

@end


@implementation DKThreadedDeferred

@synthesize thread, parentThread, action;

+ (DKThreadedDeferred *)threadedDeferred:(id<DKCallback>)func {
  return [[[self alloc] initWithFunction:func withObject:nil] autorelease];
}

+ (DKThreadedDeferred *)threadedDeferred:(id<DKCallback>)func paused:(BOOL)_paused {
  return [[[self alloc] initWithFunction:func withObject:nil canceller:nil paused:_paused] autorelease];
}

- (id)initWithFunction:(id<DKCallback>)func
            withObject:(id)arg {
  return [self initWithFunction:func withObject:arg canceller:nil paused:NO];
}

- (id)initWithFunction:(id<DKCallback>)func 
            withObject:(id)arg
             canceller:(id<DKCallback>)cancelf
                paused:(BOOL)_paused {
  if ((self = [super initWithCanceller:cancelf])) {
    action = [func retain];
    thread = [[[NSThread alloc] 
               initWithTarget:self
               selector:@selector(_cbThreadedDeferred:)
               object:arg] retain];
    parentThread = [[NSThread currentThread] retain];
    if (!_paused) {
      [thread start];
    } else {
      return [[DKDeferred deferred] addCallback:callbackTS(self, _cbStartThread:)];
    }
  }
  return self;
}

- (id)_cbStartThread:(id)arg {
  [thread start];
  return self;
}

- (void)dealloc {
  [action release];
  [thread release];
  [parentThread release];
  [super dealloc];
}

- (void)_cbThreadedDeferred:(id)arg {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  id result;
  result = [action :arg];
  if (!result)
    result = [NSNull null];
  [self performSelector:@selector(_cbReturnFromThread:) 
               onThread:parentThread
             withObject:result
          waitUntilDone:NO];
  [pool drain];
}

- (void)_cbReturnFromThread:(id)result {
  if ([result isKindOfClass:[NSError class]])
    [self errback:result];
  else if ([result isKindOfClass:[DKDeferred class]])
    @throw __CHAINED_DEFERRED_RESULT_ERROR;
  else
    [self callback:result];
}

@end


@implementation DKDeferredOperation

@synthesize operation = op;

+ (DKDeferredOperation *)operation:(id<DKCallback>)func withObject:(id)_arg {
  return [[[self alloc] initWithFunction:func withObject:_arg canceller:nil paused:NO] autorelease];
}

+ (DKDeferredOperation *)pausedOperation:(id<DKCallback>)func withObject:(id)_arg {
  return [[[self alloc] initWithFunction:func withObject:_arg canceller:nil paused:YES] autorelease];
}

- (id)initWithFunction:(id<DKCallback>)func 
            withObject:(id)_arg
             canceller:(id<DKCallback>)cancelf
                paused:(BOOL)startPaused {
  if ((self = [super initWithCanceller:cancelf])) {
    action = [func retain];
    parentThread = [[NSThread currentThread] retain];
    op = [[[NSInvocationOperation alloc] 
          initWithTarget:self
          selector:@selector(_cbOperation:)
           object:_arg] retain];
  }
  return self;
}

- (id)_cbStartOperation:(id)_arg {
  [op start];
  return self;
}

- (void)_cbOperation:(id)_arg {
  id result = [[[action :_arg] retain] autorelease];
  [self performSelector:@selector(_cbReturnFromOp:)
               onThread:parentThread
             withObject:result
          waitUntilDone:NO];
}

- (void)_cbReturnFromOp:(id)result {
  if ([result isKindOfClass:[NSError class]])
    [self errback:result];
  else if ([result isKindOfClass:[DKDeferred class]])
    @throw __CHAINED_DEFERRED_RESULT_ERROR;
  else
    [self callback:result];
}

- (void)dealloc {
  [action release];
  [parentThread release];
  [op release];
  [super dealloc];
}

@end


@implementation DKDeferredURLConnection

static NSInteger __urlConnectionCount;

@synthesize url, refreshFrequency, progressCallback;
@synthesize expectedContentLength, percentComplete;

+ (id)deferredURLConnection:(NSString *)aUrl {
  return [[(DKDeferredURLConnection *)[DKDeferredURLConnection alloc] initWithURL:aUrl] autorelease];
}

+ (id)pausedDeferredURLConnection:(NSString *)aUrl {
  return [[(DKDeferredURLConnection *)[DKDeferredURLConnection alloc] initWithURL:aUrl paused:YES] autorelease];
}

- (id)initWithURL:(NSString *)aUrl {
  return [self initWithURL:aUrl pauseFor:0.0f];
}

- (id)initWithURL:(NSString *)aUrl paused:(BOOL)_paused {
  return [self initRequest:
            [NSURLRequest requestWithURL:[NSURL URLWithString:aUrl]
                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                         timeoutInterval:15.0f]
            decodeFunction:nil paused:_paused];
}

- (id)initWithURL:(NSString *)aUrl pauseFor:(NSTimeInterval)pause {
  return [self initWithRequest:
          [NSURLRequest requestWithURL:[NSURL URLWithString:aUrl]
                           cachePolicy:NSURLRequestReloadIgnoringCacheData 
                       timeoutInterval:15.0f]
                      pauseFor:0.0f
                decodeFunction:nil];
}

- (id)initRequest:(NSURLRequest *)req 
   decodeFunction:(id<DKCallback>)decodeF
           paused:(BOOL)_paused {
  if ((self = [super initWithCanceller:nil])) {
    if (!__urlConnectionCount) {
      __urlConnectionCount = 0;
    }
    refreshFrequency = 1.0f;
    expectedContentLength = 0L;
    percentComplete = 0.0f;
    progressCallback = nil;
    url = [[req URL] retain];
    _data = [[NSMutableData data] retain];
    [_data setLength:0];
    request = [req retain];
    decodeFunction = [decodeF retain];
    if (_paused) {
      return [[DKDeferred deferred] addCallback:callbackTS(self, _cbStartLoading:)];
    } else {
      [self _cbStartLoading:nil];
    }
  }
  return self;
}

- (id)initWithRequest:(NSURLRequest *)req pauseFor:(NSTimeInterval)pause
       decodeFunction:(id<DKCallback>)decodeF {
  if ((self = [super initWithCanceller:nil])) {
    // init __urlConnetionCount
    if (!__urlConnectionCount) {
      __urlConnectionCount = 0;
    }
    refreshFrequency = 1.0f;
    expectedContentLength = 0L;
    percentComplete = 0.0f;
    progressCallback = nil;
    url = [[req URL] retain];
    _data = [[NSMutableData data] retain];
    [_data setLength:0];
    request = [req retain];
    decodeFunction = [decodeF retain];
    if (pause > 0) {
      [DKDeferred callLater:pause func:callbackTS(self, _cbStartLoading:)];
    } else {
      connection = [[NSURLConnection 
                     connectionWithRequest:request
                     delegate:self] retain];
      __urlConnectionCount += 1;
      NSLog(@"loading %@ : %@", self.started, url);
      if (!connection) {
        __urlConnectionCount -= 1;
        NSLog(@"error:???");
        [self errback:
         [NSError
          errorWithDomain:DKDeferredURLErrorDomain 
          code:DKDeferredURLError 
          userInfo:EMPTY_DICT]];
      }
    }
  }
  return self;
}

- (void)setProgressCallback:(id<DKCallback>)callback {
  if (progressCallback) {
    [progressCallback release];
    progressCallback = nil;
  }
  progressCallback = [callback retain];
}

- (void)setProgressCallback:(id<DKCallback>)callback 
              withFrequency:(NSTimeInterval)frequency {
  refreshFrequency = frequency;
  if (progressCallback) {
    [progressCallback release];
    progressCallback = nil;
  }
  progressCallback = [callback retain];
}

- (void)connection:(NSURLConnection *)aConnection 
didReceiveResponse:(NSURLResponse *)response {
  expectedContentLength = [response expectedContentLength];
//  NSLog(@" - didreceiveresponse - %@", [(NSHTTPURLResponse *)response allHeaderFields]);
  percentComplete = 0.0f;
  [_data setLength:0];
  [self _cbProgressUpdate];
}

- (void)connection:(NSURLConnection *)aConnection 
    didReceiveData:(NSData *)data {
  [_data appendData:data];
  [self _cbProgressUpdate];
}

- (void)connection:(NSURLConnection *)aConnection
  didFailWithError:(NSError *)error {
  if (aConnection == connection) connection = nil;
  [aConnection release];
  NSLog(@"didFailWithError:%@", error);
  [self _cbProgressUpdate];
  if (self.fired == -1) { // could be multiple errors, only errback on the first
    [self errback:error];
    __urlConnectionCount -= 1;
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
  id ret = nil;
  if (! (decodeFunction == nil)) {
    ret = [decodeFunction :_data];
  }
  if (progressCallback)
    [self _cbProgressUpdate];
  __urlConnectionCount -= 1;
  [self callback:(ret == nil) ? [NSData dataWithData:_data] : ret];
//  [aConnection release];
}

- (void)_cbProgressUpdate {
  percentComplete = (double)[_data length] / (double)expectedContentLength;
//  NSLog(@"_data:%i expectedContentLength:%i", [_data length], expectedContentLength);
//  NSLog(@"percentComplete:%d", percentComplete);
  if (progressCallback) {
    [progressCallback :[NSNumber numberWithDouble:percentComplete]];
  }
}

+ (int)requestCount {
  return __urlConnectionCount;
}

- (void)dealloc {
  if (connection) [connection release];
  [request release];
  [progressCallback release];
  [url release];
  [_data release];
  [super dealloc];
}

- (NSData *)data {
  return [NSData dataWithData:_data];
}

- (id)_cbStartLoading:(id)result {
  NSLog(@"connection: %@ : %@", self.started, url);
  connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
  if (connection) {
    __urlConnectionCount += 1;
  } else {
    NSLog(@"nsurlconnection error: connection could not be initialized");
    [self errback:[NSError
      errorWithDomain:DKDeferredURLErrorDomain 
      code:DKDeferredURLError userInfo:EMPTY_DICT]];
  }
  return self;
}

@end


///
/// The shared cache object
/// 
static DKDeferredCache *__sharedCache;

@implementation DKDeferredCache

@synthesize defaultTimeout;

/// DKCache Protocol
- (id)setValue:(NSObject *)value forKey:(NSString *)key timeout:(NSTimeInterval)timeout {
  return [DKDeferred defer:
          curryTS(self,
                  @selector(_setValue:forKey:timeout:arg:),
                  value, key, nsni((int)timeout))
                withObject:[NSNull null] 
                   inQueue:operationQueue];
}

- (id)valueForKey:(NSString *)key {
  return [DKDeferred defer:callbackTS(self, _getValue:) 
                withObject:key
                   inQueue:operationQueue];
}

- (void)deleteValueForKey:(NSString *)key { // TODO: Make asynchronous
  [[NSFileManager defaultManager] 
   removeItemAtPath:[dir stringByAppendingPathComponent:md5(key)] 
   error:nil];
}

- (id)getManyValues:(NSArray *)keys {
  return [DKDeferred defer:callbackTS(self, _getManyValues:) 
                withObject:keys
                   inQueue:operationQueue];
}

- (BOOL)hasKey:(NSString *)key {
  return [[NSFileManager defaultManager] 
          fileExistsAtPath:[dir stringByAppendingPathComponent:md5(key)]];
}

// TODO: convert to use NSUserDefaults....
- (id)incr:(NSString *)key delta:(int)delta { // synchronous
  NSNumber *val = nil;
  if (![self hasKey:key] || !(val = [self _getValue:key])) {
    return [NSError errorWithDomain:DKDeferredErrorDomain 
                               code:9903 userInfo:EMPTY_DICT];
  }
  NSNumber *newVal = [NSNumber numberWithInt:[val intValue] + delta];
  [self _setValue:newVal forKey:key timeout:[NSNumber numberWithInt:0] arg:nil];
  return newVal;
}

// TODO: convert to use NSUserDefaults....
- (id)decr:(NSString *)key delta:(int)delta { // synchronous
  return [self incr:key delta:-delta];
}

// should always be executed in a thread
- (id)_getManyValues:(NSArray *)keys {
  NSMutableArray *ret = [NSMutableArray arrayWithCapacity:[keys count]];
  NSObject *val = nil;
  for (NSString *key in keys) {
    val = [self _getValue:key];
    [ret addObject:((val == nil) ? [NSNull null] : val)];
  }
  return [NSDictionary dictionaryWithObjects:ret forKeys:keys];
}

// should always be executed in a thread
- (id)_getValue:(NSString *)key { 
  NSString *fname = [dir stringByAppendingPathComponent:md5(key)];
  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:fname]) {
    NSArray *content = [NSKeyedUnarchiver unarchiveObjectWithFile:fname];
    NSDate *expires = (NSDate *)[content objectAtIndex:0];
    if (([expires compare:[NSDate date]] == NSOrderedAscending)) {
      [fm removeItemAtPath:fname error:nil];
      return nil;
    } else {
      return [content objectAtIndex:1];
    }
  }
  return nil;
}

// should always be executed in a thread
- (id)_setValue:(NSObject *)value forKey:(NSString *)key 
        timeout:(NSNumber *)timeout arg:(id)arg {
  if (![[value class] canBeStoredInCache]) {
    return nil;
  }
  NSString *fname = [dir stringByAppendingPathComponent:md5(key)];
  [self _cull];
  NSArray *content = array_([NSDate dateWithTimeIntervalSinceNow:[timeout intValue]], value);
  [NSKeyedArchiver archiveRootObject:content toFile:fname];
  return nil;
}

+ (id)sharedCache {
  if (!__sharedCache) {
    __sharedCache = [[DKDeferredCache alloc] 
                     initWithDirectory:@"_dksc"
                     maxEntries:300
                     cullFrequency:3];
  }
  return __sharedCache;
}

- (id)initWithDirectory:(NSString *)_dir 
             maxEntries:(int)_maxEntries
          cullFrequency:(int)_cullFrequency {
  if ((self = [super init])) {
    maxEntries = (_maxEntries < 1) ? 300 : _maxEntries;
    cullFrequency = (_cullFrequency < 1) ? 3 : _cullFrequency;
    operationQueue = [[NSOperationQueue alloc] init];
    self.defaultTimeout = 7200.0;
    // init cache directory
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDirectory, YES);
    NSString *cachesPath = [paths objectAtIndex:0];
    dir = [[cachesPath stringByAppendingPathComponent:_dir] retain];
    if (![fm fileExistsAtPath:cachesPath]) {
      [fm createDirectoryAtPath:cachesPath attributes:nil];
    }
    if (![fm fileExistsAtPath:dir]) {
      [fm createDirectoryAtPath:dir attributes:nil];
    }
  }
  return self;
}

- (void)dealloc {
  [operationQueue release];
  [dir release];
  [super dealloc];
}

- (void)_cull {
  if ([self _getNumEntries] > maxEntries) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *fileList = [fm directoryContentsAtPath:dir];
    NSMutableArray *doomed = [NSMutableArray array];
    int count = 0;
    for (NSString *path in fileList) {
      if ((count % cullFrequency) == 0) {
        [doomed addObject:path];
      }
      count += 1;
    }
    for (NSString *dead in doomed) {
      [fm removeItemAtPath:[dir stringByAppendingPathComponent:dead] error:nil];
//      NSLog(@"##DKCache removeItem: %@", dead);
    }
  }
}

- (int)_getNumEntries {
  NSArray *fileNames = [[NSFileManager defaultManager]
                        directoryContentsAtPath:dir];
  if (!fileNames)
    return 0;
  return [fileNames count];
}

@end


@implementation DKMappedPriorityQueue

- (id)init {
  if ((self = [super init])) {
    _queueKeys = [[NSMutableDictionary alloc] init];
    _queue = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_queueKeys release];
  [_queue release];
  [super dealloc];
}

- (id)objForKey:(id)key {
  return [[_queueKeys objectForKey:key]
          objectAtIndex:1];
}

- (SEL)selForKey:(id)key {
  SEL ret;
  id obj =[[_queueKeys objectForKey:key] objectAtIndex:0];
  if (obj) {
    [obj getValue:&ret];
    return ret;
  }
  return nil;
}

- (int)count {
  return [_queue count];
}

- (id)enqueue:(id)obj key:(id)key {
  return [self enqueue:obj key:key prioritySelector:nil];
}

- (id)enqueue:(id)obj key:(id)key prioritySelector:(SEL)prioritySel {
  if (prioritySel == nil) {
    prioritySel = @selector(compare:);
  }
  NSArray *existing = [_queueKeys objectForKey:key];
  if (existing && [existing count]) {
    return nil;
  }
  [_queue addObject:key];
  [_queueKeys setObject:
   array_([NSValue valueWithBytes:&prioritySel objCType:@encode(SEL)], obj)
                 forKey:key];
  [self _siftDown:0 :[_queue count] - 1];
  return obj;
}

- (id)dequeue {
  id key;
  id keyE;
  id obj;
  int size = [_queue count];
  if (!size) {
    return nil;
  }
  keyE = [[[_queue objectAtIndex:(size - 1)] retain] autorelease];
  [_queue removeLastObject];
  if ([_queue count]) {
    key = [[[_queue objectAtIndex:0] retain] autorelease];
    [_queue replaceObjectAtIndex:0 withObject:keyE];
    [self _siftUp:0];
  } else {
    key = keyE;
  }
  obj = [[[self objForKey:key] retain] autorelease];
  [_queueKeys removeObjectForKey:key];
  return array_(obj, key);
}

- (id)peek {
  if (![_queue count]) {
    return nil;
  }
  return [_queue objectAtIndex:0];
}

- (NSArray *)allValues {
  NSMutableArray *ret = [NSMutableArray array];
  for (id k in _queue) {
    [ret addObject:[self objForKey:k]];
  }
  return ret;
}

- (NSArray *)allKeys {
  return [NSArray arrayWithArray:_queue];
}

- (NSComparisonResult)compareKeys:(id)leftKey :(id)rightKey {
  return ((NSComparisonResult)
    [[self objForKey:leftKey]
      performSelector:[self selForKey:leftKey]
      withObject:[self objForKey:rightKey]]);
}

- (void)_siftDown:(int)startPos :(int)pos {
  int parentPos;
  id parent;
  id newItem = [_queue objectAtIndex:pos];
  while (pos > startPos) {
    parentPos = (pos - 1) >> 1;
    parent = [_queue objectAtIndex:parentPos];
    if ([self compareKeys:newItem :parent] == NSOrderedAscending) {
      [_queue replaceObjectAtIndex:pos withObject:parent];
      pos = parentPos;
      continue;
    }
    break;
  }
  [_queue replaceObjectAtIndex:pos withObject:newItem];
}

- (void)_siftUp:(int)pos {
  int rightPos;
  int endPos = [_queue count];
  int startPos = pos;
  id newItem = [_queue objectAtIndex:pos];
  int childPos = 2 * pos + 1;
  while (childPos < endPos) {
    rightPos = childPos + 1;
    if (rightPos < endPos && 
        !([self compareKeys:[_queue objectAtIndex:childPos] 
                           :[_queue objectAtIndex:rightPos]] 
          == NSOrderedAscending)) {
      childPos = rightPos;
    }
    [_queue replaceObjectAtIndex:pos withObject:[_queue objectAtIndex:childPos]];
    pos = childPos;
    childPos = 2 * pos + 1;
  }
  [_queue replaceObjectAtIndex:pos withObject:newItem];
  [self _siftDown:startPos :pos];
}

@end


@implementation DKDeferredPool

+ (id)pool {
  return [[[self class] init] autorelease];
}

- (id)init {
  if ((self = [super init])) {
    _queue = [[[DKMappedPriorityQueue alloc] init] retain];
    _runningDeferreds = [[[NSMutableDictionary alloc] init] retain];
    concurrency = 4;
    timeout = 10.0;
    wLock = [[[NSLock alloc] init] retain];
    comparisonSelector = @selector(compareDates:);
  }
  return self;
}

- (SEL)comparisonSelector {
  SEL ret;
  @synchronized(self) {
    ret = comparisonSelector;
  }
  return ret;
}

- (void)setComparisonSelector:(SEL)selecter {
  @synchronized(self) {
    comparisonSelector = selecter;
  }
}

- (void)setFinalizeFunc:(id<DKCallback>)f {
  finalizeFunc = [f retain];
}

- (void)_checkFinalization {
  if (finalizeFunc && ![_queue count] && ![_runningDeferreds count]) {
    [finalizeFunc :self];
  }
}

- (id)add:(DKDeferred *)d key:(id)k {
  id ret;
  [wLock lock];
  ret = [_queue enqueue:d key:k prioritySelector:comparisonSelector];
  [wLock unlock];
  if (ret) {
    [d addBoth:curryTS(self, @selector(_cbRemoveDeferred::), k)];
  } else {
    ret = d;
    [ret cancel];
  }
  [self _resumeWaiting];
  return ret;
}

/**
 * interesting TODO:
 * this could function as a cooperative scheduler
 * for chained deferreds. Each link is paused and scheduled
 * then resumed when dequeued.
 */
- (id)_cbRemoveDeferred:(id)key :(id)results {
  if (isDeferred(results)) {
    [wLock lock];
    [_runningDeferreds setObject:results forKey:key];
    [wLock unlock];
    return [results addBoth:curryTS(self, @selector(_cbRemoveDeferred::), key)];
  }
  [wLock lock];
  [_runningDeferreds removeObjectForKey:key];
  [wLock unlock];
  [self _resumeWaiting];
  return results;
}

- (void)_resumeWaiting {
  NSArray *item;
  NSMutableArray *resumables = [NSMutableArray array];
  [wLock lock];
  while ([_runningDeferreds count] < concurrency) {
    item = [_queue dequeue];
    if (!item || ![item count]) {
      break;
    }
//    NSLog(@"resumeWaiting: %@ %@", [item objectAtIndex:0], [item objectAtIndex:1]);
    [[item retain] autorelease];
    [resumables addObject:item];
    [_runningDeferreds setObject:[item objectAtIndex:0]
                          forKey:[item objectAtIndex:1]];
  }
  [self _checkFinalization];
  [wLock unlock]; // a callback can return in the same thread and invoke _resumeWaiting here
  for (item in resumables) {
    [[item objectAtIndex:0] callback:nil];
  }
}

- (void)drain {
  [[_runningDeferreds allValues] makeObjectsPerformSelector:@selector(cancel)];
  id obj;
  while ((obj = [_queue dequeue])) {
    if ([obj count]) {
      [[obj objectAtIndex:0] cancel];
    }
  }
}

- (void)setConcurrency:(int)numConcurrentDeferreds {
  @synchronized(self) {
    concurrency = numConcurrentDeferreds;
  }
}

- (int)concurrency {
  int c;
  @synchronized(self) {
    c = concurrency;
  }
  return c;
}

- (void)setTimeout:(double)concurrentDeferredTimeout {
  @synchronized(self) {
    timeout = concurrentDeferredTimeout;
  }
}

- (double)timeout {
  int t;
  @synchronized(self) {
    t = timeout;
  }
  return t;
}

- (void)dealloc {
  [finalizeFunc release];
  [wLock release];
  [_runningDeferreds release];
  [_queue release];
  [super dealloc];
}

@end
