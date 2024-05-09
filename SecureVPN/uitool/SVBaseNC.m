//
//  SVBaseNC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#import "SVBaseNC.h"

@interface SVBaseNC ()

@end

@implementation SVBaseNC

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.hidden = YES;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count != 1) {
        viewController.hidesBottomBarWhenPushed = NO;
    } else {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    if (self.viewControllers.count < 2) {
        [super setViewControllers:viewControllers animated:animated];
    } else {
        UIViewController *viewController = [self.viewControllers lastObject];
        viewController.hidesBottomBarWhenPushed = YES;
    }
}


@end
