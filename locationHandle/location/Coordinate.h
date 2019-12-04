//
//  Coordinate.h
//  LocationHandlerForMac
//
//  Created by Dream on 2019/5/17.
//  Copyright © 2019 wjm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Coordinate : NSObject

@property (assign, readonly) double latitude;
@property (assign, readonly) double longitude;
@property (copy, readonly) NSString *latStr;
@property (copy, readonly) NSString *lngStr;
@property (copy, readonly) NSString *stringValue;

- (instancetype)initWithLat:(double)lat lng:(double)lng;
- (instancetype)initWithLatLngStr:(NSString *)latLng;

@end

NS_ASSUME_NONNULL_END
