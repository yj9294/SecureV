//
//  SVNManager.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/20.
//

#import "SVNManager.h"
#import <NetworkExtension/NetworkExtension.h>
#import "SVNConfig.h"
#import "SVNLog.h"
#import "SVTools.h"
#import "SVPosterManager.h"

NSNotificationName const VNConnectionStatusNoto = @"VNConnectionStatusNoto";
NSNotificationName const VNConnectFailNoto = @"VNConnectFailNoto";

@interface SVNManager ()

@property (nonatomic, strong) NSUserDefaults *vnGroupDefaults;
@property (nonatomic, strong) NSMutableArray <SVNLog *> *vnOutputLogs;
@property (nonatomic, strong) NETunnelProviderManager *providerManager;

@end

@implementation SVNManager

+ (SVNManager *)sharedInstance {
    static SVNManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVNManager alloc] init];
    });
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.vnGroupDefaults removeObserver:self forKeyPath:SVN_LOG];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [SVNLog clean];
    self.profile = [self profile];
    self.vnStatus = NEVPNStatusDisconnected;
    self.vnGroupDefaults = [[NSUserDefaults alloc] initWithSuiteName:SVN_GROUP];
    [self.vnGroupDefaults addObserver:self forKeyPath:SVN_LOG options:NSKeyValueObservingOptionNew context:nil];
}

- (void)configureWithComplete:(void(^)(BOOL isSuccess))complete {
    [SVNLog appendWithText:@"securn vpn config ..." level:VNLogLevelInfo source:VNLogSourceMainApp];
    __weak typeof(self) weakSelf = self;
    [self loadProviderManagerWithComplete:^(BOOL isSuccess) {
        if (isSuccess) {
            weakSelf.vnStatus = weakSelf.providerManager.connection.status;
            [[NSNotificationCenter defaultCenter] addObserverForName:NEVPNStatusDidChangeNotification object:weakSelf.providerManager.connection queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
                weakSelf.vnStatus = weakSelf.providerManager.connection.status;
                [SVNLog appendWithText:[NSString stringWithFormat:@"Connection status changed to \"%@\".", [weakSelf logForStatus:weakSelf.vnStatus]] level:VNLogLevelInfo source:VNLogSourceMainApp];
                [[NSNotificationCenter defaultCenter] postNotificationName:VNConnectionStatusNoto object:@(weakSelf.vnStatus)];
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:VNConnectionStatusNoto object:@(weakSelf.vnStatus)];
            if (self.providerManager.protocolConfiguration.serverAddress.length > 0) {
                weakSelf.profile.serverAddress = self.providerManager.protocolConfiguration.serverAddress;
            }
            if (complete) complete(YES);
        } else {
            if (complete) complete(NO);
        }
    }];
}

- (void)loadProviderManagerWithComplete:(void(^)(BOOL isSuccess))complete {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error) {
            [SVNLog appendWithText:error.debugDescription level:VNLogLevelError source:VNLogSourceMainApp];
            if (complete) complete(NO);
        } else {
            if (managers.firstObject) {
                self.providerManager = managers.firstObject;
            }
            if (self.providerManager == nil) {
                self.providerManager = [[NETunnelProviderManager alloc] init];
            }
            [SVNLog appendWithText:@"Load all from preferences success" level:VNLogLevelInfo source:VNLogSourceMainApp];
            if (complete) complete(YES);
        }
    }];
}

- (NSString *)logForStatus:(NEVPNStatus)status {
    NSString *message;
    switch (status) {
        case NEVPNStatusDisconnected:
            message = @"disconnected";
            break;
        case NEVPNStatusInvalid:
            message = @"invalid";
            break;
        case NEVPNStatusConnected:
            message = @"connected";
            break;
        case NEVPNStatusConnecting:
            message = @"connecting";
            break;
        case NEVPNStatusDisconnecting:
            message = @"disconnecting";
            break;
        case NEVPNStatusReasserting:
            message = @"reasserting";
            break;
        default:
            message = @"unknow";
            break;
    }
    return message;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:SVN_LOG]) {
        NSArray *logs = change[NSKeyValueChangeNewKey];
        if (logs.count > 0) {
            [self updateLogs:logs];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateLogs:(NSArray *)logs {
    int newCount = logs.count - self.vnOutputLogs.count;
    if (newCount > 0) {
        NSRange range = NSMakeRange(logs.count - newCount, newCount);
        NSArray *newLogs = [logs subarrayWithRange:range];
        for (NSData *data in newLogs) {
            SVNLog *log = [SVNLog getValueWithData:data];
            [self.vnOutputLogs addObject:log];
            NSLog(@"%@", [log logDescription]);
            if (log.level == VNLogLevelConnectError) {
                [[NSNotificationCenter defaultCenter] postNotificationName:VNConnectFailNoto object:self.profile.serverAddress];
                [SVStatisticAnalysis saveEvent:@"v_fail" params:@{@"type": self.profile.serverAddress}];
            }
        }
    }
}

- (void)configureAndSaveManagerWithComplete:(void(^)(void))complete {
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        NETunnelProviderProtocol *tunnelProtocol = [[NETunnelProviderProtocol alloc] init];
        tunnelProtocol.username = self.profile.username;
//        NSDictionary *config = @{@"port": @(443), @"server": self.profile.serverAddress};
//        tunnelProtocol.providerConfiguration = config;
        tunnelProtocol.serverAddress = self.profile.serverAddress;
        tunnelProtocol.providerBundleIdentifier = SVN_TUNNEL;
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"secure" withExtension:@"ovpn"];
         NSData *data = [[NSData alloc] initWithContentsOfURL:url];
         NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         string = [string stringByReplacingOccurrencesOfString:@"192.168.0.1" withString:self.profile.serverAddress];
         NSData *newData = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        tunnelProtocol.providerConfiguration = @{@"ovpn": newData, @"username": self.profile.username, @"password": self.profile.password};
        tunnelProtocol.disconnectOnSleep = NO;
        
        self.providerManager.protocolConfiguration = tunnelProtocol;
        self.providerManager.localizedDescription = [SVTools sv_getAppName];
        if (self.providerManager.enabled == NO) {
            //第一次进来是NO，改成YES，并且抑制启动广告
            self.providerManager.enabled = YES;
            [SVPosterManager sharedInstance].isCanShowLaunchAd = NO;
        }
        __weak typeof(self) weakSelf = self;
        [self.providerManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                self.providerManager.enabled = NO;
                [SVStatisticAnalysis saveEvent:@"v_noperm" params:nil];
                [SVNLog appendWithText:error.debugDescription level:VNLogLevelConnectError source:VNLogSourceMainApp];
            } else {
                [weakSelf.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (complete) complete();
                }];
            }
        }];
    }];
}

- (void)startVPN {
    if (self.providerManager == nil) {
        __weak typeof(self) weakSelf = self;
        [self loadProviderManagerWithComplete:^(BOOL isSuccess) {
            if (isSuccess) {
                [weakSelf configureAndSaveManagerWithComplete:^{
                    [weakSelf startTunnel];
                }];
            }
        }];
    } else {
        __weak typeof(self) weakSelf = self;
        [self configureAndSaveManagerWithComplete:^{
            [weakSelf startTunnel];
        }];
    }
}

- (void)startTunnel {
    NSError *error = nil;
    [self.providerManager.connection startVPNTunnelWithOptions:nil andReturnError:&error];
    if (error) {
        [SVNLog appendWithText:error.localizedDescription level:VNLogLevelConnectError source:VNLogSourceMainApp];
    } else {
        [SVNLog appendWithText:@"Connection established!" level:VNLogLevelInfo source:VNLogSourceMainApp];
    }
}

- (void)stopVPN {
    [self.providerManager.connection stopVPNTunnel];
}

- (NSMutableArray<SVNLog *> *)vnOutputLogs {
    if (_vnOutputLogs == nil) {
        _vnOutputLogs = [NSMutableArray array];
    }
    return _vnOutputLogs;
}

- (SVNProfile *)profile {
    if (_profile == nil) {
        _profile = [[SVNProfile alloc] init];
        _profile.password = @"qwertyuiop";
    }
    return _profile;
}

@end
