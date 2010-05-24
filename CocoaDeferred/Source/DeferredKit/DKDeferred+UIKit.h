//
//  DKDeferred+UIKit.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import <UIKit/UIKit.h>
#import "DKDeferred.h"

@interface DKDeferred (UIKitAdditions)

/**
 * Returns a DKDeferred that will callback with UIImage containing the image
 * at <code>aUrl</code>. Can optionally cache it's results in the <code>+[DKDeferredCache sharedCache]</code>
 * for <code>-[DKDeferredCache defaultTimeout]</code>.
 */
+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached;

/**
 * Returns a DKDeferred that will callback with a UIImage containing the image
 * at <code>aUrl</code> proportionally scaled to meet the requirements of <code>size</code>.
 * Can optionally cache the resized image in the <code>+[DKDeferredCache sharedCache]</code>
 * for <code>-[DKDeferredCache defaultTimeout]</code>.
 */
+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached;

/**
 * Same as loadImage:cached: except that it may be started paused. If <code>paused</code> is <code>YES</code>
 * to initiate the network connection or to check the cache you must call [deferred callback:nil]
 */
+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached paused:(BOOL)_paused;

/**
 * Same as loadImage:sizeTo:cached: except that it may be started paused. If <code>paused is <code>YES</code>
 * to initilize the network connection or to check the cache you must call [deferred callback:nil]
 */
+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached paused:(BOOL)_paused;


@end
