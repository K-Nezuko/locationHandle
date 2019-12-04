//
//  AlertViewController.m
//  locationHandle
//
//  Created by Dream on 2019/12/3.
//

#import "AlertViewController.h"

@interface AlertViewController ()

@property (weak) IBOutlet NSTextField *titleTf;

@end

@implementation AlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)cancleAction:(id)sender {
    [self dismissViewController:self];
}

- (IBAction)completeAction:(NSButton *)sender {
    NSString *cTitle = self.titleTf.stringValue;
    if (cTitle.length != 0 && self.completeBlock) {
        self.completeBlock(cTitle);
        [self dismissViewController:self];
    }
}

@end
