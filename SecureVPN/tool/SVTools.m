//
//  SVTools.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import "SVTools.h"

@implementation SVTools

+ (NSString *)sv_getAppVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)sv_getAppName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

+ (NSString *)randomStringWithLengh:(int)len {
    char ch[len];
    for (int index = 0; index < len; index++) {
        int num = arc4random_uniform(75) + 48;
        if (num > 57 && num < 65) { 
            num = num % 57 + 48;
        } else if (num > 90 && num < 97) {
            num = num % 90 + 65;
        }
        ch[index] = num;
    }
    return [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
}

+ (BOOL)isLimitCountry {
    NSLocale *locale = [NSLocale currentLocale];
    if (@available(iOS 17.0, *)) {
        NSString *code = [locale regionCode];
        if ([code isEqualToString:@"CN"]) {
            return YES;
        }
    } else {
        NSString *code = [locale objectForKey:NSLocaleCountryCode];
        if ([code containsString:@"CN"]) {
            return YES;
        }
    }
    return NO;
}

@end
