//
//  SVMapVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVMapVC.h"
#import "SVNavigationView.h"
#import "UIView+SV.h"
#import "UIButton+SV.h"
#import <MapKit/MapKit.h>
#import "SVNTools.h"
#import "SVMapInfoView.h"
#import "SVPosterManager.h"

@interface SVMapVC () <UIGestureRecognizerDelegate, GADFullScreenContentDelegate, GADNativeAdDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *annotation;
@property (nonatomic, strong) SVMapInfoView *infoView;
@property (nonatomic, strong) UIImageView *adBgImageView;

@property (nonatomic, strong, nullable) GADInterstitialAd *backInterstitial;
@property (nonatomic, strong, nullable) GADNativeAdView *nativeAdView;
@property (nonatomic, strong, nullable) GADNativeAd *nativeAd;

@end

@implementation SVMapVC

- (void)didVC {
    [super didVC];
    [[SVPosterManager sharedInstance] enterMap];
    [self setupAdLoader];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    [[SVPosterManager sharedInstance] setupIsShow:NO type:SVAdvertLocationTypeMapNative];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"#202329"];
    SVNavigationView *navView = [[SVNavigationView alloc] init];
    navView.textLabel.text = @"Map";
    [navView.rightButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:navView];
    
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton nImage:[UIImage imageNamed:@"refresh"] hImage:nil];
    [refreshButton setEnlargeEdge:7];
    [refreshButton addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:refreshButton];
    [refreshButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-20);
        make.height.width.mas_equalTo(30);
        make.centerY.mas_equalTo(0);
    }];
    
    [self.view addSubview:self.mapView];
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navView.mas_bottom).offset(10);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.height.mas_equalTo(170);
    }];
    [self.mapView addAnnotation:self.annotation];
    
    self.infoView = [[SVMapInfoView alloc] init];
    [self.view addSubview:self.infoView];
    [self.infoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mapView.mas_bottom).offset(15);
        make.left.right.mas_equalTo(0);
    }];
    
    self.adBgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_bg"]];
    self.adBgImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.adBgImageView];
    [self.adBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.greaterThanOrEqualTo(self.infoView.mas_bottom).offset(5);
        make.height.mas_lessThanOrEqualTo(245);
        make.bottom.mas_equalTo(-SVBottom());
    }];
    
    [self configureMap];
}

- (void)configureMap {
    __weak typeof(self) weakSelf = self;
    [SVNTools locationCoordinateWithComplete:^(BOOL isSuccess, SVNetInfoModel * _Nullable model) {
        if (isSuccess) {
            CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(model.latitude, model.longitude);
            MKCoordinateSpan span = MKCoordinateSpanMake(0.1, 0.1); // 视野范围，数值越小显示的区域越小
            MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
            [weakSelf.mapView setRegion:region animated:YES];
            weakSelf.annotation.coordinate = centerCoordinate;
            [weakSelf.mapView setNeedsDisplay];
            [weakSelf.infoView setModel:model];
        }
    }];
}

- (void)displayAdvert {
    [SVStatisticAnalysis saveEvent:@"scene_bk" params:@{@"type": @"map"}];
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
    SVAdvertLocationType type = SVAdvertLocationTypeMapNative;
    if ([manager isCanShowAdvertWithType:type]) {
        __weak typeof(self) weakSelf = self;
        [manager syncRequestNativeAdWithType:type complete:^(BOOL isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf == nil) return;
                if (isSuccess) {
                    GADNativeAd *nativeAd = [SVPosterManager sharedInstance].mapAd;
                    [SVPosterManager sharedInstance].mapAd = nil;
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
    self.nativeAd.paidEventHandler = ^(GADAdValue * _Nonnull value) {
        [[SVPosterManager sharedInstance] paidAdWithValue:value];
    };
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

#pragma mark - action

- (void)refreshAction {
    [self configureMap];
}

- (void)backAction {
    [self displayAdvert];
}

#pragma mark - getter
- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.layer.cornerRadius = 10;
        _mapView.layer.masksToBounds = YES;
        _mapView.mapType = MKMapTypeStandard;
        _mapView.showsUserLocation = NO;
        _mapView.zoomEnabled = YES;
        _mapView.scrollEnabled = YES;
    }
    return _mapView;
}

- (MKPointAnnotation *)annotation {
    if (!_annotation) {
        _annotation = [[MKPointAnnotation alloc] init];
    }
    return _annotation;
}

#pragma mark - GADNativeAdDelegate

//1、
- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeMapNative];
}

//点击
- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeMapNative];
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
    [SVStatisticAnalysis saveEvent:@"show_bk" params:@{@"type": @"map"}];
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager advertLogFailedWithType:SVAdvertLocationTypeBack error:error.localizedDescription];
    self.backInterstitial = nil;
    [self jumpVCWithAnimated:YES];
}
@end
