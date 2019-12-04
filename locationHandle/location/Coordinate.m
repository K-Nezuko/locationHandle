//
//  Coordinate.m
//  LocationHandlerForMac
//
//  Created by Dream on 2019/5/17.
//  Copyright © 2019 wjm. All rights reserved.
//

#import "Coordinate.h"

@interface Coordinate()

@property (copy) NSString *lat;
@property (copy) NSString *lng;

@end

@implementation Coordinate

- (instancetype)initWithLat:(double)lat lng:(double)lng {
    self = [super init];
    if (self) {
        self.lat = [NSString stringWithFormat:@"%.6f", lat];
        self.lng = [NSString stringWithFormat:@"%.6f", lng];
    }
    return self;
}

- (instancetype)initWithLatLngStr:(NSString *)latLng {
    self = [super init];
    if (self) {
        NSArray *arr = [latLng componentsSeparatedByString:@","];
        self.lat = [NSString stringWithFormat:@"%.6f", [[arr firstObject] doubleValue]];
        self.lng = [NSString stringWithFormat:@"%.6f", [[arr lastObject] doubleValue]];
    }
    return self;
}

- (double)latitude {
    return self.lat.doubleValue;
}

- (double)longitude {
    return self.lng.doubleValue;
}

- (NSString *)latStr {
    return self.lat;
}

- (NSString *)lngStr {
    return self.lng;
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"%@,%@", self.lat, self.lng];
}

@end
