//
//  SVConnectResultVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVConnectResultVC.h"
#import "SVNavigationView.h"
#import "UIView+SV.h"
#import "SVServerVC.h"
#import "SVMapVC.h"
#import "SVBrowserVC.h"
#import "SVPosterManager.h"

NSNotificationName const SVRetryConnectNoto = @"SVRetryConnectNoto";

@interface SVConnectResultVC () <UIGestureRecognizerDelegate, GADFullScreenContentDelegate, GADNativeAdDelegate>

@property (nonatomic, assign) SVVNResultStatus resultStatus;
@property (nonatomic, strong) UIImageView *adBgImageView;

@property (nonatomic, strong, nullable) GADInterstitialAd *backInterstitial;
@property (nonatomic, strong, nullable) GADNativeAdView *nativeAdView;
@property (nonatomic, strong, nullable) GADNativeAd *nativeAd;

@end

@implementation SVConnectResultVC

- (void)didVC {
    [super didVC];
    [[SVPosterManager sharedInstance] enterResult];
    [self setupAdLoader];
    if (self.resultStatus == SVVNResultStatusCollectSuccess) {
        [SVStatisticAnalysis saveEvent:@"result_show" params:@{@"type": @"connected"}];
    } else if (self.resultStatus == SVVNResultStatusCollectFail) {
        [SVStatisticAnalysis saveEvent:@"result_show" params:@{@"type": @"fail"}];
    } else {
        [SVStatisticAnalysis saveEvent:@"result_show" params:@{@"type": @"disconnected"}];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    [[SVPosterManager sharedInstance] setupIsShow:NO type:SVAdvertLocationTypeResultNative];
}

- (id)initWithStatus:(SVVNResultStatus)status {
    if (self = [super init]) {
        self.resultStatus = status;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"#202329"];
    SVNavigationView *navView = [[SVNavigationView alloc] init];
    navView.textLabel.text = @"Server";
    [navView.rightButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:navView];
    
    UIImageView *statusImageView = [[UIImageView alloc] init];
    [self.view addSubview:statusImageView];
    [statusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.width.mas_equalTo(295);
        make.height.mas_equalTo(153);
        if (SVScreenHeight() < 750) {
            make.top.equalTo(navView.mas_bottom).offset(0);
        } else {
            make.top.equalTo(navView.mas_bottom).offset(80);
        }
    }];
    
    UILabel *statusLabel = [[UILabel alloc] init];
    statusLabel.font = [UIFont fontWithSize:17 weight:UIFontWeightMedium];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:statusLabel];
    [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statusImageView.mas_bottom).offset(12);
        make.height.mas_equalTo(24);
        make.centerX.mas_equalTo(0);
    }];
    
    UIView *serverView = [[UIView alloc] init];
    [self.view addSubview:serverView];
    [serverView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statusLabel.mas_bottom).offset(10);
        make.centerX.mas_equalTo(0);
        make.height.mas_equalTo(30);
    }];
    
    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", self.model.countryCode]];
    [serverView addSubview:iconImageView];
    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.mas_equalTo(0);
        make.width.height.mas_equalTo(30);
    }];
    
    UILabel *nameLabel = [UILabel lbText:self.model.name font:[UIFont pFont:14] color:[UIColor whiteColor]];
    [serverView addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.left.equalTo(iconImageView.mas_right).offset(10);
    }];
    
    UIView *itemView = [[UIView alloc] init];
    [self.view addSubview:itemView];
    
    if (self.resultStatus == SVVNResultStatusCollectSuccess) {
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(statusLabel.mas_bottom).offset(70);
            make.left.right.mas_equalTo(0);
        }];
        statusImageView.image = [UIImage imageNamed:@"server_success"];
        statusLabel.text = @"Link Successful";
        statusLabel.textColor = [UIColor colorWithHexString:@"#5ABB7A"];
        UIView *webView = [self viewWithTitle:@"Private Browser" imageName:@"home_browser" watermarkName:@"server_web_bg" action:@selector(browserAction)];
        UIView *locationView = [self viewWithTitle:@"Check the location" imageName:@"home_map" watermarkName:@"server_map_bg" action:@selector(mapAction)];
        
        [itemView addSubview:webView];
        [itemView addSubview:locationView];
        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(80);
        }];
        
        [locationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(webView.mas_bottom).offset(15);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(80);
            make.bottom.mas_equalTo(0);
        }];
        
    } else if (self.resultStatus == SVVNResultStatusDisconnectSuccess){
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(statusLabel.mas_bottom).offset(70);
            make.left.right.mas_equalTo(0);
        }];
        statusImageView.image = [UIImage imageNamed:@"server_disconnect"];
        statusLabel.text = @"Successfully disconnected";
        statusLabel.textColor = [UIColor colorWithHexString:@"#66B9DE"];
        serverView.hidden = YES;
        UIView *locationView = [self viewWithTitle:@"Check the location" imageName:@"home_map" watermarkName:@"server_map_bg" action:@selector(mapAction)];
        UIView *routeView = [self viewWithTitle:@"Switch Routes" imageName:@"server_list" watermarkName:@"server_list_bg" action:@selector(routeAction)];
        
        [itemView addSubview:locationView];
        [itemView addSubview:routeView];
        [locationView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(80);
        }];
        
        [routeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(locationView.mas_bottom).offset(15);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(80);
            make.bottom.mas_equalTo(0);
        }];
    } else {
        [itemView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(statusLabel.mas_bottom).offset(99);
            make.left.right.mas_equalTo(0);
        }];
        statusImageView.image = [UIImage imageNamed:@"server_fail"];
        statusLabel.text = @"Link Failure";
        statusLabel.textColor = [UIColor colorWithHexString:@"#DB6775"];
        UIView *routeView = [self viewWithTitle:@"Switch Routes" imageName:@"server_list" watermarkName:@"server_list_bg" action:@selector(routeAction)];
        
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [retryButton setTitle:@"Retry" forState:UIControlStateNormal];
        retryButton.titleLabel.font = [UIFont fontWithSize:17 weight:UIFontWeightMedium];
        [retryButton tColor:[UIColor whiteColor]];
        [retryButton bgImage:[UIImage imageNamed:@"server_button_bg"]];
        [retryButton addTarget:self action:@selector(retryAction) forControlEvents:UIControlEventTouchUpInside];
        
        [itemView addSubview:routeView];
        [itemView addSubview:retryButton];
        [routeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.height.mas_equalTo(80);
        }];
        
        [retryButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(routeView.mas_bottom).offset(15);
            make.height.mas_equalTo(51);
            make.centerX.mas_equalTo(0);
            make.width.mas_equalTo(284);
            make.bottom.mas_equalTo(0);
        }];
    }
    
    self.adBgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_bg"]];
    self.adBgImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.adBgImageView];
    [self.adBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.greaterThanOrEqualTo(itemView.mas_bottom).offset(10);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_lessThanOrEqualTo(245);
        make.bottom.mas_equalTo(-SVBottom());
    }];
}

- (void)displayAdvert {
    [SVStatisticAnalysis saveEvent:@"scene_bk" params:@{@"type": @"result"}];
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeBack;
    if ([manager isCanShowAdvertWithType:type]) {
        if (manager.backInterstitial && [manager isCacheValidWithType:type]) {
            if (manager.isScreenAdShow) return;
            manager.isScreenAdShow = YES;
            self.backInterstitial = manager.backInterstitial;
            manager.backInterstitial = nil;
            self.backInterstitial.fullScreenContentDelegate = self;
            [self.backInterstitial presentFromRootViewController:self];
        } else {
            [self jumpVCWithAnimated:YES];
        }
    } else {
        [self jumpVCWithAnimated:YES];
    }
}

- (void)jumpVCWithAnimated:(BOOL)animated {
    [self.navigationController popViewControllerAnimated:animated];
}

- (void)setupAdLoader {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeResultNative;
    if ([manager isCanShowAdvertWithType:type]) {
        __weak typeof(self) weakSelf = self;
        [manager syncRequestNativeAdWithType:type complete:^(BOOL isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf == nil) return;
                if (isSuccess) {
                    GADNativeAd *nativeAd = [SVPosterManager sharedInstance].resultAd;
                    [SVPosterManager sharedInstance].resultAd = nil;
                    [weakSelf addNativeViewWithNativeAd:nativeAd];
                }
            });
        }];
    } else {
        if (!self.adBgImageView.isHidden) {
            if ([manager isShowLimt:type]) {
                self.adBgImageView.hidden = YES;
            }
        }
    }
}

- (void)addNativeViewWithNativeAd:(GADNativeAd *)nativeAd {
    if (self.nativeAdView) {
        [self.nativeAdView removeFromSuperview];
        self.nativeAdView = nil;
    }
    
    nativeAd.delegate = self;
    self.nativeAd = nativeAd;
    GADNativeAdView *nativeAdView = [[NSBundle mainBundle] loadNibNamed:@"NativeAdView" owner:nil options:nil].firstObject;
    self.nativeAdView = nativeAdView;
    
    nativeAdView.mediaView.mediaContent = nativeAd.mediaContent;
    nativeAdView.mediaView.contentMode = UIViewContentModeScaleAspectFill;
    ((UILabel *)(nativeAdView.headlineView)).text = nativeAd.headline;
    
    ((UILabel *)nativeAdView.bodyView).text = nativeAd.body;
    nativeAdView.bodyView.hidden = nativeAd.body ? NO : YES;
    
    [((UIButton *)nativeAdView.callToActionView) setTitle:nativeAd.callToAction forState:UIControlStateNormal];
    nativeAdView.callToActionView.hidden = nativeAd.callToAction ? NO : YES;
    
    ((UIImageView *)nativeAdView.iconView).image = nativeAd.icon.image;
    nativeAdView.iconView.hidden = nativeAd.icon ? NO : YES;

//    ((UIImageView *)nativeAdView.starRatingView).image = [self imageForStars:nativeAd.starRating];
//    nativeAdView.starRatingView.hidden = nativeAd.starRating ? NO : YES;

    ((UILabel *)nativeAdView.storeView).text = nativeAd.store;
    nativeAdView.storeView.hidden = nativeAd.store ? NO : YES;

    ((UILabel *)nativeAdView.priceView).text = nativeAd.price;
    nativeAdView.priceView.hidden = nativeAd.price ? NO : YES;

    ((UILabel *)nativeAdView.advertiserView).text = nativeAd.advertiser;
    nativeAdView.advertiserView.hidden = nativeAd.advertiser ? NO : YES;
    
    nativeAdView.callToActionView.userInteractionEnabled = NO;
    nativeAdView.nativeAd = nativeAd;
    
    [self.adBgImageView addSubview:nativeAdView];
    [nativeAdView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
}

- (UIView *)viewWithTitle:(NSString *)title imageName:(NSString *)imageName watermarkName:(NSString *)watermarkName action:(SEL)action {
    UIView *barView = [[UIView alloc] init];
    barView.userInteractionEnabled = YES;
    barView.backgroundColor = [UIColor colorWithHexString:@"#37393F"];
    barView.layer.cornerRadius = 10;
    barView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    [barView addGestureRecognizer:tap];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    [barView addSubview:iconImageView];
    [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
//        make.width.height.mas_equalTo(50);
        make.centerY.mas_equalTo(0);
    }];
    
    UILabel *label = [UILabel lbText:title font:[UIFont pFont:16] color:[UIColor whiteColor]];
    [barView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(75);
        make.centerY.mas_equalTo(0);
    }];
    
    UIImageView *watermarkImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:watermarkName]];
    [barView addSubview:watermarkImageView];
    [watermarkImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.centerY.mas_equalTo(0);
        make.width.height.mas_equalTo(80);
    }];
    
    return barView;
}

#pragma mark - action
- (void)browserAction {
    [SVStatisticAnalysis saveEvent:@"browse_show" params:@{@"from": @"result"}];
    SVBrowserVC *vc = [[SVBrowserVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)mapAction {
    [SVStatisticAnalysis saveEvent:@"map_show" params:@{@"from": @"result"}];
    SVMapVC *vc = [[SVMapVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)routeAction {
    NSMutableArray *array = [self.navigationController.viewControllers mutableCopy];
    if (array.count > 1) {
        [array removeLastObject];
        SVServerVC *vc = [[SVServerVC alloc] initWithModel:self.model];
        [array addObject:vc];
        [self.navigationController setViewControllers:array animated:YES];
    }
}

- (void)retryAction {
    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:SVRetryConnectNoto object:nil];
}

- (void)backAction {
    [self displayAdvert];
}

#pragma mark - GADNativeAdDelegate

//1、
- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeResultNative];
    self.nativeAd.paidEventHandler = ^(GADAdValue * _Nonnull value) {
        [[SVPosterManager sharedInstance] paidAdWithValue:value];
    };
}

//点击
- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeResultNative];
}


#pragma  mark - UINavigationControllerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    if ([manager isCanShowAdvertWithType:SVAdvertLocationTypeBack] && manager.backInterstitial) {
        [self displayAdvert];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - GADFullScreenContentDelegate
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *advert = (GADInterstitialAd *)ad;
    advert.paidEventHandler = ^(GADAdValue * _Nonnull value) {
        [[SVPosterManager sharedInstance] paidAdWithValue:value];
    };
}

//这里用将要消失
- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    self.backInterstitial = nil;
    [manager setupIsShow:NO type:SVAdvertLocationTypeBack];
    [self jumpVCWithAnimated:NO];
}

//3 点击
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库点击次数
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeBack];
}

//1 将要展示
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库展示次数
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeBack];
    [SVStatisticAnalysis saveEvent:@"show_bk" params:@{@"type": @"result"}];
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager advertLogFailedWithType:SVAdvertLocationTypeBack error:error.localizedDescription];
    self.backInterstitial = nil;
    [self jumpVCWithAnimated:YES];
}

@end
