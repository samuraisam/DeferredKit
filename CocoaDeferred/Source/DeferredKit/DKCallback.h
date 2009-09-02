//
//  DKCallback.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/30/09.
//

#import <Foundation/Foundation.h>

#define callbackS(sel) [DKCallback fromSelector:@selector(sel)]
#define callbackTS(tgt, sel) [DKCallback fromSelector:@selector(sel) target:tgt]
#define callbackP(fp) [DKCallback fromPointer:fp]
#define callbackI(inv, i) [DKCallback fromInvocation:inv parameterIndex:i]

@protocol DKCallback <NSObject>

- (id):(id)arg;

@end

typedef id (*dkCallback)(id);

@interface DKCallback : NSObject <DKCallback>

+ (DKCallback *)fromSelector:(SEL)s;
+ (DKCallback *)fromSelector:(SEL)s target:(NSObject *)target;
+ (DKCallback *)fromPointer:(dkCallback)f;
+ (DKCallback *)fromInvocation:(NSInvocation *)inv parameterIndex:(NSUInteger)i;
- (DKCallback *)andThen:(DKCallback *)other;
- (DKCallback *)composeWith:(DKCallback *)other;

@end
