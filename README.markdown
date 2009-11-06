# DeferredKit: Asynchronous programming made ridiculously easy for Cocoa and Cocoa Touch.

DeferredKit is an asynchronous library for cocoa built around the idea of a [Deferred Object](http://twistedmatrix.com/projects/core/documentation/howto/defer.html) - that is, "an object created to encapsulate a sequence of callbacks in response to an object that may not yet be available." Besides the core class, DKDeferred, much other functionality is included in this project, including an asynchronous URL loading API, an asynchronous disk cache, and a JSON-RPC implementation.

DeferredKit is modeled after the deferred class by  [TwistedMatrix](http://twistedmatrix.com/) and inspired by [MochiKit's](http://www.mochikit.com/doc/html/MochiKit/Async.html#fn-deferred) implementation of Deferred. DKCallback - the function object is mostly taken from a pre-blocks version of [FunctionalKit](http://github.com/mogeneration/functionalkit).

The DKDeferred implementation is not dependent upon threads or any other form of concurrency for it's operation (however, you may create threaded Deferred's) and operates in the same environment as the rest of your Objective-C program.

**NOTE:** DeferredKit bundles [json-framework](http://code.google.com/p/json-framework/), and will need to be removed from your project before adding DeferredKit using the following method. Otherwise, embedding the code works just as well.

More:
  1. [JSON-RPC in Objective-C](http://samuraiblog.com/wordpress/2009/11/06/json-rpc-in-objective-c/)

## Installing DeferredKit
1. Copy the entire source tree into your projects directory.
2. Add DeferredKit to your project.
    * Copy `"{PROJECT_ROOT}/DeferredKit/CocoaDeferred/CocoaDeferred.xcodeproj"`
    * In the window presented by Xcode, uncheck "Copy items...". Reference type should be "Relative to Project"
    * Uncheck any targets Xcode might automatically assume.
3. Add DeferredKit to your header search paths.
    * Under your target's build settings, search for find "Header Search Paths" and add `"DeferredKit/CocoaDeferred/Source"`
4. Add DeferredKit to your Target
    * Under your target's general settings, under Direct Dependancies click the "+" button and choose "DeferredKit"
5. Expand your `"CocoaDeferred.xcodeproj"` and drag `"libDeferredKit.a"` to your target's "Link Binary with Library"

## Example Usage
### Asynchronous URL Loading
All methods in DeferredKit return Deferred objects. This is the same basic interface used to access all functionality provided by DeferredKit.

    id cbGotResource(id results) {
      [[Resource resourceWithData:results] save];
      return nil;
    }

    id cbGetResourceFailed(id error) {
      // alert user resource is unavailable.
      return nil;
    }

    DKDeferred *d = [DKDeferred loadURL:@"http://addr.net/resource/"];
    [d addCallback:callbackP(cbGotResource)];
    [d addCallback:callbackP(cbGetResourceFailed)];

### Asynchronous processing
You can generate Deferred objects which encapsulate the execution of a method or function in a thread. The Deferred automatically returns the result to the correct thread.

    id cbDoneProcessing(id results) {
      if (content) {
        [content release];
        content = nil;
      }
      content = [results retain];
      [tableView reloadData];
      return nil;
    }
    
    DKDefered *d =[DKDeferred deferInThread:
                   callbackTS((id)[Resource class], updateAllResources:)];
    [d addCallback:cbDoneProcessing];

### Combining Asynchronous tasks
These two Deferred objects may return almost immediately if loaded from the cache.

    - (IBAction)loadResource:(id)sender {
      DKDeferred *html = [DKDeferred loadURL:@"http://url1.com/resource" cached:YES];
      DKDeferred *header = [DKDeferred loadImage:@"http://url1.com/resource-img.png" cached:YES];
    
      DKDeferred *d = [DKDeferred gatherResults:array_(html, header)];
      [d addCalback:callbackTS(self, cbDoneLoading:)];
    }
    
    - (id)cbDoneLoading:(id)results {
      [self showHTML:[results objectAtIndex:0]];
      [self showHeaderImage:[results objectAtIndex:1]];
      return nil;
    }

### Interacting with a JSON-RPC Service
DeferredKit provides a JSON-RPC implementation using DKDeferred.

    id myservice = [DKDeferred jsonService:@"" name:@"myservice"]
    DKDeferred *d = [myservice someMethod:array(arg1, arg2)]
    [d addCallbacks:callbackTS(self, cbGotResults:) :callbackTS(cbGetResultsFailed:)];

### Asynchronous processing chain
Each callback added to a DKDeferred results in a chain of callbacks - the last callback added will be called with the result returned by the previous callback.

    - (IBAction)fetchResources:(id)sender {
      id _parseResults:(id results) {
        // _parseResults can return an NSError at which point the deferred
        // will begin it's error callback chain
        return [Resource arrayWithJSONResponse:results];
      }
      
      DKDeferred *d = [DKDeferred loadJSONDoc:@"http://whereitsat.net/resource/"]
      [d addCallback:callbackP(_parseResults)];
      [d addCallback:callbackTS(self, _presentResources:)];
      [d addErrback:callbackTS(self, _getResourcesFailed:)];
    }
    
    - (id)_presentResources:(id)results {
      if (resources) {
        [resources release];
        resources = nil;
      }
      resources = [results retain];
      [tableView reloadData];
    }

### Asynchronous disk cache
Since the disk cache utilizes a deferred object interface, access to cached results can implement caching in only a few lines.

    - (IBAction)fetchSomeStuff:(id)sender {
      id _gotKey(id results) {
        if (results == [NSNull null]) { // cache miss
          return [DKDeferred deferInThread:[Resource getResources] withObject:nil];
        } else { // cache hit
          return results;
        }
      }
      DKDeferred *d = [[DKDeferredCache sharedCache] valueForKey:@"someKey"];
      [d addCallback:callbackP(_gotKey)];
      [d addCallback:callbackTS(self, cbGotResults:)];
    }
    
    - (id)cbGotResults:(id)results {
      if (isDeferred(results)) // in the event of a cache miss
        return [results addCallback:callbackTS(self, cbGotResults:)];
      if (resources) {
        [resources release];
        resources = nil;
      }
      resources = [results retain];
      [tableView reloadData];
    }

## Reference

### DKDeferred

#### Properties
### `@property(readonly) int fired`
### `@property(readonly) int paused`
### `@property(readonly) NSArray *results`
### `@property(readonly) BOOL silentlyCancelled`
### `@property(readwrite) BOOL chained`
### `@property(readonly) id<DKCallback> canceller`
### `@property(readonly) NSString *deferredID`
### `@property(readwrite, retain) id<DKCallback> finalizer`

#### Class Methods
### `+[DKDeferred deferred]`
  >  Returns an empty `DKDeferred`
### `+[DKDeferred maybeDeferred:(id<DKCallback>)maybeDeferred]`
  > 
### `+[DKDeferred gatherResuls:(NSArray *)listOfDeferreds]`
### `+[DKDeferred succeed:(id)resultOrNil]`
### `+[DKDeferred fail:(id)resultOrNil]`
### `+[DKDeferred wait:(NSTimeInterval)seconds value:(id)callbackWithOrNil]`
### `+[DKDeferred callLater:(NSTimeInterval)seconds func:(id<DKCallback>)function]`
### `+[DKDeferred deferInThread:(id<DKCallback>)function withObject:(id)argOrNil]`
### `+[DKDeferred loadURL:(NSString *)url]`
### `+[DKDeferred loadURL:(NSString *)url cached:(BOOL)cached]`

#### Instance Methods
### `-[DKDeferred initWithCanceller:(id<DKCallback>)cancellerFunctionOrNil]`
### `-[DKDeferred addBoth:(id<DKCallback>)function]`
### `-[DKDeferred addCallback:(id<DKCallback>)function]`
### `-[DKDeferred addErrback:(id<DKCallback>)function]`
### `-[DKDeferred addCallbacks:(id<DKCallback>)callback :(id<DKCallback>)errback]`
### `-[DKDeferred cancel]`
### `-[DKDeferred callback:(id)resultOrNil]`
### `-[DKDeferred errback:(id)resltOrNil]`


### DKDeferred (JSONAdditions)

#### Class Methods
### `+[DKDeferred loadJSONDoc:(NSString *)url]`
### `+[DKDeferred jsonService:(NSString *)url name:(NSString *)serviceName]`

### DKDeferred (UIKitAdditions)

#### Class Methods
### `+[DKDeferred loadImage:(NSString *)url cached:(BOOL)cached]`
### `+[DKDeferred loadImage:(NSString *)url sizeTo:(CGSize)finalSize cached:(BOOL)cached]`

### DKDeferredList

#### Properties
### `@property(readwrite, assign) BOOL fireOnOneCallback`
### `@property(readwrite, assign) BOOL fireOneOneErrback`
### `@property(readwrite, assign) BOOL consumeErrors`
### `@property(readonly) int finishedCount`

#### Class Methods
### `+[DKDeferred deferredList:(NSArray *)listOfDeferreds]`
### `+[DKDeferred deferredList:(NSArray *)listOfDeferreds withCanceller:(id<DKCallback>)cancellerFuncOrNil]`

#### Instance Methods
### `-[DKDeferred initWithList:(NSArray *)listOfDeferreds withCanceller:(id<DKCallback>)cancellerFuncOrNil fireOnOneCallback:(BOOL)fireFirstResult fireOnOneErrback:(BOOL)fireFirstError consumeErrors:(BOOL)continueChainOnError]`

### DKCache

#### Class Methods
### `+[DKDeferredCache sharedCache]`

#### Instance Methods
### `-[DKDeferredCache setValue:(NSObject *)val forKey:(NSString *)key timeout:(NSTimeInterval)secondsUntilInvalid]`
### `-[DKDeferredCache valueForKey:(NSString *)key]`
### `-[DKDeferredCache deleteValueForKey:(NSString *)key]`
### `-[DKDeferredCache getManyValues:(NSArray *)listOfKeys]`
### `-[DKDeferredCache hasKey:(NSString *)key]`
### `-[DKDeferredCache incr:(NSString *)key delta:(int)numToIncrementBy]`
### `-[DKDeferredCache decr:(NSString *)key delta:(int)numToDecrementBy]`

### NSObject (DKDeferredCache)

#### Class Methods
### `+[NSObject canBeStoredInCache]`

### DKCallback

#### Macros
### `callbackP(selector) -> [DKCallback fromPointer:(dkCallback)functionPointer]`
### `callbackTS(target, selector) -> [DKCallback fromSelector:@selector(selector) target:target]`
### `callbackS(selector) -> [DKCallback fromSelector:@selector(selector)]`
### `callbackI(invocation, argIndex) -> [DKCallback fromInvocation:invocation parameterIndex:argIndex]`

#### Class Methods
### `+[DKCallback fromSelector:(SEL)selector]`
### `+[DKCallback fromSelector:(SEL)selector target:(id)target]`
### `+[DKCallback fromPointer:(dkCallback)functionPointer]`
### `+[DKCallback fromInvocation:(NSInvocation *)invocation parameterIndex:(NSUInteger)argIndex]`

#### Instance Methods
### `-[DKCallback andThen:(DKCallback *)other]`
### `-[DKCallback composeWith:(DKCallback *)other]`