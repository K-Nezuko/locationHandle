//
//  Location.h
//  locationHandle
//
//  Created by Dream on 2019/12/3.
//

#import <Foundation/Foundation.h>
#import "Coordinate.h"

NS_ASSUME_NONNULL_BEGIN

@interface Location : NSObject

/// 单例
+ (instancetype)shareInstance;

/// 移动到新的位置
/// @param newLocation 新的位置坐标(系统坐标)
/// @return 正确执行时, 返回nil; 否则返回错误信息
- (nullable NSString *)moveToNewLocation:(Coordinate *)newLocation;

@property (strong, readonly) Coordinate *cLocation;

@end

NS_ASSUME_NONNULL_END
