//
//  SVAdInfoModel.h
//  SecureVPN
//
//  Created by  sevurevpn on 2024/3/7.
//

#import <Foundation/Foundation.h>
#import "SVAdAllType.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVAdInfoModel : NSObject

//广告id
@property (nonatomic, strong) NSString *aid;
//优先级
@property (nonatomic, assign) NSUInteger level;
//广告类型
@property (nonatomic, assign) SVAdvertType type;

@end

NS_ASSUME_NONNULL_END
