//
//  SVHomePop.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import "SVHomePop.h"
#import <Masonry/Masonry.h>
#import "UIView+SV.h"

@interface SVHomePop ()

@property (nonatomic, strong) void(^complete)(void);

@end

@implementation SVHomePop

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentView = [[UIView alloc] init];
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 10;
        self.contentView.layer.masksToBounds = YES;
        [self addSubview:self.contentView];
        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(0);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
        }];
        
        self.logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"country_tip"]];
        [self.contentView addSubview:self.logoImageView];
        [self.logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0);
            make.width.mas_equalTo(207);
            make.height.mas_equalTo(165);
            make.centerX.mas_equalTo(0);
        }];
        
        self.textLabel = [UILabel lbText:@"" font:[UIFont pFont:18] color:[UIColor colorWithHexString:@"#333333"]];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 4;
        paragraphStyle.alignment = NSTextAlignmentJustified;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:@"This app is not available in the current country/region." attributes:@{NSFontAttributeName: [UIFont pFont:18], NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#333333"], NSParagraphStyleAttributeName: paragraphStyle}];
        self.textLabel.numberOfLines = 0;
        self.textLabel.preferredMaxLayoutWidth = SVScreenWidth() - 80;
        self.textLabel.attributedText = attribute;
        [self.contentView addSubview:self.textLabel];
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.logoImageView.mas_bottom).offset(20);
            make.left.mas_equalTo(20);
            make.right.mas_equalTo(-20);
        }];
        
        self.button = [UIButton btTitle:@"OK"];
        [self.button addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.button];
        [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.textLabel.mas_bottom).offset(20);
            make.bottom.mas_equalTo(-20);
            make.width.mas_equalTo(284);
            make.centerX.mas_equalTo(0);
            make.height.mas_equalTo(51);
        }];
    }
    return self;
}

- (void)showWithComplete:(void(^)(void))complete {
    self.complete = complete;
    [self show];
}

- (void)action {
    if (self.complete) self.complete();
    [self dismiss];
}

@end
