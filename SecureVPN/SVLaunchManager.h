//
//  SVLaunchManager.h
//  SecureVPN
//
//  Created by  securevpn on 2024/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVLaunchManager : NSObject

@property (nonatomic, assign) BOOL isInit;

+ (SVLaunchManager *)shared;
- (void)launch;
- (void)displayLaunchView;
- (void)gotoUpstage;
@end

NS_ASSUME_NONNULL_END
