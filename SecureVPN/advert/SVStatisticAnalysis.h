//
//  SVStatisticAnalysis.h
//  SecureVPN
//
//  Created by  securevpn on 2024/3/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVStatisticAnalysis : NSObject

+ (void)saveEvent:(NSString *)event params:(nullable NSDictionary *)params;
+ (void)setAttributeWithInfo:(NSString *)info name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
