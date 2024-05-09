//
//  SVStatisticAnalysis.m
//  SecureVPN
//
//  Created by  securevpn on 2024/3/8.
//

#import "SVStatisticAnalysis.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>

@implementation SVStatisticAnalysis

+ (void)setAttributeWithInfo:(NSString *)info name:(NSString *)name {
    NSLog(@"\n<Attribute> info:%@, name:%@", info, name);
    [FIRAnalytics setUserPropertyString:info forName:name];
}

+ (void)saveEvent:(NSString *)event params:(nullable NSDictionary *)params {
    [FIRAnalytics logEventWithName:event parameters:params];
    NSLog(@"\n<User Event> event:%@, params:%@", event, params);
}

@end
