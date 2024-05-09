//
//  SVSecurePrivacyPop.h
//  SecureVPN
//
//  Created by  securevpn on 2024/1/5.
//

#import <UIKit/UIKit.h>
#import <YYText/YYLabel.h>
#import "SVPop.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVSecurePrivacyPop : SVPop

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) YYLabel *contentLabel;
@property (nonatomic, strong) UIButton *button;

- (void)showWithComplete:(void(^)(void))complete;

@end

NS_ASSUME_NONNULL_END
