//
//  SVNetInfoModel.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVNetInfoModel : NSObject

@property (nonatomic, copy) NSString *ip;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;

@end

NS_ASSUME_NONNULL_END
