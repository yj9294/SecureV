//
//  SVFbHandle.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/29.
//

#import <Foundation/Foundation.h>
#import "SVServerModel.h"
#import <FirebaseRemoteConfig/FirebaseRemoteConfig.h>
NS_ASSUME_NONNULL_BEGIN

#define SVFirebase [SVFbHandle shared]

@interface SVFbHandle : NSObject

@property (nonatomic, strong, readonly) FIRRemoteConfig *remoteInfo;

+ (SVFbHandle *)shared;
- (void)configreRemoteInfo;
- (void)configureAdvert;
- (void)appInfoWithComplete:(void(^)(BOOL isSuccess, id config))complete;
- (NSString *)getAppMode;
- (nullable NSArray *)getVNConfig;
- (nullable NSArray <SVServerModel *> *)getVNModels;

@end

NS_ASSUME_NONNULL_END
