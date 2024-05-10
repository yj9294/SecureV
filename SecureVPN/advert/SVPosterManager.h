//
//  SVPosterManager.h
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import <Foundation/Foundation.h>
#import "SVPosterModel.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "SVDbAdvertHandle.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SVPrintType) {
    SVPrintTypeStartLoad = 0, //开始加载
    SVPrintTypeNotLoad, //不能加载
    SVPrintTypeLoadSuccess, //加载成功
    SVPrintTypeLoadFail, //加载失败
    SVPrintTypeShowSuccess, //显示成功
    SVPrintTypeShowFail, //显示失败
    SVPrintTypeNotShow, //不能显示
    SVPrintTypeHasCache, //有缓存
    
};

@interface SVPosterManager : NSObject

@property (nonatomic, strong, nullable) GADAdLoader *homeLoader;
@property (nonatomic, strong, nullable) GADNativeAd *homeAd;
@property (nonatomic, strong, nullable) GADAdLoader *resultLoader;
@property (nonatomic, strong, nullable) GADNativeAd *resultAd;
@property (nonatomic, strong, nullable) GADAdLoader *mapLoader;
@property (nonatomic, strong, nullable) GADNativeAd *mapAd;

@property (nonatomic, strong, nullable) id launchAd;
@property (nonatomic, strong, nullable) GADInterstitialAd *vpnInterstitial;
@property (nonatomic, strong, nullable) GADInterstitialAd *clickInterstitial;
@property (nonatomic, strong, nullable) GADInterstitialAd *backInterstitial;

@property (nonatomic, strong, nullable, readonly) SVPosterModel *launchModel;

//是否有全屏广告在展示
@property (atomic, assign) BOOL isScreenAdShow;
@property (atomic, assign) BOOL isCanShowLaunchAd;

+ (SVPosterManager *)sharedInstance;
- (void)setupWithComplete:(nullable void(^)(BOOL isSuccess))complete;
- (void)saveAdvertDatas;

- (void)setupCckWithType:(SVAdvertLocationType)type;
- (void)setupCswWithType:(SVAdvertLocationType)type;
- (void)setupIsShow:(BOOL)isShow type:(SVAdvertLocationType)type;
- (void)setupIsLoad:(BOOL)isLoad type:(SVAdvertLocationType)type;

- (BOOL)isCanShowAdvertWithType:(SVAdvertLocationType)type;
- (BOOL)isCanLoadAdvertWithType:(SVAdvertLocationType)type;
- (BOOL)isShowLimt:(SVAdvertLocationType)type;
- (BOOL)isCacheValidWithType:(SVAdvertLocationType)type;
- (BOOL)isTimeOut:(NSTimeInterval)time interval:(NSTimeInterval)interval;

- (void)requestLaunchAd;
- (void)requestScreenAdWithType:(SVAdvertLocationType)type;
- (void)syncRequestScreenAdWithType:(SVAdvertLocationType)type timeout:(NSTimeInterval)timeout complete:(void(^)(BOOL isSuccess))complete;
- (void)syncRequestNativeAdWithType:(SVAdvertLocationType)type complete:(void(^)(BOOL isSuccess))complete;
- (void)requestNativeAdWithType:(SVAdvertLocationType)type;

- (void)resetAdLoad;
- (BOOL)resetAdShow;
- (void)resetAd;

- (nullable SVPosterModel *)getAdvertModelWithType:(SVAdvertLocationType)type;
- (void)paidAdWithValue:(GADAdValue *)value;
- (void)advertLogFailedWithType:(SVAdvertLocationType)type error:(NSString *)msg;

- (NSArray *)sortAds:(NSArray <SVAdInfoModel *> *)ads;

- (void)printWithModel:(SVPosterModel *)model metaModel:(nullable SVAdInfoModel *)metaModel logType:(SVPrintType)logType extra:(nullable NSString *)extra;

//进入或回到对应界面需要进行的处理
- (void)enterLaunch;
- (void)enterHome;
- (void)tripVpn;
- (void)enterResult;
- (void)enterServer;
- (void)enterBrowser;
- (void)enterMap;

- (void)enterForeground;
@end

NS_ASSUME_NONNULL_END
