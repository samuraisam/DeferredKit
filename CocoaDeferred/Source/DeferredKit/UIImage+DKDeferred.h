//
//  UIImage+DKDeferred.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/30/09.
//

#import <UIKit/UIKit.h>

@interface UIImage (DKDeferredAdditions)

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
- (UIImage *)scaleImageToSize:(CGSize)newSize;

@end