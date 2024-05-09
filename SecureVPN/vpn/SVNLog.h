//
//  SVNLog.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VNLogSource) {
    VNLogSourceMainApp = 0,
    VNLogSourceTunnel,
    VNLogSourceOther,
};

typedef NS_ENUM(NSUInteger, VNLogLevel) {
    VNLogLevelInfo = 0,
    VNLogLevelError,
    VNLogLevelConnectError
};

static NSString * const SVN_LOG = @"secureVpnLog";

@interface SVNLog : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) VNLogLevel level;
@property (nonatomic, assign) VNLogSource source;

- (instancetype)initWithText:(NSString *)text level:(VNLogLevel)level source:(VNLogSource)source;
- (NSString *)logDescription;
+ (void)appendWithText:(NSString *)text level:(VNLogLevel)level source:(VNLogSource)source;
+ (void)append:(SVNLog *)log;
+ (NSArray <SVNLog *> *)getValues;
+ (SVNLog *)getValueWithData:(NSData *)data;
+ (void)clean;

@end

NS_ASSUME_NONNULL_END
