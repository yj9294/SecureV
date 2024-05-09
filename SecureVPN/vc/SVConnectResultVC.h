//
//  SVConnectResultVC.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "SVBaseVC.h"
#import "SVServerModel.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const SVRetryConnectNoto;

typedef NS_ENUM(NSUInteger, SVVNResultStatus) {
    SVVNResultStatusCollectSuccess = 0,
    SVVNResultStatusCollectFail,
    SVVNResultStatusDisconnectSuccess
};

@interface SVConnectResultVC : SVBaseVC

@property (nonatomic, strong) SVServerModel *model;

- (id)initWithStatus:(SVVNResultStatus)status;

@end

NS_ASSUME_NONNULL_END
