//
//  SV.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#import <UIKit/UIKit.h>
#import "SVConstant.h"
#import <Masonry/Masonry.h>
#import "SVUITools.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SV)

+ (UIView *)sv_showLoading:(NSString *)text;
+ (void)sv_hideLoading;
+ (void)sv_hideLoading:(UIView *)inView;
+ (void)sv_tipToast:(nullable NSString *)text;

//- (UIViewController *)viewController;
//- (UINavigationController *)navController;

@end

@interface UIImage (SV)

+ (UIImage *)sv_imageWithColor:(UIColor *)color;
+ (UIImage *)sv_deepImageWithColor:(UIColor *)color;
- (UIImage *)sv_imageWithAlpha:(CGFloat)alpha;
- (UIImage *)sv_adjustImageColorByFactor:(CGFloat)factor;

@end

@interface UIButton (SVU)
+ (UIButton *)btTitle:(NSString *)title;

- (void)bgColor:(UIColor *)color;
- (void)bgImage:(UIImage *)image;

- (void)tColor:(UIColor *)color;
- (void)nImage:(UIImage *)image hImage:(UIImage * _Nullable)sImage;

@end

@interface  UILabel (SV)

//- (void)adjustSize;
+ (UILabel *)lbText:(NSString *)text font:(UIFont *)font color:(UIColor *)color;

@end



NS_ASSUME_NONNULL_END
