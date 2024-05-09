//
//  SVUITools.h
//  SecureVPN
//
//  Created by  sevurevpn on 2024/3/7.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVUITools : NSObject

@end

@interface UIFont (SV)

+ (UIFont *)pFont:(CGFloat)size;
+ (UIFont *)fontWithSize:(CGFloat)size;
+ (UIFont *)fontWithSize:(CGFloat)size weight:(UIFontWeight)weight;

@end

@interface UIColor (SV)

+ (UIColor *)colorWithHexString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
