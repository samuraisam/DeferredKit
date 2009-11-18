//
//  DKCallback.m
//  DeferredKit
//
//  Created by Samuel Sutch on 8/30/09.
//

#import "DKCallback.h"


@interface DKCallbackFromSelector : DKCallback {
  SEL selector;
}

@property(readonly) SEL selector;
- (DKCallbackFromSelector *)initWithSelector:(SEL)s;

@end

@implementation DKCallbackFromSelector

@synthesize selector;

- (DKCallbackFromSelector *)initWithSelector:(SEL)s {
  if ((self = [super init])) {
    selector = s;
  }
  return self;
}

- (id):(id)arg {
  return [arg performSelector:selector];
}

@end

@interface DKCallbackFromSelectorWithTarget : DKCallback {
  SEL selector;
  NSObject *target;
}

@property(readonly) SEL selector;
@property(readonly) NSObject *target;
- (DKCallbackFromSelectorWithTarget *)initWithSelector:(SEL)s target:(NSObject *)t;

@end

@implementation DKCallbackFromSelectorWithTarget

@synthesize selector, target;

- (DKCallbackFromSelectorWithTarget *)initWithSelector:(SEL)s target:(NSObject *)t {
  if (![t respondsToSelector:s]) {
    @throw [NSException 
            exceptionWithName:NSInvalidArgumentException 
            reason:[NSString stringWithFormat:@"%@ does not respond to selector %s", t, sel_getName(s)]
            userInfo:nil];
  }
  if ((self = [super init])) {
    selector = s;
    target = [t retain];
  }
  return self;
}

- (id):(id)arg {
  return [target performSelector:selector withObject:arg];
}

- (void)dealloc {
  [target release];
  [super dealloc];
}

@end

@interface DKCallbackComposition : DKCallback {
  DKCallback *f;
  DKCallback *g;
}

- (DKCallbackComposition *)initWithF:(DKCallback *)anF andG:(DKCallback *)aG;
@end

@implementation DKCallbackComposition

- (DKCallbackComposition *)initWithF:(DKCallback *)anF andG:(DKCallback *)aG {
  if ((self = [super init])) {
    f = [anF retain];
    g = [aG retain];
  }
  return self;
}

- (void)dealloc {
  [f release];
  [g release];
  [super dealloc];
}

- (id):(id)arg {
  return [f :[g :arg]];
}

@end

@interface DKCallbackFromPointer : DKCallback {
  dkCallback theFunction;
}
- (DKCallback *)initWithPointer:(dkCallback)fp;
@end
@implementation DKCallbackFromPointer
- (DKCallback *)initWithPointer:(dkCallback)fp {
  if ((self = [super init])) {
    theFunction = fp;
  }
  return self;
}
- (id):(id)arg {
  return (*theFunction)(arg);
}
@end


@interface DKCallbackFromInvocation : DKCallback {
  NSInvocation *invocation;
  NSUInteger index;
}
- (DKCallback *)initWithInvocation:(NSInvocation *)inv parameterIndex:(NSUInteger)idx;
@end

@implementation DKCallbackFromInvocation
- (DKCallback *)initWithInvocation:(NSInvocation *)inv parameterIndex:(NSUInteger)idx {
  if ((self = [super init])) {
    //    NSLog(@"inv: %@", inv);
    invocation = [inv retain];
    index = idx;
  }
  return self;
}
- (id):(id)arg {
  [invocation setArgument:&arg atIndex:(index + 2)];
  [invocation invoke];
  id anObject;
  [invocation getReturnValue:&anObject];
  return anObject;
}
- (void)dealloc {
  [invocation release];
  [super dealloc];
}

@end

@implementation DKCallback

+ (DKCallback *)fromSelector:(SEL)s {
  return [[[DKCallbackFromSelector alloc] initWithSelector:s] autorelease];
}

+ (DKCallback *)fromSelector:(SEL)s target:(NSObject *)target {
  return [[[DKCallbackFromSelectorWithTarget alloc] initWithSelector:s target:target] autorelease];
}

+ (DKCallback *)fromPointer:(dkCallback)f {
  return [[[DKCallbackFromPointer alloc] initWithPointer:f] autorelease];
}

+ (DKCallback *)fromInvocation:(NSInvocation *)invocation parameterIndex:(NSUInteger)index {
  return [[[DKCallbackFromInvocation alloc] initWithInvocation:invocation parameterIndex:index] autorelease]; 
}

- (id):(id)arg {
  @throw [NSException exceptionWithName:@"InvalidOperation" reason:@"Must override -(id):(id) in DKCallback" userInfo:nil];
}

- (DKCallback *)andThen:(DKCallback *)other {
  return [other composeWith:self];
}

- (DKCallback *)composeWith:(DKCallback *)other {
  return [[DKCallbackComposition alloc] initWithF:self andG:other];
}
@end