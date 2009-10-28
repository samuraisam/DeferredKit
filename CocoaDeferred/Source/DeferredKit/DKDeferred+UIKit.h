//
//  DKDeferred+UIKit.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import <UIKit/UIKit.h>
#import "DKDeferred.h"

//@class UIImage;

@interface DKDeferred (UIKitAdditions)

+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached;
+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached;
+ (id)loadImage:(NSString *)aUrl cached:(BOOL)cached paused:(BOOL)_paused;
+ (id)loadImage:(NSString *)aUrl sizeTo:(CGSize)size cached:(BOOL)cached paused:(BOOL)_paused;


@end
