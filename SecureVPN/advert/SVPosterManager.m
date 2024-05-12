//
//  SVPosterManager.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import "SVPosterManager.h"
#import "SVFbHandle.h"
#import "NSObject+SV.h"
#import "SVBaseVC.h"
#import "SVNManager.h"
#import <FirebaseAnalytics/FIRParameterNames.h>
#import <FirebaseAnalytics/FIRAnalytics.h>
#import <FBSDKCoreKit/FBSDKAppEvents.h>


@interface SVPosterManager () <GADNativeAdLoaderDelegate>

@property (nonatomic, strong) dispatch_queue_t adQueue;

@property (nonatomic, strong) NSMutableArray *requestHomeNativeAds;
@property (nonatomic, strong) NSMutableArray *requestResultNativeAds;
@property (nonatomic, strong) NSMutableArray *requestMapNativeAds;

@property (nonatomic, strong, nullable, readwrite) SVPosterModel *launchModel;
@property (nonatomic, strong, nullable) SVPosterModel *vpnModel;
@property (nonatomic, strong, nullable) SVPosterModel *clickModel;
@property (nonatomic, strong, nullable) SVPosterModel *backModel;

@property (nonatomic, strong, nullable) SVPosterModel *homeNativeModel;
@property (nonatomic, strong, nullable) SVPosterModel *resultNativeModel;
@property (nonatomic, strong, nullable) SVPosterModel *mapNativeModel;

@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) float lapo;

@end

@implementation SVPosterManager

+ (SVPosterManager *)sharedInstance {
    static SVPosterManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVPosterManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.adQueue = dispatch_queue_create("com.aw.qr.scan.ad.queue", DISPATCH_QUEUE_CONCURRENT);
        self.isFirst = YES;
        self.isScreenAdShow = NO;
        self.isCanShowLaunchAd = YES;
        self.lapo = 2;
    }
    return self;
}

- (void)setupWithComplete:(nullable void(^)(BOOL isSuccess))complete {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *array = [[SVFirebase.remoteInfo configValueForKey:@"adconfig"] JSONValue];
        if ([array isKindOfClass:[NSArray class]] && array.count == 0) {
            if (complete) complete(NO);
            return;
        }
        
        NSArray *adLists = [weakSelf convertModelsWithArray:array];
        if (weakSelf.isFirst) {
            weakSelf.isFirst = NO;
            NSArray *models = [SVDbAdvertHandle saveDatas:adLists];
            [weakSelf setupAdModels:models];
        } else {
            [weakSelf setupAdModels:adLists];
        }
        if (complete) complete(YES);
    });
}

- (NSArray *)convertModelsWithArray:(NSArray *)array {
    NSMutableArray *adLists = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        SVPosterModel *model = [[SVPosterModel alloc] init];
        NSMutableArray *ads = [NSMutableArray arrayWithCapacity:1];
        model.name = dict[@"name"];
        model.msw = [dict[@"msw"] intValue];
        model.mck = [dict[@"mck"] intValue];
        NSArray *temps = dict[@"advertList"];
        for (NSDictionary *meta in temps) {
            SVAdInfoModel *metaModel = [[SVAdInfoModel alloc] init];
            metaModel.aid = meta[@"aid"];
            metaModel.level = [meta[@"level"] intValue];
            metaModel.type = [meta[@"type"] intValue];
            [ads addObject:metaModel];
        }
        model.advertList = ads;
        [adLists addObject:model];
    }
    return adLists;
}

- (void)setupAdModels:(NSArray *)models {
    for (SVPosterModel *model in models) {
        switch (model.posty) {
            case SVAdvertLocationTypeLaunch:
                if (self.launchModel) {
                    [self setModel:model targetModel:self.launchModel];
                } else {
                    self.launchModel = model;
                }
                break;
            case SVAdvertLocationTypeVpn:
                if (self.vpnModel) {
                    [self setModel:model targetModel:self.vpnModel];
                } else {
                    self.vpnModel = model;
                }
                break;
            case SVAdvertLocationTypeClick:
                if (self.clickModel) {
                    [self setModel:model targetModel:self.clickModel];
                } else {
                    self.clickModel = model;
                }
                break;
            case SVAdvertLocationTypeBack:
                if (self.backModel) {
                    [self setModel:model targetModel:self.backModel];
                } else {
                    self.backModel = model;
                }
                break;
            case SVAdvertLocationTypeHomeNative:
                if (self.homeNativeModel) {
                    [self setModel:model targetModel:self.homeNativeModel];
                } else {
                    self.homeNativeModel = model;
                }
                break;
            case SVAdvertLocationTypeResultNative:
                if (self.resultNativeModel) {
                    [self setModel:model targetModel:self.resultNativeModel];
                } else {
                    self.resultNativeModel = model;
                }
                break;
            case SVAdvertLocationTypeMapNative:
                if (self.mapNativeModel) {
                    [self setModel:model targetModel:self.mapNativeModel];
                } else {
                    self.mapNativeModel = model;
                }
                break;
            default:
                break;
        }
    }
}

- (void)setModel:(SVPosterModel *)model targetModel:(SVPosterModel *)targetModel {
    targetModel.name = model.name;
    targetModel.msw = model.msw;
    targetModel.mck = model.mck;
    targetModel.advertList = model.advertList;
}

- (void)saveAdvertDatas {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:11];
    if (self.launchModel) {
        [array addObject:self.launchModel];
    }
    if (self.vpnModel) {
        [array addObject:self.vpnModel];
    }
    if (self.clickModel) {
        [array addObject:self.clickModel];
    }
    if (self.backModel) {
        [array addObject:self.backModel];
    }
    if (self.homeNativeModel) {
        [array addObject:self.homeNativeModel];
    }
    if (self.resultNativeModel) {
        [array addObject:self.resultNativeModel];
    }
    if (self.mapNativeModel) {
        [array addObject:self.mapNativeModel];
    }
    
    [SVDbAdvertHandle saveDatas:array];
}

//- (void)paidAdWithValue:(GADAdValue *)value ad:(id)ad {
//    GADResponseInfo *info;
//    if ([ad isKindOfClass:[GADAppOpenAd class]]) {
//        info = ((GADAppOpenAd *)ad).responseInfo;
//    } else if ([ad isKindOfClass:[GADInterstitialAd class]]) {
//        info = ((GADInterstitialAd *)ad).responseInfo;
//    } else if ([ad isKindOfClass:[GADNativeAd class]]) {
//        info = ((GADNativeAd *)ad).responseInfo;
//    } else if ([ad isKindOfClass:[GADBannerView class]]) {
//        info = ((GADBannerView *)ad).responseInfo;
//    }
//    
//    if (info) {
//        [self paidAdWithValue:value info:info];
//    }
//}
//
//- (void)paidAdWithValue:(GADAdValue *)value info:(GADResponseInfo *)info {
//    //上报face book
//    double realValue = [value.value doubleValue];
//    
//    [FBSDKAppEvents.shared logPurchase:realValue currency:value.currencyCode parameters:@{@"precisionType": @(value.precision), @"adNetwork": info.loadedAdNetworkResponseInfo.adSourceName}];
//    
//    //上报firebace
//    [SVFirebase logEventWithName:@"Ad_Impression_Revenue" parameters:@{
//        kFIRParameterValue: @(realValue),
//        kFIRParameterCurrency: value.currencyCode,
//        @"precisionType": @(value.precision),
//        @"adNetwork": info.loadedAdNetworkResponseInfo.adSourceName
//    }];
//    
//    if ([SVNManager shared].vnStatus == NEVPNStatusConnected) {
//        [SVNTools uploadVpnAdPurchaseWithIp:[SVNManager shared].profile.serverAddress purchase:realValue];
//    }
//}

- (void)paidAdWithValue:(GADAdValue *)value {
    //上报face book
    double realValue = [value.value doubleValue];
    
    [FBSDKAppEvents.shared logPurchase:realValue currency:value.currencyCode];
    
    // firebase
    [FIRAnalytics logEventWithName:@"upload_revenue" parameters:[NSDictionary dictionaryWithObjectsAndKeys:@(realValue), kFIRParameterValue, value.currencyCode, kFIRParameterCurrency,nil]];
        
    if ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected) {
        [SVNTools uploadVpnAdPurchaseWithIp:[SVNManager sharedInstance].profile.serverAddress purchase:realValue];
    }
}

- (void)advertLogFailedWithType:(SVAdvertLocationType)type error:(NSString *)msg {
    [self printWithModel:[self getAdvertModelWithType:type] metaModel:nil logType:SVPrintTypeShowFail extra:msg];
}

- (NSArray *)sortAds:(NSArray <SVAdInfoModel *> *)ads {
    if (ads.count > 1) {
        NSMutableArray *alls = [NSMutableArray arrayWithArray:ads];
        NSSet *set = [NSSet setWithArray:alls];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"level" ascending:NO];
        NSArray *newArray = [[set allObjects] sortedArrayUsingDescriptors:@[sort]];
        return newArray;
    } else {
        return ads;
    }
}

- (nullable id)getAdvertWithType:(SVAdvertLocationType)type {
    id ad = nil;
    switch (type) {
        case SVAdvertLocationTypeLaunch:
            ad = self.launchAd;
            break;
        case SVAdvertLocationTypeVpn:
            ad = self.vpnInterstitial;
            break;
        case SVAdvertLocationTypeClick:
            ad = self.clickInterstitial;
            break;
        case SVAdvertLocationTypeBack:
            ad = self.backInterstitial;
            break;
        case SVAdvertLocationTypeHomeNative:
            ad = self.homeAd;
            break;
        case SVAdvertLocationTypeResultNative:
            ad = self.resultAd;
            break;
        case SVAdvertLocationTypeMapNative:
            ad = self.mapAd;
            break;
        default:
            break;
    }
    return ad;
}

- (nullable SVPosterModel *)getAdvertModelWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = nil;
    switch (type) {
        case SVAdvertLocationTypeLaunch:
            model = self.launchModel;
            break;
        case SVAdvertLocationTypeVpn:
            model = self.vpnModel;
            break;
        case SVAdvertLocationTypeClick:
            model = self.clickModel;
            break;
        case SVAdvertLocationTypeBack:
            model = self.backModel;
            break;
        case SVAdvertLocationTypeHomeNative:
            model = self.homeNativeModel;
            break;
        case SVAdvertLocationTypeResultNative:
            model = self.resultNativeModel;
            break;
        case SVAdvertLocationTypeMapNative:
            model = self.mapNativeModel;
            break;
        default:
            break;
    }
    return model;
}

- (void)printWithModel:(SVPosterModel *)model metaModel:(nullable SVAdInfoModel *)metaModel logType:(SVPrintType)logType extra:(nullable NSString *)extra {
#ifdef DEBUG
    NSString *message = [NSString stringWithFormat:@"\n<AD> name: '%@'%@", model.name, metaModel ? [NSString stringWithFormat:@" priority: %ld\n", metaModel.level] : @"\n"];
    switch (logType) {
        case SVPrintTypeStartLoad:
            message = [message stringByAppendingFormat:@"<AD> load info: start loading '%@' ad", model.name];
            break;
        case SVPrintTypeNotLoad:
            message = [message stringByAppendingFormat:@"<AD> load limit: '%@' ad cannot be load", model.name];
            break;
        case SVPrintTypeLoadSuccess:
            message = [message stringByAppendingFormat:@"<AD> load success: '%@' ad load Success", model.name];
            break;
        case SVPrintTypeLoadFail:
            message = [message stringByAppendingFormat:@"<AD> 请注意，这里有个错误...\n<AD> 请注意，这里有个错误...\n<AD> load error: '%@' ad load Failed, %@", model.name, metaModel.aid];
            break;
        case SVPrintTypeShowSuccess:
            message = [message stringByAppendingFormat:@"<AD> show success: '%@' ad show Success", model.name];
            break;
        case SVPrintTypeShowFail:
            message = [message stringByAppendingFormat:@"<AD> 请注意，这里有个错误...\n<AD> 请注意，这里有个错误...\n<AD> show error: '%@' ad load Failed %@", model.name, metaModel.aid];
            break;
        case SVPrintTypeNotShow:
            message = [message stringByAppendingFormat:@"<AD> show limit: '%@' ad cannot be displayed", model.name];
            break;
        case SVPrintTypeHasCache:
            message = [message stringByAppendingFormat:@"<AD> cache hit: '%@' ad have cache", model.name];
            break;
        default:
            break;
    }
    if (extra.length > 0) {
        message = [message stringByAppendingFormat:@"\n<AD> %@", extra];
    }
//    message = [message stringByAppendingFormat:@""];
    NSLog(@"%@", message);
#endif
}

//#pragma mark - 广告请求

- (void)syncRequestNativeAdWithType:(SVAdvertLocationType)type complete:(void(^)(BOOL isSuccess))complete {
    [self syncRequestNativeAdWithType:type timeout:20 complete:complete];
}

- (void)syncRequestNativeAdWithType:(SVAdvertLocationType)type timeout:(NSTimeInterval)timeout complete:(void(^)(BOOL isSuccess))complete {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (![self isCanShowAdvertWithType:type model:model]) {
        if (complete) complete(NO);
        return;
    }
    //判断有无缓存
    id ad = [self getAdvertWithType:type];
    if (ad && [self isCacheValidWithType:type]) {
        [self printWithModel:model metaModel:nil logType:SVPrintTypeHasCache extra:nil];
        if (complete) complete(YES);
        return;
    }
    
    BOOL isLoad = model.ild == 0 ? NO : YES;
    if (isLoad) {
        isLoad = ![self isTimeOut:model.tsld interval:20];
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!isLoad) {
            [weakSelf requestNativeAdWithType:type];
        }
        //wait 20s
        int count = 0;
        BOOL isSuccess = NO;
        while (count < timeout) {
            id newAd = [weakSelf getAdvertWithType:type];
            if (newAd) {
                isSuccess = YES;
                break;
            }
            if (!model.ild) {
                break;
            }
            sleep(1);
            count += 1;
        }
        if (complete) complete(isSuccess);
    });
}

- (void)requestNativeAdWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (!model) {
        return;
    }
    if (model.ild) {
        model.ild = ![self isTimeOut:model.tsld interval:20];
    }
    if (model.ild) return;
    if ([self getAdvertWithType:model.posty] && [self isCacheValidWithType:model.posty]) {
        [self printWithModel:model metaModel:nil logType:SVPrintTypeHasCache extra:nil];
        return;
    }
    
    [self setupIsLoad:YES type:model.posty];
    NSArray <SVAdInfoModel *> *ads = model.advertList;
    if (model.advertList.count > 1) {
        ads = [self sortAds:model.advertList];
    }
    SVAdInfoModel *ad = ads.firstObject;
    switch (ad.type) {
        case SVAdvertTypeNative: {
            if (model.posty == SVAdvertLocationTypeHomeNative) {
                self.requestHomeNativeAds = [NSMutableArray arrayWithArray:ads];
                [self requestNativeAdWithModel:model metaModel:ad];
            } else if (model.posty == SVAdvertLocationTypeResultNative) {
                self.requestResultNativeAds = [NSMutableArray arrayWithArray:ads];
                [self requestNativeAdWithModel:model metaModel:ad];
            } else if (model.posty == SVAdvertLocationTypeMapNative) {
                self.requestMapNativeAds = [NSMutableArray arrayWithArray:ads];
                [self requestNativeAdWithModel:model metaModel:ad];
            }
            break;
        }
//        case SVAdvertTypeBanner:
//            break;
        default:
            break;
    }
}

- (void)requestNativeAdWithModel:(SVPosterModel *)model metaModel:(SVAdInfoModel *)ad {
//    GADMultipleAdsAdLoaderOptions *multipleAdsOptions =
//        [[GADMultipleAdsAdLoaderOptions alloc] init];
//    multipleAdsOptions.numberOfAds = 5;
    GADAdLoader *adLoader = [[GADAdLoader alloc] initWithAdUnitID:ad.aid rootViewController:nil adTypes:@[GADAdLoaderAdTypeNative] options:nil];
    adLoader.delegate = self;
    [self printWithModel:model metaModel:ad logType:SVPrintTypeStartLoad extra:nil];
    [adLoader loadRequest:[GADRequest request]];
    if (model.posty == SVAdvertLocationTypeHomeNative) {
        self.homeLoader = adLoader;
    } else if (model.posty == SVAdvertLocationTypeResultNative) {
        self.resultLoader = adLoader;
    } else if (model.posty == SVAdvertLocationTypeMapNative) {
        self.mapLoader = adLoader;
    }
}

- (void)syncRequestScreenAdWithType:(SVAdvertLocationType)type timeout:(NSTimeInterval)timeout complete:(void(^)(BOOL isSuccess))complete {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (![self isCanShowAdvertWithType:type model:model]) {
        if (complete) complete(NO);
        return;
    }
    
    id ad = [self getAdvertWithType:type];
    if (ad && [self isCacheValidWithType:type]) {
        [self printWithModel:model metaModel:nil logType:SVPrintTypeHasCache extra:nil];
        if (complete) complete(YES);
        return;
    }
    
    BOOL isLoad = model.ild;
    if (isLoad) {
        isLoad = ![self isTimeOut:model.tsld interval:20];
    }
    
    __block BOOL isComplete = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (isLoad) {
            //wait 20s
            int count = 0;
            BOOL isSuccess = NO;
            while (count < timeout) {
                id newAd = [weakSelf getAdvertWithType:type];
                if (newAd) {
                    isSuccess = YES;
                    break;
                }
                
                if (!model.ild) {
                    break;
                }
                sleep(1);
                count += 1;
            }
            if (complete) complete(isSuccess);
        } else {
            BOOL isSuccess = NO;
            isSuccess = [weakSelf syncRequestScreenAdWithModel:model];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isComplete) {
                    isComplete = YES;
                    if (complete) complete(isSuccess);
                }
            });
        }
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!isComplete) {
            isComplete = YES;
            if (complete) complete(NO);
        }
    });
}

- (BOOL)syncRequestScreenAdWithModel:(SVPosterModel *)model {
    [self setupIsLoad:YES type:model.posty];
    NSArray <SVAdInfoModel *> *ads = model.advertList;
    if (model.advertList.count > 1) {
        ads = [self sortAds:model.advertList];
    }
    __block BOOL isSuccess = NO;
    __weak typeof(self) weakSelf = self;
    for (SVAdInfoModel *ad in ads) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        switch (ad.type) {
            case SVAdvertTypeInterstitial: {
                [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeStartLoad extra:nil];
                [weakSelf requestInterstitialAd:model infoModel:ad complete:^(GADInterstitialAd *ad) {
                    if (ad)  {
                        isSuccess = YES;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
                break;
            }
            case SVAdvertTypeOpen: {
                [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeStartLoad extra:nil];
                [weakSelf requestOpenAd:model infoModel:ad complete:^(GADAppOpenAd *ad) {
                    if (ad) {
                        isSuccess = YES;
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
                break;
            }
            default:
                dispatch_semaphore_signal(semaphore);
                break;
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (isSuccess) break;
    }
    [self setupIsLoad:NO type:model.posty];
    if (model.posty == SVAdvertLocationTypeLaunch) {
        [self handleLaunchAd];
    }
    return isSuccess;
}

- (void)requestScreenAdWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (![self isCanLoadAdvertWithType:model.posty]) {
        return;
    }
    [self setupIsLoad:YES type:model.posty];
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.adQueue, ^{
        NSArray <SVAdInfoModel *> *ads = model.advertList;
        if (model.advertList.count > 1) {
            ads = [weakSelf sortAds:model.advertList];
        }
        
        for (SVAdInfoModel *ad in ads) {
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
             __block BOOL isSuccess = NO;
            switch (ad.type) {
                case SVAdvertTypeInterstitial: {
                    [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeStartLoad extra:nil];
                    [weakSelf requestInterstitialAd:model infoModel:ad complete:^(GADInterstitialAd *ad) {
                        if (ad)  {
                            isSuccess = YES;
                        }
                        dispatch_semaphore_signal(semaphore);
                    }];
                    break;
                }
                case SVAdvertTypeOpen: {
                    [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeStartLoad extra:nil];
                    [weakSelf requestOpenAd:model infoModel:ad complete:^(GADAppOpenAd *ad) {
                        if (ad) {
                            isSuccess = YES;
                        }
                        dispatch_semaphore_signal(semaphore);
                    }];
                    break;
                }
                default:
                    dispatch_semaphore_signal(semaphore);
                    break;
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (isSuccess) break;
        }
        [weakSelf setupIsLoad:NO type:model.posty];
        if (model.posty == SVAdvertLocationTypeLaunch) {
            [weakSelf handleLaunchAd];
        }
    });
}

- (void)handleLaunchAd {
    if (self.launchAd) {
        self.lapo = 2;
    } else {
        self.lapo += 1;
        float time = powf(2, self.lapo);
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf requestLaunchAd];
        });
    }
}

- (void)requestLaunchAd {
    [self requestScreenAdWithType:SVAdvertLocationTypeLaunch];
}

- (void)requestOpenAd:(SVPosterModel *)model infoModel:(SVAdInfoModel *)ad complete:(void(^)(GADAppOpenAd *ad))complete {
    
    NSString *adid = ad.aid;
    if (self.launchAd && [self isCacheValidWithType:model.posty]) {
        [self printWithModel:model metaModel:ad logType:SVPrintTypeHasCache extra:nil];
        complete(self.launchAd);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [GADAppOpenAd loadWithAdUnitID:adid request:[GADRequest request] completionHandler:^(GADAppOpenAd *_Nullable appOpenAd, NSError *_Nullable error) {
        if (error) {
            [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeLoadFail extra:[NSString stringWithFormat:@"reason => %@", [error localizedDescription]]];
            if (complete) complete(nil);
            return;
        }
        weakSelf.launchAd = appOpenAd;
        [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeLoadSuccess extra:nil];
//        __weak typeof(appOpenAd) weakAd = appOpenAd;
//        appOpenAd.paidEventHandler = ^(GADAdValue * _Nonnull value) {
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            __strong typeof(weakAd) strongAd = weakAd;
//            [strongSelf paidAdWithValue:value ad:strongAd];
//        };
        if (complete) complete(appOpenAd);
  }];
}

- (void)requestInterstitialAd:(SVPosterModel *)model infoModel:(SVAdInfoModel *)ad complete:(void(^)(GADInterstitialAd *ad))complete {
    //判断缓存情况
    SVAdvertLocationType type = model.posty;
    NSString *adid = ad.aid;
    GADInterstitialAd *cacheAd = [self getAdvertWithType:type];
    
    if (cacheAd && [self isCacheValidWithType:model.posty]) {
        [self printWithModel:model metaModel:ad logType:SVPrintTypeHasCache extra:nil];
        if (complete) complete(cacheAd);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [GADInterstitialAd loadWithAdUnitID:adid request:[GADRequest request] completionHandler:^(GADInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
        if (error) {
            [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeLoadFail extra:[NSString stringWithFormat:@"reason => %@", [error localizedDescription]]];
            if (complete) complete(nil);
          return;
        }
        
        switch (type) {
            case SVAdvertLocationTypeLaunch:
                self.launchAd = interstitialAd;
                break;
            case SVAdvertLocationTypeVpn:
                self.vpnInterstitial = interstitialAd;
                break;
            case SVAdvertLocationTypeClick:
                self.clickInterstitial = interstitialAd;
                break;
            case SVAdvertLocationTypeBack:
                self.backInterstitial = interstitialAd;
                break;
            default:
                break;
        }
        [weakSelf printWithModel:model metaModel:ad logType:SVPrintTypeLoadSuccess extra:nil];
//        interstitialAd.paidEventHandler = ^(GADAdValue * _Nonnull value) {
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            [strongSelf paidAdWithValue:value];
//        };
        
        [weakSelf setupTldWithType:type];
        if (complete) complete(interstitialAd);
    }];
}

//#pragma mark - model更新和状态检查

- (void)setupCckWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    model.cck += 1;
}

- (void)setupCswWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    [self printWithModel:model metaModel:nil logType:SVPrintTypeShowSuccess extra:nil];
    //更新展示次数，正在展示和展示时间三个字段
    model.csw += 1;
    model.tsw = [[NSDate date] timeIntervalSince1970];
    model.isw = YES;
    if ([SVNManager sharedInstance].vnStatus == NEVPNStatusConnected) {
        [SVNTools uploadVpnAdShowWithIp:[SVNManager sharedInstance].profile.serverAddress];
    }
}

- (void)setupIsShow:(BOOL)isShow type:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    model.isw = isShow;
}

- (void)setupIsLoad:(BOOL)isLoad type:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    model.ild = isLoad;
    if (isLoad == 1) {
        model.tsld = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)setupTldWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    model.tld = [[NSDate date] timeIntervalSince1970];
}

- (BOOL)isCanLoadAdvertWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    return [self isCanLoadAdvertWithType:type model:model];
}

- (BOOL)isCanLoadAdvertWithType:(SVAdvertLocationType)type model:(SVPosterModel *)model {
    BOOL isLoad = model.ild;
    if (model.ild) {
        isLoad = ![self isTimeOut:model.tsld interval:20];
    }
    
    if ((model == nil) || model.isw || isLoad || (model.csw >= model.msw) || (model.cck >= model.mck)) {
        [self printWithModel:[self getAdvertModelWithType:type] metaModel:nil logType:SVPrintTypeNotLoad extra:[NSString stringWithFormat:@"reason => name:%@ isShow:%d isLoad:%d currentShow/maxShow:%d/%d currentClick/maxClick:%d/%d", model.name, model.isw, isLoad, model.csw, model.msw, model.cck, model.mck]];
        return NO;
    }
    
    //判断是否是激进模式
    if (type == SVAdvertLocationTypeClick) {
        NSString *userModel = [SVFirebase getAppMode];
        if ([userModel isEqualToString:@"bs"]) {
            [self printWithModel:[self getAdvertModelWithType:type]  metaModel:nil logType:SVPrintTypeNotLoad extra:[NSString stringWithFormat:@"reason => name:%@ userModel:%@", model.name, userModel]];
            return NO;
        }
    }
    return YES;
}

- (BOOL)isCanShowAdvertWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    return [self isCanShowAdvertWithType:type model:model];
}

- (BOOL)isCanShowAdvertWithType:(SVAdvertLocationType)type model:(SVPosterModel *)model {
    if ((model == nil) || model.isw || (model.csw >= model.msw) || (model.cck >= model.mck)) {
        [self printWithModel:[self getAdvertModelWithType:type]  metaModel:nil logType:SVPrintTypeNotShow extra:[NSString stringWithFormat:@"reason => name:%@ isShow:%d currentShow/maxShow:%d/%d currentClick/maxClick:%d/%d", model.name, model.isw, model.csw, model.msw, model.cck, model.mck]];
        return NO;
    }
    
    //判断是否是激进模式
    if (type == SVAdvertLocationTypeClick) {
        NSString *userModel = [SVFirebase getAppMode];
        if ([userModel isEqualToString:@"bs"]) {
            [self printWithModel:[self getAdvertModelWithType:type]  metaModel:nil logType:SVPrintTypeNotShow extra:[NSString stringWithFormat:@"reason => name:%@ userModel:%@", model.name, userModel]];
            return NO;
        }
    }
    
    //判断是否在后台
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        [self printWithModel:[self getAdvertModelWithType:type]  metaModel:nil logType:SVPrintTypeNotShow extra:[NSString stringWithFormat:@"reason => name:%@, The application is not in an active state", model.name]];
        return NO;
    }
    return YES;
}

- (BOOL)isShowLimt:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (model == nil) {
        return YES;
    }
    
    if (model.csw >= model.msw) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isTimeOut:(NSTimeInterval)time interval:(NSTimeInterval)interval {
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeInterval = fabs(date - time);
    if (timeInterval > interval) {
        return YES;
    } else {
        return NO;
    }
}

//判断缓存是否有效
- (BOOL)isCacheValidWithType:(SVAdvertLocationType)type {
    SVPosterModel *model = [self getAdvertModelWithType:type];
    if (model.tld != 0) {
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval timeInterval = fabs(time - model.tld);
        if (timeInterval > 3000) {
            return NO;
        }
    }
    return YES;
}

- (void)resetAd {
    self.launchModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.vpnModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.clickModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.backModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.homeNativeModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.resultNativeModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    self.mapNativeModel.tld = [[NSDate date] timeIntervalSince1970] - 4000;
    [self resetAdLoad];
    self.launchModel.ild = false;
    
    self.launchModel.isw = false;
    self.vpnModel.isw= false;
    self.clickModel.isw = false;
    self.backModel.isw = false;
    self.homeNativeModel.isw = false;
    self.resultNativeModel.isw = false;
    self.mapNativeModel.isw = false;
}

- (void)resetAdLoad {
    self.vpnModel.ild = false;
    self.clickModel.ild = false;
    self.backModel.ild = false;
    self.homeNativeModel.ild = false;
    self.resultNativeModel.ild = false;
    self.mapNativeModel.ild = false;
}

- (BOOL)resetAdShow {
    BOOL hasShow = NO;
    if (self.vpnModel.isw) {
        self.vpnModel.isw = false;
        hasShow = YES;
    }
    if (self.clickModel.isw) {
        self.clickModel.isw = false;
        hasShow = YES;
    }
    if (self.backModel.isw) {
        self.backModel.isw = false;
        hasShow = YES;
    }
    if (self.homeNativeModel.isw) {
        self.homeNativeModel.isw = false;
    }
    if (self.resultNativeModel.isw) {
        self.resultNativeModel.isw = false;
    }
    if (self.mapNativeModel.isw) {
        self.mapNativeModel.isw = false;
    }
    return hasShow;
}

#pragma mark - GADNativeAdLoaderDelegate

- (void)adLoader:(GADAdLoader *)adLoader didReceiveNativeAd:(GADNativeAd *)nativeAd {
//    nativeAd.delegate = self;
    SVAdvertLocationType type = SVAdvertLocationTypeUnknow;
    if (adLoader == self.homeLoader) {
        self.homeAd = nativeAd;
        type = SVAdvertLocationTypeHomeNative;
        [self printWithModel:[self getAdvertModelWithType:type] metaModel:((SVAdInfoModel *)self.requestHomeNativeAds.firstObject) logType:SVPrintTypeLoadSuccess extra:nil];
        self.requestHomeNativeAds = nil;
        
    } else if (adLoader == self.resultLoader) {
        self.resultAd = nativeAd;
        type = SVAdvertLocationTypeResultNative;
        [self printWithModel:[self getAdvertModelWithType:type] metaModel:((SVAdInfoModel *)self.requestResultNativeAds.firstObject) logType:SVPrintTypeLoadSuccess extra:nil];
        self.requestResultNativeAds = nil;
        
    } else if (adLoader == self.mapLoader) {
        self.mapAd = nativeAd;
        type = SVAdvertLocationTypeMapNative;
        [self printWithModel:[self getAdvertModelWithType:type] metaModel:((SVAdInfoModel *)self.requestMapNativeAds.firstObject) logType:SVPrintTypeLoadSuccess extra:nil];
        self.requestMapNativeAds = nil;
        
    }
    [self setupTldWithType:type];
    [self setupIsLoad:NO type:type];
}


- (void)adLoader:(nonnull GADAdLoader *)adLoader didFailToReceiveAdWithError:(nonnull NSError *)error {
    SVAdvertLocationType type = SVAdvertLocationTypeUnknow;
    SVAdInfoModel *model = nil;
    if (adLoader == self.homeLoader) {
        type = SVAdvertLocationTypeHomeNative;
        if (self.requestHomeNativeAds.count > 1) {
            [self.requestHomeNativeAds removeObjectAtIndex:0];
            model = self.requestHomeNativeAds.firstObject;
        } else {
            [self setupIsLoad:NO type:type];
            self.requestHomeNativeAds = nil;
        }
        
    } else if (adLoader == self.resultLoader) {
        type = SVAdvertLocationTypeResultNative;
        if (self.requestResultNativeAds.count > 1) {
            [self.requestResultNativeAds removeObjectAtIndex:0];
            model = self.requestResultNativeAds.firstObject;
        } else {
            [self setupIsLoad:NO type:type];
            self.requestResultNativeAds = nil;
        }
        
    } else if (adLoader == self.mapLoader) {
        type = SVAdvertLocationTypeMapNative;
        if (self.requestMapNativeAds.count > 1) {
            [self.requestMapNativeAds removeObjectAtIndex:0];
            model = self.requestMapNativeAds.firstObject;
        } else {
            [self setupIsLoad:NO type:type];
            self.requestMapNativeAds = nil;
        }
        
    }
    
    SVPosterModel *adModel = [[SVPosterManager sharedInstance] getAdvertModelWithType:type];
    [self printWithModel:adModel metaModel:model logType:SVPrintTypeLoadFail extra:[NSString stringWithFormat:@"reason => %@", [error localizedDescription]]];
    
    if (model) {
        [self requestNativeAdWithModel:adModel metaModel:model];
    }
}

#pragma mark - 页面进入和埋点相关

- (void)enterLaunch {
    [SVNTools isChina:nil];
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeVpn];
    [[SVPosterManager sharedInstance] requestNativeAdWithType:SVAdvertLocationTypeHomeNative];
}

- (void)enterHome {
    [SVStatisticAnalysis saveEvent:@"home_show" params:nil];
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeVpn];
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeClick];
    [[SVPosterManager sharedInstance] requestNativeAdWithType:SVAdvertLocationTypeMapNative];
}

//触发连接断开时
- (void)tripVpn {
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeBack];
    [[SVPosterManager sharedInstance] requestNativeAdWithType:SVAdvertLocationTypeResultNative];
}

- (void)enterResult {
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeBack];
}

- (void)enterServer {
    [SVStatisticAnalysis saveEvent:@"server_show" params:nil];
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeBack];
}

- (void)enterBrowser {
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeBack];
}

- (void)enterMap {
    [[SVPosterManager sharedInstance] requestScreenAdWithType:SVAdvertLocationTypeBack];
}

- (void)enterForeground {
    UIViewController *vc = [NSObject getCurrentTopVC];
    if ([vc isKindOfClass:[SVBaseVC class]]) {
        SVBaseVC *basevc = (SVBaseVC *)vc;
        [basevc didVC];
    }
}

@end
