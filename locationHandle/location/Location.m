//
//  Location.m
//  locationHandle
//
//  Created by Dream on 2019/12/3.
//

#import "Location.h"
#import <Carbon/Carbon.h>
#import "ChangeLoction.h"

@interface Location()

@property (strong) Coordinate *cLocation;

@end

static NSString *CacheKey = @"location_cacheKey";

@implementation Location

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static Location *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[Location alloc] init];
        [_instance getLocationFromCache];
    });
    return _instance;
}

- (NSString *)moveToNewLocation:(Coordinate *)newLocation {
    NSString *errMsg = [self performShellWithCoordinate:newLocation];
    if (errMsg.length==0) {
        self.cLocation = [[Coordinate alloc] initWithLat:newLocation.latitude lng:newLocation.longitude];
        [self saveLocationToCache];
        return nil;
    } else {
        return errMsg;
    }
}

/// get
- (void)getLocationFromCache {
    NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:CacheKey];
    if (c.length == 0) c = @"30.267916,120.147963";
    self.cLocation = [[Coordinate alloc] initWithLatLngStr:c];
}

/// save
- (void)saveLocationToCache {
    NSString *location = self.cLocation.stringValue;
    [[NSUserDefaults standardUserDefaults] setObject:location forKey:CacheKey];
}

/// 调用脚本
- (NSString *)performShellWithCoordinate:(Coordinate *)coor {
    
    NSTask *task = [[NSTask alloc] init];
    NSString *shellPath = [[NSBundle mainBundle] pathForResource:@"ChangeLocation" ofType:@"sh"];
    [task setLaunchPath:shellPath];
    [task setArguments:@[coor.latStr, coor.lngStr]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    NSFileHandle *handle = [pipe fileHandleForReading];
    [task launch];

    NSString *output = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    return output;
}

@end
