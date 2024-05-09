//
//  PacketTunnelProvider.m
//  Tunnel
//
//  Created by  securevpn on 2024/2/20.
//

#import "PacketTunnelProvider.h"
#import "NEPacketTunnelFlow+TMExtension.h"
#import "SVNLog.h"

@import OpenVPNAdapter;

typedef void(^StartHandler)(NSError * _Nullable);
typedef void(^StopHandler)(void);

@interface PacketTunnelProvider () <OpenVPNAdapterDelegate, OpenVPNAdapterPacketFlow>

@property (nonatomic, copy) StartHandler __nullable startHandler;
@property (nonatomic, copy) StopHandler __nullable stopHandler;
@property (nonatomic, strong) OpenVPNAdapter *vpnAdapter;
@property (nonatomic, strong) OpenVPNReachability *vpnReachability;
@property (nonatomic, strong) NSArray *dnsList;


@end

@implementation PacketTunnelProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        [SVNLog appendWithText:@"start config tunnel" level:VNLogLevelInfo source:VNLogSourceTunnel];
    }
    return self;
}

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    [SVNLog appendWithText:@"start tunnel" level:VNLogLevelInfo source:VNLogSourceTunnel];
    
    NETunnelProviderProtocol *protocol =  (NETunnelProviderProtocol*)self.protocolConfiguration;
    if (!protocol) {
        [SVNLog appendWithText:@"no NETunnelProviderProtocol" level:VNLogLevelError source:VNLogSourceTunnel];
        return;
    }
    
    NSDictionary<NSString *,id> *provider = protocol.providerConfiguration;
    if (!provider) {
        [SVNLog appendWithText:@"no providerConfiguration" level:VNLogLevelError source:VNLogSourceTunnel];
        return;
    }
    
    NSData *fileContent = provider[@"ovpn"];
    OpenVPNConfiguration *configuration = [[OpenVPNConfiguration alloc] init];
    configuration.fileContent = fileContent;
    configuration.keyDirection = 1;
//    configuration.disableClientCert = NO;
    configuration.tunPersist = YES;
//    [VNLog appendWithText:protocol.serverAddress level:VNLogLevelInfo source:VNLogSourceTunnel];
    configuration.server = protocol.serverAddress;
    configuration.port = 443;
    configuration.proto = OpenVPNTransportProtocolUDP;
//    configuration.connectionTimeout = 30;
    configuration.connectionTimeout = 30;
    NSError *error;
    OpenVPNConfigurationEvaluation *evaluation = [self.vpnAdapter applyConfiguration:configuration error:&error];
    if (error) {
        [SVNLog appendWithText:error.localizedDescription level:VNLogLevelError source:VNLogSourceTunnel];
        if (completionHandler) completionHandler(error);
        return;
    }
    
    if (!evaluation.autologin) {
        OpenVPNCredentials *tials = [[OpenVPNCredentials alloc]init];
        tials.username = [NSString stringWithFormat:@"%@",[provider objectForKey:@"username"]];
        tials.password = [NSString stringWithFormat:@"%@",[provider objectForKey:@"password"]];
//        [SVNLog appendWithText:[NSString stringWithFormat:@"username: %@ password: %@", tials.username, tials.password] level:VNLogLevelInfo source:VNLogSourceTunnel];
        [self.vpnAdapter provideCredentials:tials error:&error];
        if(error){
            [SVNLog appendWithText:error.localizedDescription level:VNLogLevelError source:VNLogSourceTunnel];
            if (completionHandler) completionHandler(error);
            return;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [self.vpnReachability startTrackingWithCallback:^(OpenVPNReachabilityStatus status) {
        if (status != OpenVPNReachabilityStatusNotReachable) {
            [weakSelf.vpnAdapter reconnectAfterTimeInterval:5];
        }
    }];
    
    self.startHandler = completionHandler;
    [self.vpnAdapter connectUsingPacketFlow:self.packetFlow];
    
    [SVNLog appendWithText:@"start tunnel config complete" level:VNLogLevelInfo source:VNLogSourceTunnel];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    self.stopHandler = completionHandler;
    if ([self.vpnReachability isTracking]) {
        [self.vpnReachability stopTracking];
    }
    [self.vpnAdapter disconnect];
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    NSString *message = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
    if (message.length > 0) {
        [SVNLog appendWithText:[NSString stringWithFormat:@"receive message: %@", message] level:VNLogLevelInfo source:VNLogSourceTunnel];
        if (completionHandler) completionHandler(messageData);
    } else {
        if (completionHandler) completionHandler(nil);
    }
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

- (void)wake {}

#pragma mark protocol

- (void)openVPNAdapter:(nonnull OpenVPNAdapter *)openVPNAdapter configureTunnelWithNetworkSettings:(nullable NEPacketTunnelNetworkSettings *)networkSettings completionHandler:(nonnull void (^)(NSError * _Nullable))completionHandler {
    
    [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
        if (error) {
            [SVNLog appendWithText:error.debugDescription level:VNLogLevelError source:VNLogSourceTunnel];
        }
        if (completionHandler) completionHandler(error);
    }];
    
    if (networkSettings.tunnelRemoteAddress.length > 0) {
        [SVNLog appendWithText:[NSString stringWithFormat:@"Remote IP address: %@", networkSettings.tunnelRemoteAddress] level:VNLogLevelInfo source:VNLogSourceTunnel];
        [SVNLog appendWithText:[NSString stringWithFormat:@"DNS servers added: %@", [networkSettings.DNSSettings.servers componentsJoinedByString:@", "]] level:VNLogLevelInfo source:VNLogSourceTunnel];
        
        if (networkSettings.IPv4Settings) {
            NSMutableArray *routes = [NSMutableArray array];
            for (NEIPv4Route *route in networkSettings.IPv4Settings.includedRoutes) {
                NSString *routeString = [NSString stringWithFormat:@"%@ subnetmask:%@", route.destinationAddress, route.destinationSubnetMask];
                [routes addObject:routeString];
            }
            
            if (routes.count > 0) {
                NSString *routesString = [routes componentsJoinedByString:@"\n"];
                [SVNLog appendWithText:[NSString stringWithFormat:@"Routes:\n%@", routesString] level:VNLogLevelInfo source:VNLogSourceTunnel];
            }
        }
    }
}

- (void)openVPNAdapter:(nonnull OpenVPNAdapter *)openVPNAdapter handleError:(nonnull NSError *)error {
    BOOL isOpen = [[error userInfo][OpenVPNAdapterErrorFatalKey] boolValue];
    if(isOpen){
        NSString *message = [error userInfo][OpenVPNAdapterErrorMessageKey];
        if (message == nil) {
            message = error.localizedDescription;
        }
        if ([message containsString:@"OpenVPN fatal error occured"]) {
            [SVNLog appendWithText:message level:VNLogLevelConnectError source:VNLogSourceTunnel];
        } else {
            [SVNLog appendWithText:message level:VNLogLevelError source:VNLogSourceTunnel];
        }
        
        [SVNLog appendWithText:[NSString stringWithFormat:@"Connection Info: %@", self.vpnAdapter.connectionInformation.debugDescription] level:VNLogLevelError source:VNLogSourceTunnel];
        
        if (self.vpnReachability.isTracking) {
            [self.vpnReachability stopTracking];
        }
        
        if (self.startHandler) {
            self.startHandler(error);
            self.startHandler = nil;
        } else {
            [self cancelTunnelWithError:error];
        }
    }
}

- (void)openVPNAdapter:(nonnull OpenVPNAdapter *)openVPNAdapter handleEvent:(OpenVPNAdapterEvent)event message:(nullable NSString *)message {
    switch (event) {
        case OpenVPNAdapterEventConnected:
        {
            if(self.reasserting){
                self.reasserting = false;
            }
            
            if (self.startHandler) {
                self.startHandler(nil);
                self.startHandler = nil;
            }
        }
            break;
        case OpenVPNAdapterEventDisconnected:
        {
            if (self.stopHandler) {
                if (self.vpnReachability.isTracking) {
                    [self.vpnReachability stopTracking];
                }
                self.stopHandler();
                self.stopHandler = nil;
            }
        }
            break;
        case OpenVPNAdapterEventReconnecting:
            self.reasserting = true;
            break;
        default:
            break;
    }
}

- (void)openVPNAdapter:(OpenVPNAdapter *)openVPNAdapter handleLogMessage:(NSString *)logMessage {
    [SVNLog appendWithText:logMessage level:VNLogLevelInfo source:VNLogSourceTunnel];
}

- (void)readPacketsWithCompletionHandler:(void (^)(NSArray<NSData *> * _Nonnull, NSArray<NSNumber *> * _Nonnull))completionHandler {
    [self.packetFlow readPacketsWithCompletionHandler:completionHandler];
}

- (BOOL)writePackets:(NSArray<NSData *> *)packets withProtocols:(NSArray<NSNumber *> *)protocols {
    return [self.packetFlow writePackets:packets withProtocols:protocols];
}

#pragma mark private method

#pragma mark - property

- (OpenVPNAdapter *)vpnAdapter {
    if (!_vpnAdapter) {
        _vpnAdapter = [[OpenVPNAdapter alloc] init];
        _vpnAdapter.delegate = self;
    }
    return _vpnAdapter;
}

- (OpenVPNReachability *)vpnReachability {
    if (!_vpnReachability) {
        _vpnReachability = [[OpenVPNReachability alloc] init];
    }
    return _vpnReachability;
}

@end
