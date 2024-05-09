//
//  NSString.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/28.
//

#import "NSString+SV.h"

@implementation NSString (SV)

- (NSString *)URLEncode {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL,kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}


@end
