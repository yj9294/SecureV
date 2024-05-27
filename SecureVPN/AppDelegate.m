//
//  AppDelegate.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#import "AppDelegate.h"
#import "SVPoolManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SVNManager.h"
#import "SVTools.h"
#import "SVFbHandle.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [SVFirebase configreRemoteInfo];
    [FBSDKSettings sharedSettings].isAdvertiserIDCollectionEnabled = YES;
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    if ([SVNManager sharedInstance].vnStatus != NEVPNStatusDisconnected) {
        [[SVNManager sharedInstance] stopVPN];
    }
    [[SVPoolManager shared] savePool];
}

@end
