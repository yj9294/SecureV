//
//  SVServerVC.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVBaseVC.h"
#import "SVServerModel.h"
NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const SVVNConnectNoto;

@interface SVServerVC : SVBaseVC

- (id)initWithModel:(SVServerModel *)model;

@end

NS_ASSUME_NONNULL_END
