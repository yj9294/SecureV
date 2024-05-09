//
//  SVNProfile.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVNProfile : NSObject

@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end

NS_ASSUME_NONNULL_END
