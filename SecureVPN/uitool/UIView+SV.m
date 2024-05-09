//
//  SV.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#import "UIView+SV.h"
#import "MBProgressHUD.h"

@implementation UIView (SV)

//+ (void)sv_tipToast:(nullable NSString *)text {
//    if (!text) return;
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
//        CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
//        [style setCornerRadius:6];
//        [style setTitleFont:[UIFont pFont:14]];
//        
//        UIView *toast = [window toastViewForMessage:text title:nil image:nil style:style];
//        [window sv_tipToast:toast duration:1.5 position:CSToastPositionCenter completion:^(BOOL didTap) {
//        }];
//    });
//}

+ (UIView *)sv_showLoading:(NSString *)text {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [self showLoading:text inView:window];
    return window;
}

+ (MBProgressHUD *)showLoading:(NSString *)text inView:(UIView *)inView {
    [self sv_hideLoading:inView];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:inView animated:YES];
    
    [hud.label setText:text.length > 0 ? text : @"loading..."];
    [hud setAnimationType:MBProgressHUDAnimationFade];
    [hud setMode:MBProgressHUDModeCustomView];
    [hud.label setNumberOfLines:0];
    [hud.label setFont:[UIFont systemFontOfSize:16]];
    [hud.label setTextColor:[UIColor whiteColor]];
    [hud setMinSize:CGSizeMake(160, 80)];
    
    UIColor *bgColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    [hud.bezelView setColor:bgColor];
    [hud.bezelView setStyle:MBProgressHUDBackgroundStyleSolidColor];
    return hud;
}

+ (void)sv_hideLoading {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [MBProgressHUD hideHUDForView:window animated:YES];
}

+ (void)sv_hideLoading:(UIView *)inView {
    [MBProgressHUD hideHUDForView:inView animated:YES];
}

+ (void)sv_tipToast:(nullable NSString *)text {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    MBProgressHUD *hud = [self showLoading:text inView:window];
    [hud hideAnimated:YES afterDelay:1];
}

//- (UIViewController *)viewController {
//    id obj = [self nextResponder];
//    while (obj) {
//        if ([obj isKindOfClass:[UIViewController class]]) {
//            return (UIViewController *)obj;
//        }
//        obj = [obj nextResponder];
//    }
//    return nil;
//}
//
//- (UINavigationController *)navController {
//    id obj = [self nextResponder];
//    while (obj) {
//        if ([obj isKindOfClass:[UINavigationController class]]) {
//            return (UINavigationController *)obj;
//        }
//        obj = [obj nextResponder];
//    }
//    return nil;
//}

@end

@implementation UIImage (SV)

+ (UIImage *)sv_imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)sv_deepImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    CGContextRef overlayContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(overlayContext, [[UIColor colorWithWhite:0 alpha:0.2f] CGColor]);
    CGContextFillRect(overlayContext, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)sv_imageWithAlpha:(CGFloat)alpha {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -area.size.height);
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextSetAlpha(context, alpha);
    CGContextDrawImage(context, area, self.CGImage);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)sv_adjustImageColorByFactor:(CGFloat)factor {
    CIImage *ciImage = [[CIImage alloc] initWithImage:self];

    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:@(factor) forKey:kCIInputContrastKey];

    CIImage *outputCIImage = [filter outputImage];

    if (outputCIImage) {
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgImage = [context createCGImage:outputCIImage fromRect:[outputCIImage extent]];
        UIImage *adjustedImage = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:self.imageOrientation];
        CGImageRelease(cgImage);

        return adjustedImage;
    }

    return nil;
}
@end

@implementation UIButton (SVU)

+ (UIButton *)btTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithSize:17 weight:UIFontWeightMedium];
    [button tColor:[UIColor whiteColor]];
    [button bgImage:[UIImage imageNamed:@"button_bg"]];
    return button;
}

- (void)bgColor:(UIColor *)color {
    [self setBackgroundImage:[UIImage sv_imageWithColor:color] forState:UIControlStateNormal];
    [self setBackgroundImage:[UIImage sv_imageWithColor:[color colorWithAlphaComponent:0.5]] forState:UIControlStateDisabled];
    [self setBackgroundImage:[UIImage sv_deepImageWithColor:color] forState:UIControlStateHighlighted];
}

- (void)bgImage:(UIImage *)image {
    [self setBackgroundImage:image forState:UIControlStateNormal];
    [self setBackgroundImage:[image sv_adjustImageColorByFactor:1.3] forState:UIControlStateDisabled];
    [self setBackgroundImage:[image sv_adjustImageColorByFactor:0.7] forState:UIControlStateHighlighted];
}

- (void)tColor:(UIColor *)color {
    
    [self setTitleColor:color forState:UIControlStateNormal];
    [self setTitleColor:[color colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    [self setTitleColor:[color colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self setTitleColor:[color colorWithAlphaComponent:0.5] forState:UIControlStateSelected | UIControlStateHighlighted];
}

- (void)nImage:(UIImage *)image hImage:(UIImage * _Nullable)sImage {
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    sImage = [sImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self setImage:image forState:UIControlStateNormal];
    [self setImage:[image sv_imageWithAlpha:0.5] forState:UIControlStateDisabled];
    [self setImage:[image sv_imageWithAlpha:0.5] forState:UIControlStateHighlighted];
    
    if (sImage != nil) {
        [self setImage:sImage forState:UIControlStateSelected];
        [self setImage:[sImage sv_imageWithAlpha:0.5] forState:UIControlStateSelected | UIControlStateHighlighted];
    }
}

@end

@implementation UILabel (SV)

//- (void)adjustSize {
//    CGFloat width = self.frame.size.width;
//    [self sizeToFit];
//    CGRect rect = self.frame;
//    rect.size.width = width;
//    self.frame = rect;
//}

+ (UILabel *)lbText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.textAlignment = NSTextAlignmentLeft;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    return label;
}

@end
