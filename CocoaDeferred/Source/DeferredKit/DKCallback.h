//
//  DKCallback.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/30/09.
//

#import <Foundation/Foundation.h>

/**
 * Shorthand for [DKCallback fromSelector:]
 */
#define callbackS(sel) [DKCallback fromSelector:@selector(sel)]
/** 
 * Shorthand for [DKCallback fromSelector:target:]
 */
#define callbackTS(tgt, sel) [DKCallback fromSelector:@selector(sel) target:tgt]
/**
 * Shorthand for [DKCallback fromPointer:]
 */
#define callbackP(fp) [DKCallback fromPointer:fp]
/**
 * Shorthand for [DKCallback fromInvocation:parameterIndex:]
 */
#define callbackI(inv, i) [DKCallback fromInvocation:inv parameterIndex:i]


/**
 * DKCallback (protocol)
 * 
 * Provides a unified function object. Callbacks can be made any 
 * target but must take a single <code>(id)</code> argument and return
 * an <code>(id)</code>.
 */
@protocol DKCallback <NSObject>

- (id):(id)arg;

@end

typedef id (*dkCallback)(id);


/**
 * DKCallback (interface)
 * 
 * Provides implementations of DKCallback for.
 * <pre>
 * -[arg selector]
 * -[target selector:arg]
 * functionPointer(arg)
 * NSInvocation objects
 * </pre>
 */
@interface DKCallback : NSObject <DKCallback>

/**
 * Returns a DKCallback which will get it's result from performing <code>selector</code>
 * on the argument it's called with.
 */
+ (DKCallback *)fromSelector:(SEL)s;

/**
 * Returns a DKCallback that will get it's result from
 * performing <code>selector</code> on <code>target</code>. <code>selector</code>
 * must always take exactly one <code>id</code> arg and return <code>id</code>.
 */
+ (DKCallback *)fromSelector:(SEL)s target:(NSObject *)target;

/**
 * Returns a DKCallback from a function pointer. It must have the signature 
 * <code>id f(id arg) { }</code>
 */
+ (DKCallback *)fromPointer:(dkCallback)f;

/**
 * Returns a DKCallback from an NSInvocation parameter index must always be at least 2
 * to accomidate for <code>_cmd</code> and <code>self</code>.
 */
+ (DKCallback *)fromInvocation:(NSInvocation *)inv parameterIndex:(NSUInteger)i;

/**
 * Returns a DKCallback that calls <code>other</code> with the result of <code>self</code>
 */
- (DKCallback *)andThen:(DKCallback *)other;

/**
 * Returns a DKCallback that calls <code>self</code> with the result of <code>other</code>
 */
- (DKCallback *)composeWith:(DKCallback *)other;

@end
