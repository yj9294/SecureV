//
//  SVNTools.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import <Foundation/Foundation.h>
#import "SVServerModel.h"
#import "SVNetInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVNTools : NSObject

+ (void)isChina:(nullable void(^)(BOOL result))complete;
+ (NSString *)randomIp;
+ (nullable SVServerModel *)randomServer;
+ (void)uploadVpnAdShowWithIp:(NSString *)ip;
+ (void)uploadVpnAdPurchaseWithIp:(NSString *)ip purchase:(double)purchase;
+ (void)locationCoordinateWithComplete:(void(^)(BOOL isSuccess, SVNetInfoModel * _Nullable model))complete;
+ (void)getServerWithIp:(NSString *)ip complete:(void(^)(SVServerModel * _Nullable model))complete;

@end

NS_ASSUME_NONNULL_END
