//
//  DKDeferred+CoreLocation.m
//  DeferredKit
//
//  Created by Samuel Sutch on 8/31/09.
//

#import "DKDeferred+CoreLocation.h"


@implementation DKDeferred (CoreLocationAdditions)

+ (id)getLocation {
  return [[DKDeferredLocation alloc] init:YES];
}

@end

@implementation DKDeferredLocation

@synthesize location;

- (id)init:(BOOL)fetcOnlyOne { // TODO: respect fetchOnlyOne or numberOfUpdates
  if ((self = [super initWithCanceller:nil])) {
    location = nil;
    onlyOne = fetcOnlyOne;
    updates = 0;
    _manager = [[[CLLocationManager alloc] init] retain];
    [_manager setDelegate:self];
    [_manager startUpdatingLocation];
    // timeout
    [DKDeferred callLater:10.0 func:callbackTS(self, _timeout:)];
  }
  return self; 
}

- (void)_timeout:(id)arg {
  if (fired == -1) {
    [_manager stopUpdatingLocation];
    [self errback:
     [NSError
      errorWithDomain:@"DKDeferredLocation"
      code:4020 
      userInfo:dict_(@"Get location timed out", @"message")]];
  }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
  //  location = [newLocation retain];
  //  if (onlyOne) {
  //    [manager stopUpdatingLocation];
  //    [manager release];
  //  }
  updates += 1;
  if (updates > 1) {
    [manager stopUpdatingLocation];
    location = [newLocation retain];
    [self callback:location];
  }
}

- (void)locationManager:(CLLocationManager *)manager 
       didFailWithError:(NSError *)error {
  [manager stopUpdatingLocation];
  [self errback:error];
}

@end