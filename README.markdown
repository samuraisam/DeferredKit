# DeferredKit: Asynchronous programming made ridiculously easy for Cocoa and Cocoa Touch.

DeferredKit is an asynchronous library for cocoa built around the idea of a [Deferred Object](http://twistedmatrix.com/projects/core/documentation/howto/defer.html) - that is, "an object created to encapsulate a sequence of callbacks in response to an object that may not yet be available." Besides the core class, DKDeferred, much other functionality is included in this project, including an asynchronous URL loading API, an asynchronous disk cache, and a JSON-RPC implementation.

DeferredKit is modeled after the deferred class by  [TwistedMatrix's](http://twistedmatrix.com/) and inspired by [MochiKit's](http://www.mochikit.com/doc/html/MochiKit/Async.html#fn-deferred) implementation of Deferred.

The DKDeferred implementation is not dependent upon threads or any other form of concurrency for it's operation (however, you may create threaded Deferred's) and operates in the same environment as the rest of your Objective-C program.

**NOTE:** DeferredKit bundles [json-framework](http://code.google.com/p/json-framework/), and will need to be removed from your project before adding DeferredKit using the following method. Otherwise, embedding the code works just as well.

## Installing DeferredKit
1. Copy the entire source tree into your projects directory.
2. Add DeferredKit to your project.
  * Copy "{PROJECT_ROOT}/DeferredKit/CocoaDeferred/CocoaDeferred.xcodeproj"
  * In the window presented by Xcode, uncheck "Copy items...". Reference type should be "Relative to Project"
  * Uncheck any targets Xcode might automatically assume.
3. Add DeferredKit to your header search paths.
  * Under your target's build settings, search for find "Header Search Paths" and add "DeferredKit/CocoaDeferred/Source"
4. Add DeferredKit to your Target
  * Under your target's general settings, under Direct Dependancies click the "+" button and choose "DeferredKit"
5. Expand your "CocoaDeferred.xcodeproj" and drag "libDeferredKit.a" to your target's "Link Binary with Library"

## Example Usage
### Deferred URL Loading

    - (void)userTouchedGo:(id)sender {
    		DKDeferred *d = [DKDeferred loadURL:@"http://google.com/"];
    		[d addCallback:callbackTS(self, googleDidLoad:);
    		[d addErrback:callbackTS(self, googleFailedToLoad:);
    }

    - (id)googleDidLoad:(id)result { // in this case, an NSData object
    		[loadingView removeFromSuperview];
    		[webView loadHTMLString:[NSString stringWithUTF8String:[result bytes]]
    										baseURL:[NSURL URLWithString:@"google.com"]];
    		[view addSubview:webView];
    		return nil;
    }

    - (id)googleFailedToLoad:(NSError *)result {
    		// tell the user the internet is down.
    		return nil;
    }

