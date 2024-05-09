//
//  SceneDelegate.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#import "SceneDelegate.h"
#import "SVPosterManager.h"
#import "SVLaunchManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "UIView+SV.h"
#import "NSObject+SV.h"

@interface SceneDelegate () <GADFullScreenContentDelegate>
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskIdentifier;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    self.taskIdentifier = UIBackgroundTaskInvalid;
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window setBackgroundColor:[UIColor colorWithHexString:@"#202329"]];
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    [self.window setWindowScene:windowScene];
    [[SVLaunchManager shared] launch];
}

#pragma mark - cycle

- (void)sceneWillResignActive:(UIScene *)scene {
    if (![SVLaunchManager shared].isInit) return;
    [[SVPosterManager sharedInstance] saveAdvertDatas];
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    if (![SVLaunchManager shared].isInit) return;
        
    UIViewController *vc = [self getCurrentTopVC];
    if ([vc isKindOfClass:[NSClassFromString(@"GADFullScreenAdViewController") class]]) {
        return;
    }
    
    if (![SVPosterManager sharedInstance].launchModel.isw) {
        if (![SVPosterManager sharedInstance].isCanShowLaunchAd) {
            [SVPosterManager sharedInstance].isCanShowLaunchAd = YES;
        } else {
            [[SVLaunchManager shared] displayLaunchView];
        }
    }
    if (self.taskIdentifier != UIBackgroundTaskInvalid) {
        [self endTask];
    }
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    if (![SVLaunchManager shared].isInit) return;
    [[SVLaunchManager shared] gotoUpstage];
    if (self.taskIdentifier != UIBackgroundTaskInvalid) {
        [self endTask];
    }
    
    __weak typeof(self) weakSelf = self;
    self.taskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[SVLaunchManager shared] gotoUpstage];
        [weakSelf endTask];
    }];
}

- (void)endTask {
    [[UIApplication sharedApplication] endBackgroundTask:self.taskIdentifier];
    self.taskIdentifier = UIBackgroundTaskInvalid;
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    NSURL *url = URLContexts.allObjects.firstObject.URL;
    if (url) {
        [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication] openURL:url sourceApplication:nil annotation:@[UIApplicationOpenURLOptionsAnnotationKey]];
    }
}
@end
