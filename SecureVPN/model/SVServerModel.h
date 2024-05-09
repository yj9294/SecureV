//
//  SVServerModel.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVServerModel : NSObject

//ip
@property (nonatomic, copy) NSString *ip;
//国家
@property (nonatomic, copy) NSString *name;
//国家code
@property (nonatomic, copy) NSString *countryCode;
//概率
@property (nonatomic, assign) float probability;

@end

NS_ASSUME_NONNULL_END
