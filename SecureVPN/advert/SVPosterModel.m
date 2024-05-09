//
//  AdModel.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import "SVPosterModel.h"

@implementation SVPosterModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ild = NO;
        self.isw = NO;
        self.tld = 0;
        self.tsw = 0;
        self.tsld = 0;
        self.tut = 0;
        self.msw = 20;
        self.mck = 10;
        self.cck = 0;
        self.csw = 0;
    }
    return self;
}

- (void)setName:(NSString *)name {
    SVAdvertLocationType type = SVAdvertLocationTypeUnknow;
    if ([name isEqualToString:@"launch"]) {
        type = SVAdvertLocationTypeLaunch;
    } else if ([name isEqualToString:@"vpn"]) {
        type = SVAdvertLocationTypeVpn;
    } else if ([name isEqualToString:@"click"]) {
        type = SVAdvertLocationTypeClick;
    } else if ([name isEqualToString:@"back"]) {
        type = SVAdvertLocationTypeBack;
    } else if ([name isEqualToString:@"homeNative"]) {
        type = SVAdvertLocationTypeHomeNative;
    } else if ([name isEqualToString:@"resultNative"]) {
        type = SVAdvertLocationTypeResultNative;
    } else if ([name isEqualToString:@"mapNative"]) {
        type = SVAdvertLocationTypeMapNative;
    }
    self.posty = type;
    _name = name;
}

- (NSUInteger)hash {
    return  self.name.hash;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    SVPosterModel *model = (SVPosterModel *)object;
    return [self.name isEqualToString:model.name];
}

@end

//@implementation SVAdMetaTransformer
//
//+ (Class)transformedValueClass
//{
//    return [NSArray class];
//}
//
//+ (BOOL)allowsReverseTransformation
//{
//    return YES;
//}
//
//- (id)transformedValue:(id)value
//{   return [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:NO error:nil];
//}
//
//- (id)reverseTransformedValue:(id)value
//{
//    if (@available(iOS 14.0, *)) {
//        return [NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:[SVAdInfoModel class] fromData:value error:nil];
//    } else {
//        return [NSKeyedUnarchiver unarchivedObjectOfClass:[SVAdInfoModel class] fromData:value error:nil];
//    }
//}

//@end
