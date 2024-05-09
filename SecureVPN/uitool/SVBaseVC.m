//
//  SVBaseVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/1.
//

#import "SVBaseVC.h"


typedef NS_ENUM(NSUInteger, SVViewControllerStatus) {
    SVViewControllerStatusWillAppear = 0,
    SVViewControllerStatusDidAppear,
    SVViewControllerStatusWillDisappear,
    SVViewControllerStatusDidDisappear
};

@interface SVBaseVC () {
    SVViewControllerStatus __vcStatus;
}
@end

@implementation SVBaseVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __vcStatus = SVViewControllerStatusWillAppear;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.vcIsDid) {
        self.vcIsDid = YES;
        if (self.vcIsShowAding) {
            self.vcIsShowAding = NO;
        } else {
            [self didVC];
        }
    }
    __vcStatus = SVViewControllerStatusDidAppear;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (__vcStatus == SVViewControllerStatusWillAppear && self.vcIsShowAding) {
        self.vcIsShowAding = NO;
    }
    __vcStatus = SVViewControllerStatusWillDisappear;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.vcIsDid) {
        self.vcIsDid = NO;
        __vcStatus = SVViewControllerStatusDidDisappear;
    } else {
        __vcStatus = SVViewControllerStatusDidDisappear;
    }
}

- (void)didVC {
    NSString *text = @"did vc complete appear";
    NSMutableString *newText = [NSMutableString stringWithFormat:@"new %@", text];
    [newText appendString:@"end"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self __setupUI];
}

- (void)__setupUI {
    self.vcIsDid = NO;
    self.vcIsShowAding = NO;
}

@end
