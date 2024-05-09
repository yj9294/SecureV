//
//  SVHomeBarView.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import "SVHomeBarView.h"
#import "UIView+SV.h"

@implementation SVHomeBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_bar"]];
        [self addSubview:bgImageView];
        [bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.mas_equalTo(0);
        }];
        
        self.iconImageView = [[UIImageView alloc] init];
        [self addSubview:self.iconImageView];
        [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(15);
            make.height.width.mas_equalTo(30);
            make.centerY.mas_equalTo(0);
        }];
        
        self.textLabel = [UILabel lbText:@"" font:[UIFont pFont:14] color:[UIColor whiteColor]];
        [self addSubview:self.textLabel];
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(55);
            make.centerY.mas_equalTo(0);
        }];
        
        self.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"home_arrow"]];
        [self addSubview:self.arrowImageView];
        [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(-15);
            make.width.mas_equalTo(8);
            make.height.mas_equalTo(15);
            make.centerY.mas_equalTo(0);
        }];
    }
    return self;
}

- (void)setModel:(SVServerModel *)model {
    _model = model;
    [self configure];
}

- (void)configure {
    self.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", self.model.countryCode]];
    self.textLabel.text = [NSString stringWithFormat:@"%@", self.model.name];
}

@end
