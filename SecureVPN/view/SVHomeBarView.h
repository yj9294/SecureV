//
//  SVHomeBarView.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import <UIKit/UIKit.h>
#import "SVServerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVHomeBarView : UIControl

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) SVServerModel *model;

@end

NS_ASSUME_NONNULL_END
