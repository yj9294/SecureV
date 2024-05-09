//
//  SVHomeVC.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import "SVHomeVC.h"
#import "UIView+SV.h"
#import "SVHomeBarView.h"
#import "UIButton+SV.h"
#import "SVNManager.h"
#import "SVNTools.h"
#import "SVTools.h"
#import "SVHomePop.h"
#import "SVBrowserVC.h"
#import "SVMapVC.h"
#import "SVServerVC.h"
#import "SVConnectResultVC.h"
#import "BHBNetworkSpeed.h"
#import "SVPosterManager.h"

typedef NS_ENUM(NSUInteger, SVHomeVNStatus) {
    SVHomeVNStatusDisconnected = 0,
    SVHomeVNStatusConnected,
    SVHomeVNStatusLoading
};

typedef NS_ENUM(NSUInteger, SVHomeJumpType) {
    SVHomeJumpTypeServer = 0,
    SVHomeJumpTypeBrowser,
    SVHomeJumpTypeMap,
    SVHomeJumpTypeNone
};

@interface SVHomeVC () <GADFullScreenContentDelegate, GADNativeAdDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) SVHomeBarView *barView;
@property (nonatomic, strong) UIButton *vnButton;
@property (nonatomic, strong) UILabel *upLabel;
@property (nonatomic, strong) UILabel *downLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *adBgImageView;
@property (nonatomic, assign) SVHomeVNStatus vnStatus;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, assign) NSUInteger connectDuration;
//打开vpn时是否需要展示广告，防止vpn状态多次变成已连接，导致广告多次加载
@property (nonatomic, assign) BOOL isNeedShowVpnAd;
//控制是否显示结果页面
@property (nonatomic, assign) BOOL isShowResult;
//是否是打开vpn操作
@property (nonatomic, assign) BOOL isVpnOpen;
//是否需要断开
@property (nonatomic, assign) BOOL isNeedDisconnect;
//断开后，是否需要重连
@property (nonatomic, assign) BOOL isReconnect;

@property (nonatomic, strong, nullable) GADInterstitialAd *vpnInterstitial;
@property (nonatomic, strong, nullable) GADInterstitialAd *clickInterstitial;
@property (nonatomic, strong, nullable) GADNativeAdView *nativeAdView;
@property (nonatomic, strong, nullable) GADNativeAd *nativeAd;
@property (nonatomic, assign) SVHomeJumpType jumpType;

@end

@implementation SVHomeVC

- (void)didVC {
    [super didVC];
    [[SVPosterManager sharedInstance] enterHome];
    [self setupAdLoader];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[SVPosterManager sharedInstance] setupIsShow:NO type:SVAdvertLocationTypeHomeNative];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.jumpType = SVHomeJumpTypeNone;
    self.isReconnect = NO;
    self.view.backgroundColor = [UIColor colorWithHexString:@"#202329"];
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = self.scrollView.backgroundColor;
    [self.scrollView addSubview:bgView];
    
    UIImageView *titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_title"]];
    [bgView addSubview:titleImageView];
    [titleImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(SVStatusHeight() + 14);
        make.left.mas_equalTo(20);
        make.width.mas_equalTo(144);
        make.height.mas_equalTo(16);
    }];
    
    UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_net_bg"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [bgView addSubview:bgImageView];
    
    self.adBgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_bg"]];
    self.adBgImageView.userInteractionEnabled = YES;
    
    //判断高是否小于750
    if (SVScreenHeight() < 750) {
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleImageView.mas_bottom).offset(14);
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(529);
        }];
        
        [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.mas_equalTo(0);
            make.width.mas_equalTo(SVScreenWidth());
            make.height.mas_equalTo(896);
        }];
        
        [self.view addSubview:self.adBgImageView];
        [self.adBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.bottom.mas_equalTo(-SVBottom());
            make.height.mas_equalTo(245);
        }];
    } else {
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleImageView.mas_bottom).offset(14);
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(529);
        }];
        
        [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.mas_equalTo(0);
            make.width.mas_equalTo(SVScreenWidth());
            make.height.mas_equalTo(SVScreenHeight());
        }];
        
        [bgView addSubview:self.adBgImageView];
        [self.adBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.top.greaterThanOrEqualTo(bgImageView.mas_bottom).offset(0);
            make.bottom.mas_equalTo(-SVBottom());
            make.height.mas_lessThanOrEqualTo(245);
        }];
    }
    
    self.barView = [[SVHomeBarView alloc] init];
    [self.barView addTarget:self action:@selector(barAction) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:self.barView];
    [self.barView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleImageView.mas_bottom).offset(34);
        make.centerX.mas_equalTo(0);
        make.width.mas_equalTo(330);
        make.height.mas_equalTo(50);
    }];
    
    self.vnButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.vnButton setBackgroundImage:[UIImage imageNamed:@"home_net_close"] forState:UIControlStateNormal];
    [self.vnButton addTarget:self action:@selector(vnAction) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:self.vnButton];
    [self.vnButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.barView.mas_bottom).offset(20);
        make.centerX.mas_equalTo(0);
        make.width.height.mas_equalTo(170);
    }];
    
    UIImageView *downImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_net_download"]];
    [bgView addSubview:downImageView];
    [downImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vnButton.mas_bottom).offset(33);
        make.left.mas_equalTo(40);
        make.width.height.mas_equalTo(26);
    }];
    
    self.downLabel = [UILabel lbText:@"0 Mbps" font:[UIFont fontWithSize:16 weight:UIFontWeightMedium] color:[UIColor whiteColor]];
    [bgView addSubview:self.downLabel];
    [self.downLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(downImageView);
        make.left.equalTo(downImageView.mas_right).offset(5);
    }];
    
    UIImageView *upImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_net_upload"]];
    [bgView addSubview:upImageView];
    [upImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(downImageView);
        make.right.mas_equalTo(-103);
        make.width.height.mas_equalTo(26);
    }];
    
    self.upLabel = [UILabel lbText:@"0 Mbps" font:[UIFont fontWithSize:16 weight:UIFontWeightMedium] color:[UIColor whiteColor]];
    [bgView addSubview:self.upLabel];
    [self.upLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(downImageView);
        make.left.equalTo(upImageView.mas_right).offset(5);
    }];
    
    self.timeLabel = [UILabel lbText:@"00 : 00 : 00" font:[UIFont fontWithSize:26 weight:UIFontWeightSemibold] color:[UIColor colorWithHexString:@"#63B7E0"]];
    [bgView addSubview:self.timeLabel];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(downImageView.mas_bottom).offset(16);
        make.centerX.mas_equalTo(0);
    }];
    
    UILabel *connectionLabel = [UILabel lbText:@"connection time" font:[UIFont fontWithSize:14 weight:UIFontWeightLight] color:[[UIColor whiteColor] colorWithAlphaComponent:0.6]];
    [bgView addSubview:connectionLabel];
    [connectionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.timeLabel.mas_bottom).offset(5);
        make.centerX.mas_equalTo(0);
    }];
    
    UIButton *browserButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [browserButton setTitle:@"Browser" forState:UIControlStateNormal];
    browserButton.titleLabel.font = [UIFont pFont:16];
    [browserButton tColor:[UIColor whiteColor]];
    [browserButton nImage:[UIImage imageNamed:@"home_browser"] hImage:nil];
    [browserButton layoutWithType:LXButtonLayoutTypeImageTop subMargin:10];
    [browserButton bgImage:[UIImage imageNamed:@"home_browser_bg"]];
    [browserButton addTarget:self action:@selector(browserAction) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:browserButton];
    [browserButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(connectionLabel.mas_bottom).offset(20);
        make.left.mas_equalTo(20);
        make.width.mas_equalTo(167);
        make.height.mas_equalTo(97);
    }];
    
    UIButton *mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mapButton setTitle:@"Map" forState:UIControlStateNormal];
    mapButton.titleLabel.font = [UIFont pFont:16];
    [mapButton tColor:[UIColor whiteColor]];
    [mapButton nImage:[UIImage imageNamed:@"home_map"] hImage:nil];
    [mapButton layoutWithType:LXButtonLayoutTypeImageTop subMargin:10];
    [mapButton bgImage:[UIImage imageNamed:@"home_map_bg"]];
    [mapButton addTarget:self action:@selector(mapAction) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:mapButton];
    [mapButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-20);
        make.centerY.equalTo(browserButton);
        make.width.mas_equalTo(167);
        make.height.mas_equalTo(97);
    }];
    
    if ([SVTools isLimitCountry]) {
        [self showPop];
    } else {
        [UIView sv_showLoading:@"loading..."];
        [SVNTools isChina:^(BOOL result) {
            [UIView sv_hideLoading];
            if (result) {
                [self showPop];
            } else {
                [self setupVPN];
            }
        }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - privacy method

- (void)updateUIWithStatus:(SVHomeVNStatus)status; {
    self.vnStatus = status;
    svdispatch_async_main_safe(^{
        switch (status) {
            case SVHomeVNStatusDisconnected: {
                [self.vnButton setBackgroundImage:[UIImage imageNamed:@"home_net_close"] forState:UIControlStateNormal];
                [self stopAnimation];
                [UIView sv_hideLoading];
            }
                break;
            case SVHomeVNStatusConnected: {
                [self.vnButton setBackgroundImage:[UIImage imageNamed:@"home_net_open"] forState:UIControlStateNormal];
                [self stopAnimation];
                [UIView sv_hideLoading];
            }
                break;
            case SVHomeVNStatusLoading: {
                [self.vnButton setBackgroundImage:[UIImage imageNamed:@"home_loading_bg"] forState:UIControlStateNormal];
                [self startAnimation];
                [UIView sv_showLoading:@"Please wait for completion."];
            }
                break;
            default:
                break;
        }
    });
}

- (void)startAnimation {
    [self.vnButton.imageView.layer removeAllAnimations];
    [self.vnButton setImage:[UIImage imageNamed:@"home_loading"] forState:UIControlStateNormal];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = @(M_PI * 2.0);
    animation.duration = 1.5;
    animation.autoreverses = NO;
    animation.repeatCount = INFINITY;
    [self.vnButton.imageView.layer addAnimation:animation forKey:@"loadingAnimation"];
}

- (void)stopAnimation {
    [self.vnButton.imageView.layer removeAllAnimations];
    [self.vnButton setImage:nil forState:UIControlStateNormal];
}

- (void)showPop {
    [SVStatisticAnalysis saveEvent:@"loc_ban" params:nil];
    SVHomePop *pop = [[SVHomePop alloc] init];
    [pop showWithComplete:^{
        exit(0);
    }];
}

- (void)setupVPN {
    [SVStatisticAnalysis setAttributeWithInfo:@"n" name:@"v_state"];
    // 放前面防止消息丢失
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:VNConnectionStatusNoto object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        NEVPNStatus status = [notification.object integerValue];
        switch (status) {
            case NEVPNStatusInvalid:
                [weakSelf updateUIWithStatus:SVHomeVNStatusDisconnected];
                break;
            case NEVPNStatusDisconnected:
                [weakSelf stopTimer];
                [SVStatisticAnalysis setAttributeWithInfo:@"n" name:@"v_state"];
                if (weakSelf.isNeedDisconnect) {
                    [SVStatisticAnalysis saveEvent:@"v_disconnect" params:nil];
                    weakSelf.isNeedDisconnect = NO;
                    //跳转
                    [weakSelf jumpResultVCWithStatus:SVVNResultStatusDisconnectSuccess];
                }
                [weakSelf updateUIWithStatus:SVHomeVNStatusDisconnected];
                
                if (weakSelf.isReconnect) {
                    weakSelf.isReconnect = NO;
                    weakSelf.isShowResult = YES;
                    [weakSelf vnConnect];
                }
                break;
            case NEVPNStatusConnecting:
                [weakSelf updateUIWithStatus:SVHomeVNStatusLoading];
                break;
            case NEVPNStatusConnected:
                [weakSelf startTimer];
                [SVStatisticAnalysis setAttributeWithInfo:@"y" name:@"v_state"];
                [SVStatisticAnalysis saveEvent:@"v_connect" params:nil];
                if (weakSelf.isNeedShowVpnAd) {
                    weakSelf.isNeedShowVpnAd = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        weakSelf.isVpnOpen = YES;
                        [weakSelf showVpnAdWithIsOpen:YES];
                    });
                } else {
                    if (self.isShowResult) {
                        self.isShowResult = NO;
                        [self jumpResultVCWithStatus:SVVNResultStatusCollectSuccess];
                    }
                    [weakSelf updateUIWithStatus:SVHomeVNStatusConnected];
                }
                break;
            case NEVPNStatusDisconnecting:
                [weakSelf updateUIWithStatus:SVHomeVNStatusLoading];
                break;
            case NEVPNStatusReasserting:
                [weakSelf updateUIWithStatus:SVHomeVNStatusLoading];
                break;
            default:
                break;
        }
    }];
    
    //监听通知
    //重连
    [[NSNotificationCenter defaultCenter] addObserverForName:SVRetryConnectNoto object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [weakSelf vnAction];
    }];
    
    //通知连接
    [[NSNotificationCenter defaultCenter] addObserverForName:SVVNConnectNoto object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        SVServerModel *model = notification.object;
        weakSelf.barView.model = model;
        if ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected) {
            [[SVNManager sharedInstance] stopVPN];
            weakSelf.isReconnect = YES;
        } else {
            weakSelf.isShowResult = YES;
            [weakSelf vnConnect];
        }
    }];
    
    //接受速度
    [[NSNotificationCenter defaultCenter] addObserverForName:kNetworkReceivedSpeedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        if ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected) {
            weakSelf.downLabel.text = [BHBNetworkSpeed shareNetworkSpeed].receivedNetworkSpeed;
        } else {
            weakSelf.downLabel.text = @"0 Mbps";
        }
    }];
    
    //发送速度
    [[NSNotificationCenter defaultCenter] addObserverForName:kNetworkSendSpeedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        if ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected) {
            weakSelf.upLabel.text = [BHBNetworkSpeed shareNetworkSpeed].sendNetworkSpeed;
        } else {
            weakSelf.upLabel.text = @"0 Mbps";
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:VNConnectFailNoto object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {        
        if (weakSelf.isShowResult) {
            weakSelf.isShowResult = NO;
            [weakSelf jumpResultVCWithStatus:SVVNResultStatusCollectFail];
        }
    }];
    
    //初始化
    [BHBNetworkSpeed shareNetworkSpeed].intervalTime = 3;
    [[BHBNetworkSpeed shareNetworkSpeed] startMonitoringNetworkSpeed];
    
    //配置vpn
    [[SVNManager sharedInstance] configureWithComplete:^(BOOL isSuccess) {
        [weakSelf configreServerInfo];
    }];
}

- (void)configreServerInfo {
    //判断是否有连接或者正在连接的ip
    NEVPNStatus status = [SVNManager sharedInstance].vnStatus;
    if (status == NEVPNStatusDisconnected || status == NEVPNStatusInvalid) {
        //随机取一个
        SVServerModel *model = [SVNTools randomServer];
        model.name = @"Auto Server";
        model.countryCode = @"auto";
        self.barView.model = [SVNTools randomServer];
        
        NSString *string = [[NSUserDefaults standardUserDefaults] stringForKey:@"firstEnterHome"];
        if (string.length == 0){
            [[NSUserDefaults standardUserDefaults] setObject:@"firstEnterHome" forKey:@"firstEnterHome"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self vnAction];
        }
    } else {
        //获取ip
        NSString *ip = [SVNManager sharedInstance].profile.serverAddress;
        if (ip.length > 0) {
            __weak typeof(self) weakSelf = self;
            [SVNTools getServerWithIp:ip complete:^(SVServerModel * _Nullable model) {
                if (model) {
                    weakSelf.barView.model = model;
                }
            }];
        }
    }
}

- (void)vnConnect {
    [SVStatisticAnalysis saveEvent:@"start_connect" params:@{@"type": self.barView.model.countryCode}];
    [SVNManager sharedInstance].profile.serverAddress = self.barView.model.ip;
    [[SVNManager sharedInstance] startVPN];
    [[SVPosterManager sharedInstance] tripVpn];
}

- (void)startTimer {
    if (self.connectTimer == nil) {
        svdispatch_async_main_safe(^{
            __weak typeof(self) weakSelf = self;
            self.connectDuration = 0;
            weakSelf.connectTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:weakSelf.connectTimer forMode:NSRunLoopCommonModes];
        });
    }
}

- (void)stopTimer {
    if ([self.connectTimer isValid]) {
        [self.connectTimer invalidate];
    }
    self.connectDuration = 0;
    self.connectTimer = nil;
    svdispatch_async_main_safe(^{
        self.timeLabel.text = @"00 : 00 : 00";
    });
}

- (void)setupAdLoader {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeHomeNative;
    if ([manager isCanShowAdvertWithType:type]) {
        __weak typeof(self) weakSelf = self;
        [manager syncRequestNativeAdWithType:type complete:^(BOOL isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf == nil) return;
                if (isSuccess) {
                    GADNativeAd *nativeAd = [SVPosterManager sharedInstance].homeAd;
                    [SVPosterManager sharedInstance].homeAd = nil;
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

#pragma mark - action

- (void)timerAction:(NSTimer *)timer {
    self.connectDuration += 1;
    NSInteger hours = (NSInteger)self.connectDuration / 3600;
    NSInteger minutes = ((NSInteger)self.connectDuration % 3600) / 60;
    NSInteger seconds = (NSInteger)self.connectDuration % 60;
    self.timeLabel.text = [NSString stringWithFormat:@"%02ld : %02ld : %02ld", hours, minutes, seconds];
}

- (void)barAction {
    self.jumpType = SVHomeJumpTypeServer;
    [self displayAdvert];
}

- (void)vnAction {
    SVHomeVNStatus status = self.vnStatus;
    if (status == SVHomeVNStatusConnected) {
        [SVStatisticAnalysis saveEvent:@"start_disconnect" params:nil];
        [self updateUIWithStatus:SVHomeVNStatusLoading];
        self.isVpnOpen = NO;
        self.isNeedDisconnect = YES;
        [self showVpnAdWithIsOpen:NO];
        [[SVPosterManager sharedInstance] tripVpn];
    } else if (status == SVHomeVNStatusDisconnected) {
        self.isNeedShowVpnAd = YES;
        self.isShowResult = YES;
        [self vnConnect];
    }
}

- (void)browserAction {
    self.jumpType = SVHomeJumpTypeBrowser;
    [self displayAdvert];
}

- (void)mapAction {
    self.jumpType = SVHomeJumpTypeMap;
    [self displayAdvert];
}

- (void)jumpResultVCWithStatus:(SVVNResultStatus)status {
    SVConnectResultVC *vc = [[SVConnectResultVC alloc] initWithStatus:status];
    vc.model = self.barView.model;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpVCWithAnimated:(BOOL)animated {
    UIViewController *vc = nil;
    if (self.jumpType == SVHomeJumpTypeServer) {
        vc = [[SVServerVC alloc] initWithModel:self.barView.model];
    } else if (self.jumpType == SVHomeJumpTypeBrowser) {
        [SVStatisticAnalysis saveEvent:@"browse_show" params:@{@"from": @"home"}];
        vc = [[SVBrowserVC alloc] init];
    } else if (self.jumpType == SVHomeJumpTypeMap) {
        [SVStatisticAnalysis saveEvent:@"map_show" params:@{@"from": @"home"}];
        vc = [[SVMapVC alloc] init];
    }
    if (vc) {
        [self.navigationController pushViewController:vc animated:animated];
    }
    self.jumpType = SVHomeJumpTypeNone;
}

- (void)showVpnAdWithIsOpen:(BOOL)isOpen {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeVpn;
    if ([manager isCanShowAdvertWithType:type]) {
        if (manager.vpnInterstitial && [manager isCacheValidWithType:type]) {
            if (manager.isScreenAdShow) {
                [self updateVnUIWithIsOpen:isOpen];
                return;
            }
            manager.isScreenAdShow = YES;
            [self showVpnAd];
        } else {
            __weak typeof(self) weakSelf = self;
            [manager syncRequestScreenAdWithType:type timeout:16 complete:^(BOOL isSuccess) {
                if (isSuccess) {
                    if (manager.isScreenAdShow) {
                        [weakSelf updateVnUIWithIsOpen:isOpen];
                        return;
                    }
                    [SVPosterManager sharedInstance].isScreenAdShow = YES;
                    [weakSelf showVpnAd];
                } else {
                    [weakSelf updateVnUIWithIsOpen:isOpen];
                }
            }];
        }
    } else {
        [self updateVnUIWithIsOpen:isOpen];
    }
}

- (void)showVpnAd {
    [SVStatisticAnalysis saveEvent:@"scene_conn" params:nil];
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    self.vpnInterstitial = manager.vpnInterstitial;
    manager.vpnInterstitial = nil;
    self.vpnInterstitial.fullScreenContentDelegate = self;
    [self.vpnInterstitial presentFromRootViewController:self];
}

- (void)updateVnUIWithIsOpen:(BOOL)isOpen {
    if (isOpen) {
        [self updateUIWithStatus:SVHomeVNStatusConnected];
        if (self.isShowResult) {
            self.isShowResult = NO;
            [self jumpResultVCWithStatus:SVVNResultStatusCollectSuccess];
        }
    } else {
        [[SVNManager sharedInstance] stopVPN];
    }
}

- (void)displayAdvert {
    if (self.jumpType == SVHomeJumpTypeServer) {
        [SVStatisticAnalysis saveEvent:@"scene_click" params:@{@"type": @"server"}];
    } else if (self.jumpType == SVHomeJumpTypeBrowser) {
        [SVStatisticAnalysis saveEvent:@"scene_click" params:@{@"type": @"browser"}];
    } else {
        [SVStatisticAnalysis saveEvent:@"scene_click" params:@{@"type": @"map"}];
    }
    
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    SVAdvertLocationType type = SVAdvertLocationTypeClick;
    if ([manager isCanShowAdvertWithType:type]) {
        if (manager.clickInterstitial && [manager isCacheValidWithType:type]) {
            if (manager.isScreenAdShow) return;
            manager.isScreenAdShow = YES;
            self.clickInterstitial = manager.clickInterstitial;
            manager.clickInterstitial = nil;
            self.clickInterstitial.fullScreenContentDelegate = self;
            [self.clickInterstitial presentFromRootViewController:self];
        } else {
            [self jumpVCWithAnimated:YES];
        }
    } else {
        [self jumpVCWithAnimated:YES];
    }
}

- (SVAdvertLocationType)getCurrentInterstitialTypeWithAd:(id)ad {
    SVAdvertLocationType type = SVAdvertLocationTypeUnknow;
    if (ad == self.vpnInterstitial) {
        type = SVAdvertLocationTypeVpn;
    } else if (ad == self.clickInterstitial) {
        type = SVAdvertLocationTypeClick;
    }
    return type;
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
    
    UILabel *headlineView = (UILabel *)nativeAdView.headlineView;
    headlineView.text = nativeAd.headline;
    headlineView.font = [UIFont fontWithSize:14 weight:UIFontWeightMedium];
    
    UILabel *bodyView = (UILabel *)nativeAdView.bodyView;
    bodyView.text = nativeAd.body;
    bodyView.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    bodyView.font = [UIFont fontWithSize:12];
    bodyView.hidden = nativeAd.body ? NO : YES;
    
    UIButton *callToActionView = (UIButton *)nativeAdView.callToActionView;
    [callToActionView setTitle:nativeAd.callToAction forState:UIControlStateNormal];
    callToActionView.titleLabel.font = [UIFont fontWithSize:16 weight:UIFontWeightMedium];
    callToActionView.hidden = nativeAd.callToAction ? NO : YES;
    
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

#pragma mark - GADNativeAdDelegate

//1、
- (void)nativeAdDidRecordImpression:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeHomeNative];
}

//点击
- (void)nativeAdDidRecordClick:(nonnull GADNativeAd *)nativeAd {
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeHomeNative];
}

#pragma mark - GADFullScreenContentDelegate
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    GADInterstitialAd *advert = (GADInterstitialAd *)ad;
    advert.paidEventHandler = ^(GADAdValue * _Nonnull value) {
        [[SVPosterManager sharedInstance] paidAdWithValue:value];
    };
}

//5 已经消失
//- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
//
//}

- (void)adWillDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    SVAdvertLocationType type = [self getCurrentInterstitialTypeWithAd:ad];
    [manager setupIsShow:NO type:type];
    if (type == SVAdvertLocationTypeVpn) {
        self.vpnInterstitial = nil;
        [self updateVnUIWithIsOpen:self.isVpnOpen];
    } else if (type == SVAdvertLocationTypeClick) {
        self.clickInterstitial = nil;
        [self jumpVCWithAnimated:NO];
    }
}

//3 点击
- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库点击次数
    SVAdvertLocationType type = [self getCurrentInterstitialTypeWithAd:ad];
    [[SVPosterManager sharedInstance] setupCckWithType:type];
}

//1 将要展示
- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    //保存数据库展示次数
    SVAdvertLocationType type = [self getCurrentInterstitialTypeWithAd:ad];
    [[SVPosterManager sharedInstance] setupCswWithType:type];
    if (type == SVAdvertLocationTypeVpn) {
        [SVStatisticAnalysis saveEvent:@"show_conn" params:nil];
    } else {
        if (self.jumpType == SVHomeJumpTypeServer) {
            [SVStatisticAnalysis saveEvent:@"show_click" params:@{@"type": @"server"}];
        } else if (self.jumpType == SVHomeJumpTypeBrowser) {
            [SVStatisticAnalysis saveEvent:@"show_click" params:@{@"type": @"browser"}];
        } else {
            [SVStatisticAnalysis saveEvent:@"show_click" params:@{@"type": @"map"}];
        }
    }
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    SVAdvertLocationType type = [self getCurrentInterstitialTypeWithAd:ad];
    [manager advertLogFailedWithType:type error:error.localizedDescription];
    if (type == SVAdvertLocationTypeVpn) {
        self.vpnInterstitial = nil;
        [self updateVnUIWithIsOpen:self.isVpnOpen];
    } else if (type == SVAdvertLocationTypeClick) {
        self.clickInterstitial = nil;
        [self jumpVCWithAnimated:YES];
    }
}

@end
