//
//  SVDbAdvertHandle.h
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import <Foundation/Foundation.h>
#import "AdEntity+CoreDataProperties.h"
#import "SVPosterModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVDbAdvertHandle : NSObject

+ (NSArray <SVPosterModel *> *)saveDatas:(NSArray <SVPosterModel *> *)list;

@end

NS_ASSUME_NONNULL_END
