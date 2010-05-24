/*
 *  DKDeferred.h
 *  DeferredKit
 *
 *  Created by Samuel Sutch on 7/25/09.
 */

#import <Foundation/Foundation.h>
#import "DKCallback.h"
#import "DKMacros.h"


#define DKDeferredErrorDomain @"DKDeferred"
#define DKDeferredURLErrorDomain @"DKDeferredURLConnection"
#define DKDeferredCanceledError 419
#define DKDeferredGenericError 420
#define DKDeferredURLError 421
#define DKDeferredPoolTimeout 422
#define DKDeferredDeferredKey @"deferred"
#define DKDeferredResultKey @"result"
#define DKDeferredExceptionKey @"exception"

#define __CHAINED_DEFERRED_REUSE_ERROR [NSException \
  exceptionWithName:@"DeferredInstanceError" \
  reason:@"Chained deferreds can not be re-used" \
  userInfo:dict_(self, DKDeferredDeferredKey)]
#define __FINALIZED_DEFERRED_REUSE_ERROR [NSException \
  exceptionWithName:@"DeferredInstanceError" \
  reason:@"Finalized deferreds can not be re-used" \
  userInfo:dict_(self, DKDeferredDeferredKey)]
#define __CHAINED_DEFERRED_RESULT_ERROR [NSException \
  exceptionWithName:@"DeferredInstanceError" \
  reason:@"Deferred instances can only be chained " \
         @"if they are the result of a callback" \
  userInfo:dict_(self, DKDeferredDeferredKey)]

/**
  * DKDeferred
  * 
  * A class to encapsulate a sequence of callbacks
  * in response to an object that may not yet be available.
  * In addition to responding to a callback a deferred also
  * keeps track of it's internal status:
  * <pre>
  * -1 = not fired
  * 0  = success
  * 1  = error
  * </pre>
  * It's design is greatly adopted from Twisted's Deferred class
  * and the library inspired by MochiKit's implementation of Deferred.
  * Usage of this library requires DKDeferred be built with [json-framework][1].
  * 
  * Primary Use
  * <pre>
  * -(void)userTouchedGo:(id)sender {
  *     DKDeferred *d = [DKDeferred loadURL:@"http://google.com/"];
  *     [d addCallback:callbackTS(self, googleDidLoad:);
  *     [d addErrback:callbackTS(self, googleFailedToLoad:);
  * }
  *
  * -(id)googleDidLoad:(id)result { // in this case, an NSData object
  *     [loadingView removeFromSuperview];
  *     [webView loadHTMLString:[NSString stringWithUTF8String:[result bytes]]
  *                     baseURL:[NSURL URLWithString:@"google.com"]];
  *     [view addSubview:webView];
  *     return nil;
  * }
  * 
  * -(id)googleFailedToLoad:(NSError *)result {
  *     // tell the user the internet is down.
  *     return nil;
  * }
  * </pre>   
  *
  * DKDeferred, much like the NSDate class is an aggregate class. Many of the public
  * constructors you use through this class will return classes that inherit from
  * DKDeferred. Initializers may sometimes return objects that do not directly represent
  * the object you're initializing (for instance, some paused deferreds). Therefore
  * it is crucial when typing your deferred symbols it is best to use <code>id</code> or
  * <code>DKDeferred*</code> like so:
  * <pre>
  * DKDeferred *d = [DKDeferred deferInThread:callbackP(_run) withObject:self];
  * --or--
  * id d = [DKDeferred deferInThread:callbackP(_run) withObject:self];
  * </pre>
  */

@interface DKDeferred : NSObject {
  NSMutableArray *chain;
  NSString *deferredID;
  int fired;
  int paused;
  NSMutableArray *results;
  id<DKCallback> canceller;
  BOOL silentlyCancelled;
  BOOL chained;
  BOOL finalized;
  id<DKCallback> finalizer;
  NSDate *started;
}

@property(readonly) int fired;
@property(readonly) int paused;
@property(readonly) NSArray *results;
@property(readonly) BOOL silentlyCancelled;
@property(readwrite) BOOL chained;
@property(readonly) id<DKCallback> canceller;
@property(readonly) NSString *deferredID;
@property(readwrite, retain) id<DKCallback> finalizer;
@property(readwrite, retain) NSDate *started;

// initializers
+ (DKDeferred *)deferred;
- (id)initWithCanceller:(id<DKCallback>)cancellerFunc;
// utility
+ (id)maybeDeferred:(id<DKCallback>)maybeDeferredf withObject:(id)anObject;
+ (id)gatherResults:(NSArray *)list_;
+ (id)succeed:(id)result;
+ (id)fail:(id)result;
+ (id)wait:(NSTimeInterval)seconds value:(id)value;
+ (id)callLater:(NSTimeInterval)seconds func:(id<DKCallback>)func;
+ (id)deferInThread:(id<DKCallback>)func withObject:(id)arg;
+ (id)defer:(id<DKCallback>)func withObject:(id)arg inQueue:(NSOperationQueue *)queue;
+ (id)loadURL:(NSString *)aUrl;
+ (id)loadURL:(NSString *)aUrl paused:(BOOL)_paused;
+ (id)loadURL:(NSString *)aUrl cached:(BOOL)cached;
+ (id)loadURL:(NSString *)aUrl cached:(BOOL)cached paused:(BOOL)_paused;
// callback methods
- (id)addBoth:(id<DKCallback>)fn;
- (id)addCallback:(id<DKCallback>)fn;
- (id)addErrback:(id<DKCallback>)fn;
- (id)addCallbacks:(id<DKCallback>)cb :(id<DKCallback>)eb;
// control methods
- (id)pause;
- (void)resume;
- (void)cancel;
- (void)callback:(id)result;
- (void)errback:(id)result;
// comparison
- (NSComparisonResult)compare:(DKDeferred *)otherDeferred;
- (NSComparisonResult)compareDates:(DKDeferred *)otherDeferred;
- (NSComparisonResult)reverseCompareDates:(DKDeferred *)otherDeferred;

@end


/**
  * DKDeferredList
  * 
  * Wraps a series of deferreds into one deferred. Can be made
  * to callback on first result (the fireOnOneCallback/fireOnOneErrback) args
  */
@interface DKDeferredList : DKDeferred {
  NSArray *list;
  NSMutableArray *resultList;
  int finishedCount;
  BOOL fireOnOneCallback;
  BOOL fireOnOneErrback;
  BOOL consumeErrors;
}

@property(readwrite, assign) BOOL fireOnOneCallback;
@property(readwrite, assign) BOOL fireOnOneErrback;
@property(readwrite, assign) BOOL consumeErrors;
@property(readonly) int finishedCount;

// initializers
+ (id)deferredList:(NSArray *)list_;
+ (id)deferredList:(NSArray *)list_ withCanceller:(id<DKCallback>)cancelf;
- (id)initWithList:(NSArray *)list_
     withCanceller:(id<DKCallback>)cancelf
 fireOnOneCallback:(BOOL)fireoc
  fireOnOneErrback:(BOOL)fireoe
     consumeErrors:(BOOL)consume;
// internal callback used to callback/errback to contained deferreds
- (id)_cbDeferred:(id)index succeeded:(id)succeeded result:(id)result;

@end


/**
 * DKDeferredWrapper
 *
 * Used internally to pause plain deferreds upon initialization. Resume
 * the contained deferred with [obj callback:nil];
 */
@interface DKDeferredWrapper : DKDeferred {
  DKDeferred *d;
}

- (id)initWithDeferred:(DKDeferred *)deferredToPause;
- (id)_cbStart:(id)result;

@end


/**
 * DKWaitForDeferred
 * 
 * This class essentially pauses the current thread until `d` returns
 * a result. It utilizes NSRunLoop and should not be used in 
 * any kind of process intensive loops (since it's poll interval
 * is only 1/100th of a second). It should normally allow for 
 * timers and events to continue being processed in the same thread.
 *
 * It's not normally recommended to use this method but functions as a 
 * great way to prototype. It does however allow you to do some cool things,
 * like calling JSON-RPC methods inline:
 *
 * <pre>
 * id ret = waitForDeferred(
 *           [[[DKDeferred jsonService:WS_URL]
 *            myNamespace] myMethod:array_(username, password, arg1)]);
 * </pre>         
 */
@interface DKWaitForDeferred : NSObject
{
  DKDeferred *d;
  id result;
  BOOL running;
}

@property (nonatomic, readwrite, retain) DKDeferred *d;
@property (nonatomic, readwrite, retain) id result;

- (id)initWithDeferred:(DKDeferred *)deferred;

@end


/**
 * DKThreadedDeferred
 * 
 * Wraps the execution of a DKCallback in it's own thread and 
 * callbacks with the function's return value. Can be paused
 * in which case [d callback:nil] will start the thread.
 */
@interface DKThreadedDeferred : DKDeferred
{
  NSThread *thread;
  NSThread *parentThread;
  id<DKCallback> action;
}

@property(readonly) NSThread *thread;
@property(readonly) NSThread *parentThread;
@property(readonly) id<DKCallback> action;

// initializers
+ (DKThreadedDeferred *)threadedDeferred:(id<DKCallback>)func;
+ (DKThreadedDeferred *)threadedDeferred:(id<DKCallback>)func paused:(BOOL)startPaused;
- (id)initWithFunction:(id<DKCallback>)func withObject:(id)arg;
- (id)initWithFunction:(id<DKCallback>)func 
            withObject:(id)arg 
             canceller:(id<DKCallback>)cancelf
                paused:(BOOL)startPaused;
// internal methods used to run the function
- (void)_cbThreadedDeferred:(id)arg;
- (void)_cbReturnFromThread:(id)result;

@end


/**
 * DKDeferredOperation
 * 
 * Wraps the execution of a DKCallback in an NSOperation and callbacks
 * with the function's return value. Operations are not started upon
 * creation of this object. You must add [d operation] to an
 * NSOperationQueue or call [[d operation] start].
 */
 
@interface DKDeferredOperation : DKDeferred
{
  NSOperation *op;
  NSThread *parentThread;
  id<DKCallback> action;
  id arg;
  BOOL _paused;
}

@property(readonly) NSOperation *operation;

+ (DKDeferredOperation *)operation:(id<DKCallback>)func withObject:(id)arg;
+ (DKDeferredOperation *)pausedOperation:(id<DKCallback>)func withObject:(id)arg;
- (id)initWithFunction:(id<DKCallback>)func 
            withObject:(id)arg
             canceller:(id<DKCallback>)cancelf
                paused:(BOOL)startPaused;
- (id)_cbStartOperation:(id)arg;
- (void)_cbOperation:(id)_arg;
- (void)_cbReturnFromOp:(id)result;

@end


/**
 * DKDeferredURLConnection
 *
 * Wraps URL requests in a simplified deferred interface. Callbacks
 * with the NSData value of the entire URL when done downloading. Can
 * be started paused in which case [d callback:nill] will start the
 * connection.
 */
@interface DKDeferredURLConnection : DKDeferred 
{
  NSString *url;
  NSMutableData *_data;
  NSURLConnection *connection;
  NSURLRequest *request;
  long expectedContentLength;
  double percentComplete;
  id<DKCallback> progressCallback;
  id<DKCallback> decodeFunction;
  NSTimeInterval refreshFrequency;
}

@property(nonatomic, readonly) NSString *url;
@property(nonatomic, readonly) NSData *data;
@property(nonatomic, readonly) long expectedContentLength;
@property(nonatomic, readonly) double percentComplete;
@property(nonatomic, readwrite, retain) id<DKCallback> progressCallback;
@property(nonatomic, readwrite, assign) NSTimeInterval refreshFrequency;

// initializers
+ (id)deferredURLConnection:(NSString *)aUrl;
+ (id)pausedDeferredURLConnection:(NSString *)aUrl;
- (id)initWithURL:(NSString *)aUrl;
- (id)initWithURL:(NSString *)aUrl paused:(BOOL)_paused;
- (id)initWithURL:(NSString *)aUrl pauseFor:(NSTimeInterval)pause;
- (id)initWithRequest:(NSURLRequest *)req 
             pauseFor:(NSTimeInterval)pause
       decodeFunction:(id<DKCallback>)decodeF;
- (id)initRequest:(NSURLRequest *)req 
   decodeFunction:(id<DKCallback>)decodeF
           paused:(BOOL)_paused;
// internal callbacks
- (id)_cbStartLoading:(id)result;
- (void)setProgressCallback:(id<DKCallback>)callback withFrequency:(NSTimeInterval)frequency;
- (void)_cbProgressUpdate;
// tracks how many DKDeferredURLConnections are currently active
+ (int)requestCount;

@end


/**
  * DKCache Protocol
  * 
  * An as-of-now internally used caching protocol. Whatever backend used,
  * this serves as a permanantly adopted protocol. Anything can be cached if
  * it conforms to the NSCoding protocol.
  */
@protocol DKCache <NSObject>

@required
- (id)setValue:(NSObject *)_value forKey:(NSString *)_key 
       timeout:(NSTimeInterval)_seconds; // deferred -> NSNumber
- (id)valueForKey:(NSString *)_key; // deferred -> NSObject
- (void)deleteValueForKey:(NSString *)_key; // deferred -> NSNumber
- (id)getManyValues:(NSArray *)_keys; // deferred -> NSDictionary
- (BOOL)hasKey:(NSString *)_key;
- (id)incr:(NSString *)_key delta:(int)delta; // nsnumber
- (id)decr:(NSString *)_key delta:(int)delta; // nsnumber

@end


/**
  * DKDeferredCache
  *
  * The current cache implementation used in DKDeferred. It implements
  * the DKCache protocol and uses a simple filesystem backend stored in
  * the users' applications cache directory.
  */
@interface DKDeferredCache : NSObject <DKCache>
{
  int maxEntries;
  int cullFrequency;
  NSString *dir;
  NSTimeInterval defaultTimeout;
  NSOperationQueue *operationQueue;
}

@property(assign) NSTimeInterval defaultTimeout;

+ (id)sharedCache;
- (id)initWithDirectory:(NSString *)_dir 
             maxEntries:(int)_maxEntries
          cullFrequency:(int)_cullFrequency;
- (id)_setValue:(NSObject *)value 
         forKey:(NSString *)key
        timeout:(NSNumber *)timeout 
            arg:(id)arg;
- (id)_getValue:(NSString *)key;
- (id)_getManyValues:(NSArray *)keys;
- (void)_cull;
- (int)_getNumEntries;

@end


@interface NSObject(DKDeferredCache)

+ (BOOL)canBeStoredInCache;

@end


/**
 * DKKeyedPool
 *
 * Manages a group of deferreds unique by key. A pool may be initialized
 * as either paused or not. A paused pool will automatically resume paused
 * deferreds as you add them. A pool can pause and resume all it's deferreds
 * and upon releaseing cancels all managed deferreds.
 */
@protocol DKKeyedPool <NSObject>

/**
 * Adds a deferred to the pool. Adding a deferred with
 * an existing key will silently cancel the added deferred,
 * killing all callbacks added to it. Deferreds must be chained with
 * the actual deferred to execute after being added to the active pool,
 * meaning ``d`` is waiting on [d callback:nil] to resume it.
 */
- (id)add:(DKDeferred *)d key:(id)k;
/**
 * Cancels all waiting and active deferreds.
 */
- (void)drain;
@optional
- (int)running;
- (void)setConcurrency:(int)numConcurrentDeferreds;
- (int)concurrency;
- (void)setTimeout:(double)concurrentDeferredTimeout;
- (double)timeout;
- (SEL)comparisonSelector;
- (void)setComparisonSelector:(SEL)selecter;

@end


/**
 * = MappedPriorityQueue =
 *
 * A priority queue that stores it's values in a mapping. An attempt
 * to insert an object for which it's key already exists should be ignored.
 */
@protocol MappedPriorityQueue <NSObject>

// returns obj or nil on duplicate key
- (id)enqueue:(id)obj key:(id)key;
- (id)enqueue:(id)obj key:(id)key prioritySelector:(SEL)prioritySelector;
// returns [obj, key]
- (id)dequeue;
- (id)peek;
- (int)count;
- (NSArray *)allValues;
- (NSArray *)allKeys;

@end


/**
 * = DKMappedPriorityQueue =
 * 
 * A mapped priority queue implementation. Uses the algorithm used
 * in the python module heapq.py implementation to minimize compares
 * on objects.
 */
@interface DKMappedPriorityQueue : NSObject <MappedPriorityQueue>
{
  NSMutableDictionary *_queueKeys; // {k => [sel, obj]}
  NSMutableArray *_queue; // [k, k...]
}

- (void)_siftUp:(int)pos;
- (void)_siftDown:(int)startPos :(int)pos;
- (NSComparisonResult)compareKeys:(id)leftKey :(id)rightKey;
- (id)objForKey:(id)key;
- (SEL)selForKey:(id)key;

@end


/**
 * = DKDeferredPool =
 * 
 * A Keyed Pool implementation. Doesn't yet support timeouts.
 */
@interface DKDeferredPool : NSObject <DKKeyedPool>
{
  id<MappedPriorityQueue> _queue;
  NSMutableDictionary *_runningDeferreds;
  int concurrency;
  double timeout;
  id<DKCallback> finalizeFunc;
  NSLock *wLock;
  SEL comparisonSelector;
}

+ (id)pool;
- (id)_cbRemoveDeferred:(id)key :(id)results;
- (void)_resumeWaiting;
- (void)_checkFinalization;
- (void)setFinalizeFunc:(id<DKCallback>)f;

@end
