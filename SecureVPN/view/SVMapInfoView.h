//
//  SVMapInfoView.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/29.
//

#import <UIKit/UIKit.h>
#import "SVNetInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVMapInfoView : UIView

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *ipLabel;
@property (nonatomic, strong) UILabel *latitudeLabel;
@property (nonatomic, strong) UILabel *longitudeLabel;
@property (nonatomic, strong) UILabel *countryLabel;
@property (nonatomic, strong) UILabel *cityLabel;
@property (nonatomic, strong) SVNetInfoModel *model;

@end

NS_ASSUME_NONNULL_END
