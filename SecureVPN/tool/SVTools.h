//
//  SVTools.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVTools : NSObject

+ (NSString *)sv_getAppVersion;
+ (NSString *)sv_getAppName;
+ (NSString *)randomStringWithLengh:(int)len;
+ (BOOL)isLimitCountry;

@end

NS_ASSUME_NONNULL_END
