//
//  SVSecurePrivacyPop.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/5.
//

#import "SVSecurePrivacyPop.h"
#import "UIView+SV.h"
#import "SVWebVC.h"
#import <YYText/NSAttributedString+YYText.h>

@interface SVSecurePrivacyPop ()

@property (nonatomic, strong) void(^complete)(void);

@end

@implementation SVSecurePrivacyPop

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
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
        
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    UIView *topBgView = [[UIView alloc] init];
    topBgView.backgroundColor = [[UIColor colorWithHexString:@"#76C1F4"] colorWithAlphaComponent:0.2];
    [self.contentView addSubview:topBgView];
    
    UILabel *titleLabel = [UILabel lbText:@"Privacy Policy" font:[UIFont fontWithSize:24 weight:UIFontWeightSemibold] color:[UIColor colorWithHexString:@"#529CBE"]];
    [topBgView addSubview:titleLabel];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"privacy_logo"]];
    logoImageView.contentMode = UIViewContentModeScaleAspectFill;
    [topBgView addSubview:logoImageView];
    NSString *message = @"    Thank you for using Secure Net, We attach great importance to the protection of user personal information. Please read and understand the 《Privacy Policy》 in detail. If you agreed to all the contents of the policy, please click \"Agree\"";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.lineSpacing = 4;
    paragraphStyle.alignment = NSTextAlignmentJustified;
    
    
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName: [UIFont pFont:16], NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#333333"], NSParagraphStyleAttributeName: paragraphStyle}];
    
    [attribute yy_setTextHighlightRange:[[attribute string] rangeOfString:@"《Privacy Policy》"] color:[UIColor colorWithHexString:@"#99EEC5"] backgroundColor:[UIColor whiteColor] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
        UIViewController *vc = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        SVWebVC *webvc = [[SVWebVC alloc] init];
        webvc.url = @"https://sites.google.com/view/secure-vpn-privacypolicy";
        [vc presentViewController:webvc animated:YES completion:nil];
    }];
    
    self.contentLabel = [[YYLabel alloc] init];
    self.contentLabel.textColor = [UIColor colorWithHexString:@"#333333"];
    self.contentLabel.font = [UIFont pFont:16];
    self.contentLabel.preferredMaxLayoutWidth = SVScreenWidth() - 60;
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.attributedText = attribute;
    [self.contentView addSubview:self.contentLabel];
   
    self.button = [UIButton btTitle:@"Agree"];
    [self.button addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.button];
    
    [topBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(0);
        make.height.mas_equalTo(111);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(30);
        make.centerY.mas_equalTo(0);
    }];
    
    [logoImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.bottom.mas_equalTo(0);
        make.width.mas_equalTo(118);
    }];
    
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topBgView.mas_bottom).offset(10);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
    }];
    
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentLabel.mas_bottom).offset(30);
        make.bottom.mas_equalTo(-30);
        make.width.mas_equalTo(284);
        make.centerX.mas_equalTo(0);
        make.height.mas_equalTo(51);
    }];
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
