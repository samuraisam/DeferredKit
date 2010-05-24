//
//  DKDeferred+CoreLocation.h
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import <Foundation/Foundation.h>
#import "DKDeferred.h"
#import <CoreLocation/CoreLocation.h>

//@class CLLocation;
//@class CLLocationManager;
//@protocol CLLocationManagerDelegate;



@interface DKDeferred (CoreLocationAdditions)

+ (id)getLocation;

@end

/* --------------------
 DKDeferredLocation
 -------------------- */

@interface DKDeferredLocation : DKDeferred <CLLocationManagerDelegate>
{
  CLLocation *location;
  CLLocationManager *_manager;
  BOOL onlyOne;
  BOOL failed;
  int updates;
}

@property(readonly) CLLocation *location;

- (id)init:(BOOL)onlyOne;
- (void)_timeout:(id)arg;

@end
