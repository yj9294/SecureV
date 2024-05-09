//
//  SVNavigationView.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import "SVNavigationView.h"
#import "UIView+SV.h"
#import "UIButton+SV.h"

@implementation SVNavigationView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.frame = CGRectMake(0, SVStatusHeight(), SVScreenWidth(), 44);
    
    self.textLabel = [UILabel lbText:@"" font:[UIFont fontWithSize:17 weight:UIFontWeightMedium] color:[UIColor whiteColor]];
    [self addSubview:self.textLabel];
    [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.centerX.mas_equalTo(0);
    }];
    
    self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightButton nImage:[UIImage imageNamed:@"back"] hImage:nil];
    [self.rightButton setEnlargeEdge:10];
    
//        [self.rightButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.rightButton];
    [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.height.width.mas_equalTo(24);
        make.centerY.mas_equalTo(0);
    }];
}

//- (void)backAction {
//    if (self.viewController.navigationController.viewControllers.count <= 1) {
//        [self.viewController dismissViewControllerAnimated:YES completion:nil];
//    } else {
//        [self.viewController.navigationController popViewControllerAnimated:YES];
//    }
//}

@end
