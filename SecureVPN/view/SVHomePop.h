//
//  SVHomePop.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import <UIKit/UIKit.h>
#import "SVPop.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVHomePop : SVPop

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *button;

- (void)showWithComplete:(void(^)(void))complete;

@end

NS_ASSUME_NONNULL_END
