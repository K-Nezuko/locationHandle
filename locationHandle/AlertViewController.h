//
//  AlertViewController.h
//  locationHandle
//
//  Created by Dream on 2019/12/3.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AlertViewController : NSViewController

@property (nonatomic, copy) void(^completeBlock)(NSString *cTitle);

@end

NS_ASSUME_NONNULL_END
