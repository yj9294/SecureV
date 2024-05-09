//
//  SVNManager.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/20.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NEVPNConnection.h>
#import "SVNProfile.h"
#import "SVNTools.h"



NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSNotificationName const VNConnectionStatusNoto;
FOUNDATION_EXTERN NSNotificationName const VNConnectFailNoto;

@interface SVNManager : NSObject

@property (nonatomic, strong) SVNProfile *profile;
@property (nonatomic, assign) NEVPNStatus vnStatus;

+ (SVNManager *)sharedInstance;
- (void)startVPN;
- (void)stopVPN;
- (void)configureWithComplete:(void(^)(BOOL isSuccess))complete;

@end

NS_ASSUME_NONNULL_END
