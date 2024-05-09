//
//  SVLaunchManager.m
//  SecureVPN
//
//  Created by  securevpn on 2024/3/8.
//

#import "SVLaunchManager.h"
#import "AFNetworking/AFNetworking.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "SVBaseNC.h"
#import "SVHomeVC.h"
#import "UIView+SV.h"
#import "SVLaunchVC.h"
#import "SVDbAdvertHandle.h"
#import "SVFbHandle.h"
#import "SVSecurePrivacyPop.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SVPosterManager.h"

@interface SVLaunchManager () <GADFullScreenContentDelegate>


@property (nonatomic, assign) BOOL isShowLaunch;
@property (nonatomic, strong) SVBaseNC *home;
@property (nonatomic, assign) BOOL isTimeout;

@property (nonatomic, strong) id launchAd;

@end

@implementation SVLaunchManager

+ (SVLaunchManager *)shared {
    static SVLaunchManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVLaunchManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isTimeout = YES;
        self.isInit = NO;
    }
    return self;
}

- (void)launch {
    [self displayLaunch];
    [self networkManager];
    [self keyboardManager];
    [self uiConfigure];
}

- (void)keyboardManager {
    [[IQKeyboardManager sharedManager] setShouldShowToolbarPlaceholder:NO];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    [[IQKeyboardManager sharedManager] setShouldResignOnTouchOutside:YES];
}

- (void)uiConfigure {
    [[UITableView appearance] setEstimatedRowHeight:0];
    [[UITableView appearance] setEstimatedSectionHeaderHeight:0];
    [[UITableView appearance] setEstimatedSectionFooterHeight:0];
    [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
}

- (void)networkManager {
    __weak typeof(self) weakSelf = self;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status > 0) {
            weakSelf.isInit = YES;
            if (weakSelf.isTimeout) {
                weakSelf.isTimeout = NO;
                svdispatch_async_main_safe(^ {
                    [weakSelf idfaCheckWithComplete:^{
                        [SVFirebase configureAdvert];
                        [weakSelf configureData];
                    }];
                });
            }
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.isTimeout) {
            weakSelf.isTimeout = NO;
            [SVFirebase configureAdvert];
            [[SVPosterManager sharedInstance] setupWithComplete:nil];
            [[SVPosterManager sharedInstance] enterLaunch];
            [weakSelf privacyCheckWithComplete:^{
                [weakSelf idfaCheckWithComplete:^{
                    //判断有没有网
                    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus > 0) {
                        [weakSelf configureData];
                    } else {
                        [weakSelf showHome];
                    }
                }];
            }];
        }
    });
}

- (void)idfaCheckWithComplete:(void(^)(void))complete {
    if (@available(iOS 14, *)) {
        if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusNotDetermined) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                    if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                        [SVStatisticAnalysis saveEvent:@"idfa_cs" params:@{@"result": @"t"}];
                    } else {
                        [SVStatisticAnalysis saveEvent:@"idfa_cs" params:@{@"result": @"r"}];
                    }
                    if (complete) complete();
                }];
            });
        } else {
            if (complete) complete();
        }
    } else {
        if (complete) complete();
    }
}

- (void)privacyCheckWithComplete:(void(^)(void))complete {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *flag = [[NSUserDefaults standardUserDefaults] objectForKey:@"isAgreePrivacy"];
        if (flag.length > 0) {
            if (complete) complete();
        } else {
            [SVStatisticAnalysis saveEvent:@"privacy_show" params:nil];
            SVSecurePrivacyPop *pop = [[SVSecurePrivacyPop alloc] init];
            [pop showWithComplete:^{
                [SVStatisticAnalysis saveEvent:@"privacy_agree" params:nil];
                [[NSUserDefaults standardUserDefaults] setObject:@"Agree" forKey:@"isAgreePrivacy"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if (complete) complete();
            }];
        }
    });
}

- (void)displayLaunch {
    UIWindow *window = [self getHomeWindow];
    if ([window.rootViewController isKindOfClass:[SVLaunchVC class]]) return;
    self.isShowLaunch = YES;
    SVLaunchVC *launch = [[SVLaunchVC alloc] init];
    [window setRootViewController:launch];
    [window makeKeyAndVisible];
}

- (UIWindow *)getHomeWindow {
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
    return window;
}

- (void)displayLaunchView {
    if (self.isShowLaunch) return;
    self.isShowLaunch = YES;
    //展示启动页的时候去获取一次
    [SVFirebase appInfoWithComplete:^(BOOL isSuccess, id  _Nonnull config) {
        if (isSuccess) {
            [[SVPosterManager sharedInstance] setupWithComplete:nil];
        }
    }];
    
    UIWindow *window = [self getHomeWindow];
    SVLaunchVC *launch = [[SVLaunchVC alloc] init];
    launch.view.frame = window.bounds;
    launch.view.tag = 200;
    [window addSubview:launch.view];
    [[SVPosterManager sharedInstance] enterLaunch];
    __weak typeof(self) weakSelf = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf showAdvert];
    });
}

- (void)hiddenLaunchView {
    UIWindow *window = [self getHomeWindow];
    UIView *view = [window viewWithTag:200];
    [view removeFromSuperview];
    if (view) {
        view = nil;
        [[SVPosterManager sharedInstance] enterForeground];
    }
}

- (void)showHome {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf privacyCheckWithComplete:^{
            UIWindow *window = [weakSelf getHomeWindow];
            if (!weakSelf.home) {
                SVHomeVC *vc = [[SVHomeVC alloc] init];
                weakSelf.home = [[SVBaseNC alloc] initWithRootViewController:vc];
            }
            if ([window.rootViewController isKindOfClass:[SVBaseNC class]]) {
                [weakSelf hiddenLaunchView];
            } else {
                [window setRootViewController:weakSelf.home];
                [window makeKeyAndVisible];
            }
            weakSelf.isShowLaunch = NO;
        }];
    });
}

- (void)configureData {
    __weak typeof(self) weakSelf = self;
    [[SVPosterManager sharedInstance] setupWithComplete:^(BOOL isSuccess) {
        [[SVPosterManager sharedInstance] enterLaunch];
        if (isSuccess) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf showAdvert];
            });
        } else {
            [weakSelf showHome];
        }
    }];
    [SVFirebase appInfoWithComplete:^(BOOL isSuccess, id  _Nonnull config) {
        if (isSuccess) {
            [[SVPosterManager sharedInstance] setupWithComplete:nil];
        }
    }];
}

- (void)showAdvert {
    if (!self.isInit) return;
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    if (manager.launchModel.isw) return;
    if ([manager isCanShowAdvertWithType:SVAdvertLocationTypeLaunch]) {
        if (manager.launchAd && [manager isCacheValidWithType:SVAdvertLocationTypeLaunch]) {
            self.launchAd = manager.launchAd;
            manager.launchAd = nil;
            [self configureAndShowLaunchAd];
        } else {
            [manager syncRequestScreenAdWithType:SVAdvertLocationTypeLaunch timeout:15 complete:^(BOOL isSuccess) {
                if (isSuccess && manager.launchAd) {
                    self.launchAd = manager.launchAd;
                    manager.launchAd = nil;
                    [self configureAndShowLaunchAd];
                } else {
                    [self showHome];
                }
            }];
        }
    } else {
        [self showHome];
    }
}

- (void)configureAndShowLaunchAd {
    svdispatch_async_main_safe(^{
        UIWindow *window = [self getHomeWindow];
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            UIView *view = [window viewWithTag:200];
            [view removeFromSuperview];
            if (view) {
                self.isShowLaunch = NO;
            }
            return;
        }
        
        if ([SVPosterManager sharedInstance].isScreenAdShow) return;
        [SVPosterManager sharedInstance].isScreenAdShow = YES;
        
        [SVStatisticAnalysis saveEvent:@"scene_load" params:nil];
        UIViewController *vc = window.rootViewController;
        if ([self.launchAd isKindOfClass:[GADAppOpenAd class]]) {
            ((GADAppOpenAd *)self.launchAd).fullScreenContentDelegate = self;
            [((GADAppOpenAd *)self.launchAd) presentFromRootViewController:vc];
        } else if ([self.launchAd isKindOfClass:[GADInterstitialAd class]]) {
            ((GADInterstitialAd *)self.launchAd).fullScreenContentDelegate = self;
            [((GADInterstitialAd *)self.launchAd) presentFromRootViewController:vc];
        } else {
            [SVPosterManager sharedInstance].isScreenAdShow = NO;
        }
    });
}

- (void)gotoUpstage {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    [manager resetAdLoad];
    [manager requestLaunchAd];
}

#pragma mark - GADFullScreenContentDelegate
- (void)adDidRecordImpression:(nonnull id<GADFullScreenPresentingAd>)ad {
    if ([ad isKindOfClass:[GADAppOpenAd class]]) {
        GADAppOpenAd *advert = (GADAppOpenAd *)ad;
        advert.paidEventHandler = ^(GADAdValue * _Nonnull value) {
            [[SVPosterManager sharedInstance] paidAdWithValue:value];
        };
    } else{
        GADInterstitialAd *advert = (GADInterstitialAd *)ad;
        advert.paidEventHandler = ^(GADAdValue * _Nonnull value) {
            [[SVPosterManager sharedInstance] paidAdWithValue:value];
        };
    }
}

- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager setupIsShow:NO type:SVAdvertLocationTypeLaunch];
    self.launchAd = nil;
    [self showHome];
    [manager requestLaunchAd];
}

- (void)adWillPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    [[SVPosterManager sharedInstance] setupCswWithType:SVAdvertLocationTypeLaunch];
    [SVStatisticAnalysis saveEvent:@"show_load" params:nil];
}

- (void)adDidRecordClick:(nonnull id<GADFullScreenPresentingAd>)ad {
    [[SVPosterManager sharedInstance] setupCckWithType:SVAdvertLocationTypeLaunch];
}

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    SVPosterManager *manager = [SVPosterManager sharedInstance];
    manager.isScreenAdShow = NO;
    [manager advertLogFailedWithType:SVAdvertLocationTypeLaunch error:error.localizedDescription];
    self.launchAd = nil;
    [self showHome];
}

@end
