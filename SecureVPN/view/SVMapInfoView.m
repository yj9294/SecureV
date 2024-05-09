//
//  SVMapInfoView.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/29.
//

#import "SVMapInfoView.h"
#import "UIView+SV.h"

@implementation SVMapInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_bg"]];
        [self addSubview:bgImageView];
        CGFloat ratio = (SVScreenWidth() - 40) / 374.0;
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
            make.top.bottom.mas_equalTo(0);
            make.height.mas_equalTo(269 * ratio);
        }];
        
        self.iconImageView = [[UIImageView alloc] init];
        [self addSubview:self.iconImageView];
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(31 * ratio);
            make.left.mas_equalTo(50 * ratio);
            make.width.height.mas_equalTo(30 * ratio);
        }];
        self.ipLabel = [UILabel lbText:@"" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        [self addSubview:self.ipLabel];
        [self.ipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.iconImageView.mas_right).offset(15 * ratio);
            make.centerY.equalTo(self.iconImageView);
        }];
        
        UIView *leftView = [[UIView alloc] init];
        leftView.layer.cornerRadius = 10;
        leftView.layer.masksToBounds = YES;
        leftView.layer.borderColor = [UIColor whiteColor].CGColor;
        leftView.layer.borderWidth = 1;
        [self addSubview:leftView];
        [leftView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.iconImageView.mas_bottom).offset(15 * ratio);
            make.left.equalTo(self.iconImageView);
            make.height.mas_equalTo(84 * ratio);
            make.width.mas_equalTo(146 * ratio);
        }];
        
        UILabel *latTitleLabel = [UILabel lbText:@"Lat:" font:[UIFont pFont:16] color:[UIColor colorWithHexString:@"#62B5E1"]];
        [leftView addSubview:latTitleLabel];
        [latTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.mas_equalTo(15 * ratio);
        }];
        
        self.latitudeLabel = [UILabel lbText:@"" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        [leftView addSubview:self.latitudeLabel];
        [self.latitudeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15 * ratio);
            make.bottom.right.mas_equalTo(-15 * ratio);
        }];
        
        UIView *rightView = [[UIView alloc] init];
        rightView.layer.cornerRadius = 10;
        rightView.layer.masksToBounds = YES;
        rightView.layer.borderColor = [UIColor whiteColor].CGColor;
        rightView.layer.borderWidth = 1;
        [self addSubview:rightView];
        [rightView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(leftView);
            make.right.mas_equalTo(-50 * ratio);
            make.height.width.equalTo(leftView);
        }];
        
        UILabel *lngTitleLabel = [UILabel lbText:@"Lng:" font:[UIFont pFont:16] color:[UIColor colorWithHexString:@"#62B5E1"]];
        [rightView addSubview:lngTitleLabel];
        [lngTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.mas_equalTo(15 * ratio);
        }];
        
        self.longitudeLabel = [UILabel lbText:@"" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        [rightView addSubview:self.longitudeLabel];
        [self.longitudeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15 * ratio);
            make.bottom.right.mas_equalTo(-15 * ratio);
        }];
        
        UIView *regionView = [[UIView alloc] init];
        [self addSubview:regionView];
        [regionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(leftView.mas_bottom).offset(30 * ratio);
            make.left.equalTo(leftView);
            make.right.equalTo(rightView);
            make.bottom.mas_equalTo(-15 * ratio);
        }];
        
        self.countryLabel = [UILabel lbText:@"" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        self.countryLabel.numberOfLines = 3;
        [regionView addSubview:self.countryLabel];
        [self.countryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(0);
            make.left.mas_equalTo(0);
            make.width.mas_equalTo(146 * ratio);
        }];
        
        self.cityLabel = [UILabel lbText:@"" font:[UIFont pFont:16] color:[UIColor whiteColor]];
        self.cityLabel.numberOfLines = 3;
        [regionView addSubview:self.cityLabel];
        [self.cityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(0);
            make.right.mas_equalTo(0);
            make.width.equalTo(self.countryLabel);
        }];
    }
    return self;
}

- (void)setModel:(SVNetInfoModel *)model {
    _model = model;
    self.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", model.countryCode]];
    if (self.iconImageView.image == nil) {
        self.iconImageView.image = [UIImage imageNamed:@"logo_auto"];
    }
    self.ipLabel.text = model.ip;
    self.latitudeLabel.text = [NSString stringWithFormat:@"%f", model.latitude];
    self.longitudeLabel.text = [NSString stringWithFormat:@"%f", model.longitude];
    self.countryLabel.text = [NSString stringWithFormat:@"Country:%@", model.country];
    self.cityLabel.text = [NSString stringWithFormat:@"City:%@", model.city];
}

@end
