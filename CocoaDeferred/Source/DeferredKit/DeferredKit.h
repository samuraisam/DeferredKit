/*
 *  DKFatass.h
 *  DeferredKit
 *
 *  Created by Samuel Sutch on 8/31/09.
 */

#import "DKDeferred.h"
#import "DKDeferred+UIKit.h"
#import "DKDeferred+JSON.h"

/*! \mainpage DKDeferred - Deferred objects for Objective-C
  <p>DeferredKit is an asynchronous library for cocoa built around the idea of a <a href="http://twistedmatrix.com/projects/core/documentation/howto/defer.html">Deferred Object</a> - that is, "an object created to encapsulate a sequence of callbacks in response to an object that may not yet be available." Besides the core class, DKDeferred, much other functionality is included in this project, including an asynchronous URL loading API, an asynchronous disk cache, and a JSON-RPC implementation.</p>

  <p>DeferredKit is modeled after the deferred class by  <a href="http://twistedmatrix.com/">TwistedMatrix</a> and inspired by <a href="http://www.mochikit.com/doc/html/MochiKit/Async.html#fn-deferred">MochiKit's</a> implementation of Deferred. DKCallback - the function object is mostly taken from a pre-blocks version of <a href="http://github.com/mogeneration/functionalkit">FunctionalKit</a>.</p>

  <p>The DKDeferred implementation is not dependent upon threads or any other form of concurrency for it's operation (however, you may create threaded Deferred's) and operates in the same environment as the rest of your Objective-C program.</p>

  <p><strong>NOTE:</strong> DeferredKit bundles <a href="http://code.google.com/p/json-framework/">json-framework</a>, and will need to be removed from your project before adding DeferredKit using the following method. Otherwise, embedding the code works just as well.</p>

  <p>More:
    1. <a href="http://samuraiblog.com/wordpress/2009/11/06/json-rpc-in-objective-c/">JSON-RPC in Objective-C</a></p>

  <h2>Installing DeferredKit</h2>

  <ol>
  <li>Copy the entire source tree into your projects directory.</li>
  <li>Add DeferredKit to your project.

  <ul>
  <li>Copy <code>"{PROJECT_ROOT}/DeferredKit/CocoaDeferred/CocoaDeferred.xcodeproj"</code> to the <strong>Groups and Files</strong> pane of Xcode.</li>
  <li>In the window presented by Xcode, uncheck "Copy items...". Reference type should be "Relative to Project"</li>
  <li>Uncheck any targets Xcode might automatically assume.</li>
  </ul>
  </li>
  <li>Add DeferredKit to your header search paths.

  <ul>
  <li>Under your target's build settings, search for find "Header Search Paths" and add <code>"DeferredKit/CocoaDeferred/Source"</code></li>
  </ul>
  </li>
  <li>Add DeferredKit to your Target

  <ul>
  <li>Under your target's general settings, under Direct Dependancies click the "+" button and choose "DeferredKit"</li>
  </ul>
  </li>
  <li>Expand your <code>"CocoaDeferred.xcodeproj"</code> and drag <code>"libDeferredKit.a"</code> to your target's "Link Binary with Library"</li>
  </ol>


  <h2>Example Usage</h2>

  <h3>Asynchronous URL Loading</h3>

  <p>All methods in DeferredKit return Deferred objects. This is the same basic interface used to access all functionality provided by DeferredKit.</p>

  <pre><code>\code id cbGotResource(id results) {
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
  \endcode</code></pre>

  <h3>Asynchronous processing</h3>

  <p>You can generate Deferred objects which encapsulate the execution of a method or function in a thread. The Deferred automatically returns the result to the correct thread.</p>

  <pre><code>\code id cbDoneProcessing(id results) {
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
  \endcode</code></pre>

  <h3>Combining Asynchronous tasks</h3>

  <p>These two Deferred objects may return almost immediately if loaded from the cache.</p>

  <pre><code>\code- (IBAction)loadResource:(id)sender {
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
  \endcode</code></pre>

  <h3>Interacting with a JSON-RPC Service</h3>

  <p>DeferredKit provides a JSON-RPC implementation using DKDeferred.</p>

  <pre><code>\code id myservice = [DKDeferred jsonService:@"" name:@"myservice"]
  DKDeferred *d = [myservice someMethod:array(arg1, arg2)]
  [d addCallbacks:callbackTS(self, cbGotResults:) :callbackTS(cbGetResultsFailed:)];
  \endcode</code></pre>

  <h3>Asynchronous processing chain</h3>

  <p>Each callback added to a DKDeferred results in a chain of callbacks - the last callback added will be called with the result returned by the previous callback.</p>

  <pre><code>\code- (IBAction)fetchResources:(id)sender {
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
  \endcode</code></pre>

  <h3>Asynchronous disk cache</h3>

  <p>Since the disk cache utilizes a deferred object interface, access to cached results can implement caching in only a few lines.</p>

  <pre><code>\code- (IBAction)fetchSomeStuff:(id)sender {
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
  \endcode</code></pre>
*/
