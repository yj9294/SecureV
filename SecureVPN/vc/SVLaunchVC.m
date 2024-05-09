//
//  SVLaunchVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVLaunchVC.h"
#import "Masonry/Masonry.h"
#import "SecureVPN-Swift.h"

@interface SVLaunchVC ()

@end

@implementation SVLaunchVC

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_bg"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:bgImageView];
    [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_logo"]];
    [self.view addSubview:logoImageView];
    [logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(175);
        make.centerX.mas_equalTo(0);
        make.width.height.mas_equalTo(120);
    }];
    
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_secure_vpn"]];
    [self.view addSubview:titleImageView];
    [titleImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logoImageView.mas_bottom).offset(30);
        make.width.mas_equalTo(246);
        make.height.mas_equalTo(27);
        make.centerX.mas_equalTo(0);
    }];
    
    LottieAnimationView *animationView = [LottieTools getLottieViewWith:@"launch" count:-1];
    UIView *view = (UIView *)animationView;
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleImageView.mas_bottom).offset(82);
        make.width.height.mas_equalTo(100);
        make.centerX.mas_equalTo(0);
    }];
    [LottieTools playWithAnView:animationView];
}

@end
