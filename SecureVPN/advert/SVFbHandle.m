//
//  SVFbHandle.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/29.
//

#import "SVFbHandle.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FirebaseCore.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "SVPosterManager.h"
#import <FBAudienceNetwork/FBAdSettings.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SVStatisticAnalysis.h"

@interface SVFbHandle ()

@property (nonatomic, strong, readwrite) FIRRemoteConfig *remoteInfo;
@property (nonatomic, assign) BOOL isAdConfig;
@property (nonatomic, strong) NSString *mode;

@end

@implementation SVFbHandle

+ (SVFbHandle *)shared {
    static SVFbHandle *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVFbHandle alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isAdConfig = NO;
        [FIRApp configure];
    }
    return self;
}

- (void)configreRemoteInfo {
    self.remoteInfo = [FIRRemoteConfig remoteConfig];
    FIRRemoteConfigSettings *setting = [[FIRRemoteConfigSettings alloc] init];
#ifdef DEBUG
    setting.minimumFetchInterval = 0;
#endif
    self.remoteInfo.configSettings = setting;
    [self.remoteInfo setDefaultsFromPlistFileName:@"remote_config_defaults"];
}

- (void)configureAdvert {
    if (self.isAdConfig) {
        return;
    }
    self.isAdConfig = YES;
    
    //ad
    if (@available(iOS 14, *)) {
        if ([ATTrackingManager trackingAuthorizationStatus] == ATTrackingManagerAuthorizationStatusAuthorized) {
            [self setTrackingWithEnabled:YES];
        } else {
            [self setTrackingWithEnabled:NO];
        }
    } else {
        [self setTrackingWithEnabled:YES];
    }
    
    [self startAdmob];
    
    //设置用户模式
    [self setAppMode];
}

- (void)setTrackingWithEnabled:(BOOL)enabled {
    [FBSDKSettings sharedSettings].isAdvertiserTrackingEnabled = enabled;
    [FBAdSettings setAdvertiserTrackingEnabled:enabled];
}

- (void)startAdmob {
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
}

- (void)setAppMode {
    NSString *model = [[self.remoteInfo configValueForKey:@"yong"] stringValue];
    if (model.length == 0) {
        model = @"bs";
    }
    
    if (![model isEqualToString:self.mode]) {
        self.mode = model;
        [SVStatisticAnalysis setAttributeWithInfo:model name:@"user_mode"];
    }
}

// 激进:jj 保守:bs
- (NSString *)getAppMode {
    NSString *model = [[self.remoteInfo configValueForKey:@"yong"] stringValue];
    if (model.length == 0) {
        model = @"bs";
    }
    return model;
}

- (nullable NSArray *)getVNConfig {
    id obj = [[self.remoteInfo configValueForKey:@"vn"] JSONValue];
    if ([obj isKindOfClass:[NSArray class]]) {
        return obj;
    }
    return nil;
}

- (nullable NSArray <SVServerModel *> *)getVNModels {
    NSArray *array = [self getVNConfig];
    NSMutableArray <SVServerModel *> *models = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        SVServerModel *model = [[SVServerModel alloc] init];
        [model setValuesForKeysWithDictionary:dict];
        [models addObject:model];
    }
    return models;
}

- (void)appInfoWithComplete:(void(^)(BOOL isSuccess, id config))complete {
    __weak typeof(self) weakSelf = self;
    [self.remoteInfo fetchWithExpirationDuration:10 completionHandler:^(FIRRemoteConfigFetchStatus status, NSError * _Nullable error) {
        if (status != FIRRemoteConfigFetchStatusSuccess) {
            NSLog(@"<Config> config fetch field:%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(NO, nil);
            });
        } else {
            NSLog(@"<Config> config fetch field:%@", [weakSelf.remoteInfo allKeysFromSource:FIRRemoteConfigSourceRemote]);
            id obj = [[weakSelf.remoteInfo configValueForKey:@"adconfig"] JSONValue];
            [weakSelf setAppMode];
//            NSArray *array = [NSJSONSerialization JSONObjectWithData:obj options:NSJSONReadingMutableContainers error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(YES, obj);
            });
        }
    }];
}

@end
