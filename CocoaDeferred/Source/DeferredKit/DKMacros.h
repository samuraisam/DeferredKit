/*
 *  DKMacros.h
 *  DeferredKit
 *
 *  Created by Samuel Sutch on 7/25/09.
 */

#ifdef __OBJC__
//#import "FK/FKFunction.h"
#import "DKCallback.h"

/** Curries a target->selector into an DKCallback 
 *
 * ``target``   is the object the selector will be sent to
 * ``selector`` is the message sent to ``target``
 * ``numargs``  must be the length of args supplied to the
 *              curried method. The last argument must be free
 *              for an argument when the function is called.
 * ``...``      any aditional arguments, (the same number of arguments
 *              as provided to ``numargs``
 **/
static inline id<DKCallback> _curryTS(id target, SEL selector, ...) {
  NSMethodSignature *sig = ([target isKindOfClass:[NSObject class]] ? 
                            [target methodSignatureForSelector:selector] :
                            [[target class] instanceMethodSignatureForSelector:selector]);
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
  [invocation setTarget:target];
  [invocation setSelector:selector];
  va_list argumentList;
  va_start(argumentList, selector);
  id arg;
  int i = 0;
  while (arg = va_arg(argumentList, id)) {
    //NSLog(@"arg:%@", arg);
    [invocation setArgument:&arg atIndex:i + 2];
    i++;
  }
  if (! (i == ([sig numberOfArguments] - 3))) {
    @throw [NSException exceptionWithName:@"CurryArgumentCountException" 
                                   reason:@"The number of arguments supplied to curry must be one "
            @"less than the total number of arguments for the given implementation"
                                 userInfo:nil];
  }
  va_end(argumentList);
  [invocation retainArguments];
  return [DKCallback fromInvocation:invocation parameterIndex:i];
}

#define curryTS(__target, __selector, args...) _curryTS(__target, __selector, args, nil)
#define isDeferred(__obj) [__obj isKindOfClass:[DKDeferred class]]
#define waitForDeferred(__d) [[[[[[DKWaitForDeferred alloc] initWithDeferred:__d] autorelease] result] retain] autorelease]
#define pauseDeferred(__d) [[[DKDeferredWrapper alloc] initWithDeferred:__d] autorelease]
#define nsni(__i) [NSNumber numberWithInt:__i]
#define nsnd(__d) [NSNumber numberWithDouble:__d]
#define nsnf(__f) [NSNumber numberWithFloat:__f]
#define nsnb(__b) nsni(__b)
#define intv(__o) [__o intValue]
#define doublev(__o) [__o doubleValue]
#define floatv(__o) [__o floatValue]
#define boolv(__o) [__o boolValue]
#define array_(__args...) [NSArray arrayWithObjects:__args, nil]
#define dict_(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]
#ifndef EMPTY_DICT
#define EMPTY_DICT [NSDictionary dictionary]
#endif
#ifndef EMPTY_ARRAY
#define EMPTY_ARRAY [NSArray array]
#endif

/**
  * Creates a new NSString containing a UUID
  **/
static inline NSString* _uuid1() {
  CFUUIDRef uuid = CFUUIDCreate(nil);
  NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuid);
  CFRelease(uuid);
  return [uuidString autorelease];
}
#endif