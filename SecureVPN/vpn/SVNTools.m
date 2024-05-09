//
//  SVNTools.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/21.
//

#import "SVNTools.h"
#import "SVTools.h"
#import "SVFbHandle.h"
#import <AFNetworking/AFNetworking.h>

#ifdef DEBUG
static NSString * const VN_BaseUrl = @"https://test.ccmmanager.online";
#else
static NSString * const VN_BaseUrl = @"https://api.ccmmanager.online";
#endif

typedef NS_ENUM(NSUInteger, SVNUploadType) {
    SVNUploadTypeShow = 0,
    SVNUploadTypePurchase,
};

typedef NS_ENUM(NSUInteger, SVNUploadStatus) {
    SVNUploadStatusStart = 0,
    SVNUploadStatusSuccess,
    SVNUploadStatusFail
};

@implementation SVNTools

+ (void)isChina:(nullable void(^)(BOOL result))complete {
    static dispatch_queue_t queue = nil;
    if (queue == nil) {
        queue = dispatch_queue_create("com.qr.code.vp.country", DISPATCH_QUEUE_SERIAL);
    }
    dispatch_async(queue, ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *country = [[NSUserDefaults standardUserDefaults] stringForKey:@"country"];
        if (country.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([country isEqualToString:@"CN"]) {
                    if (complete) complete(YES);
                } else {
                    if (complete) complete(NO);
                }
            });
            dispatch_semaphore_signal(semaphore);
        } else {
            //去请求
            [self countryWithComplete:^(NSString *country) {
                [[NSUserDefaults standardUserDefaults] setObject:country forKey:@"country"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([country isEqualToString:@"CN"]) {
                        if (complete) complete(YES);
                    } else {
                        if (complete) complete(NO);
                    }
                });
                dispatch_semaphore_signal(semaphore);
            }];
        }
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC);
        dispatch_semaphore_wait(semaphore, timeout);
    });
}



+ (void)countryWithComplete:(void(^)(NSString *country))complete {
    __block BOOL isResult = NO;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:@"https://ipinfo.io/json" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        svdispatch_async_main_safe(^{
            if (!isResult) {
                isResult = YES;
                NSString *country = responseObject[@"country"];
                if (complete) complete(country);
            }
        });
    } failure:nil];
    
    [manager GET:@"https://ipapi.co/json/" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        svdispatch_async_main_safe(^{
            if (!isResult) {
                isResult = YES;
                NSString *country = responseObject[@"country_code"];
                if (complete) complete(country);
            }
        });
    } failure:nil];
    
    [manager GET:@"https://ipwhois.app/json/" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        svdispatch_async_main_safe(^{
            if (!isResult) {
                isResult = YES;
                NSString *country = responseObject[@"country_code"];
                if (complete) complete(country);
            }
        });
    } failure:nil];
}

+ (void)locationCoordinateWithComplete:(void(^)(BOOL isSuccess, SVNetInfoModel * _Nullable model))complete {
    NSArray *servers = [self serverList];
    int randomNumber = arc4random_uniform(3);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:servers[randomNumber] parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (randomNumber == 0) {
            NSString *loc = responseObject[@"loc"];
            NSArray *locArray = [loc componentsSeparatedByString:@","];
            double latitude = [locArray.firstObject doubleValue];
            double longitude = [locArray.lastObject doubleValue];
            SVNetInfoModel *model = [[SVNetInfoModel alloc] init];
            model.ip = responseObject[@"ip"];
            model.latitude = latitude;
            model.longitude = longitude;
            model.countryCode = responseObject[@"country"];
            model.country = responseObject[@"country"];
            model.city = responseObject[@"city"];
            complete(YES, model);
        } else {
            double latitude = [responseObject[@"latitude"] doubleValue];
            double longitude = [responseObject[@"longitude"] doubleValue];
            SVNetInfoModel *model = [[SVNetInfoModel alloc] init];
            model.ip = responseObject[@"ip"];
            model.latitude = latitude;
            model.longitude = longitude;
            model.countryCode = responseObject[@"country_code"];
            model.city = responseObject[@"city"];
            if (randomNumber == 1) {
                model.country = responseObject[@"country_name"];
            } else {
                model.country = responseObject[@"country"];
            }
            complete(YES, model);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        complete(NO, nil);
    }];
}

+ (NSArray *)serverList {
    static NSArray *array = nil;
    if (array == nil) {
        array = @[
            @"https://ipinfo.io/json",
            @"https://ipapi.co/json/",
            @"https://ipwhois.app/json/"];
    }
    return array;
}

+ (NSString *)randomIp {
    NSArray *array = [SVFirebase getVNConfig];
    if (array > 0) {
        float total = 0.0;
        for (NSDictionary *dict in array) {
            total += [dict[@"probability"] floatValue];
        }
        
        float random = (float)arc4random_uniform(UINT32_MAX) / UINT32_MAX * total;
        float cumulative = 0.0;
        NSDictionary *selectDict = nil;
        for (NSDictionary *dict in array) {
            cumulative += [dict[@"probability"] floatValue];
            if (cumulative >= random) {
                selectDict = dict;
                break;
            }
        }
        return selectDict[@"ip"];
    } else {
        return @"104.200.17.204";
    }
}

+ (nullable SVServerModel *)randomServer {
    static SVServerModel *selectModel = nil;
    if (selectModel == nil) {
        NSArray *array = [SVFirebase getVNModels];
        if (array > 0) {
            float total = 0.0;
            for (SVServerModel *model in array) {
                total += model.probability;
            }
            
            float random = (float)arc4random_uniform(UINT32_MAX) / UINT32_MAX * total;
            float cumulative = 0.0;
            for (SVServerModel *model in array) {
                cumulative += model.probability;
                if (cumulative >= random) {
                    selectModel = model;
                    break;
                }
            }
            return selectModel;
        }
    }
    return selectModel;
}

+ (void)getServerWithIp:(NSString *)ip complete:(void(^)(SVServerModel * _Nullable model))complete {
    NSArray *array = [SVFirebase getVNConfig];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ip == %@", ip];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:predicate];
    if (filteredArray.count > 0) {
        SVServerModel *model = [[SVServerModel alloc] init];
        [model setValuesForKeysWithDictionary:filteredArray.firstObject];
        if (complete) complete(model);
    } else {
        [self locationCoordinateWithComplete:^(BOOL isSuccess, SVNetInfoModel * _Nullable model) {
            if (isSuccess) {
                SVServerModel *serverModel = [[SVServerModel alloc] init];
                serverModel.ip = model.ip;
                serverModel.countryCode = model.countryCode;
                serverModel.name = model.country;
                if (complete) complete(serverModel);
            } else {
                if (complete) complete(nil);
            }
        }];
    }
}

+ (void)uploadVpnAdShowWithIp:(NSString *)ip {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *version = [SVTools sv_getAppVersion];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:2];
    [headers setValue:bundleIdentifier forKey:@"CVF"];
    [headers setValue:version forKey:@"VBB"];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    [params setValue:ip forKey:@"ip"];
    [params setValue:@(1) forKey:@"cc"];
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    [params setValue:@(time) forKey:@"tt"];
    
    NSString *path = @"cv/maa/";
    [self requestWithUrl:[NSString stringWithFormat:@"%@/%@", VN_BaseUrl, path] headers:headers params:params type:SVNUploadTypeShow];
}

+ (void)uploadVpnAdPurchaseWithIp:(NSString *)ip purchase:(double)purchase {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *version = [SVTools sv_getAppVersion];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:2];
    [headers setValue:bundleIdentifier forKey:@"CVF"];
    [headers setValue:version forKey:@"VBB"];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
    [params setValue:ip forKey:@"ip"];
    NSInteger cc = purchase * 10000000;
    [params setValue:@(cc) forKey:@"cc"];
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    [params setValue:@(time) forKey:@"tt"];
    
    NSString *path = @"cv/mab/";
    [self requestWithUrl:[NSString stringWithFormat:@"%@/%@", VN_BaseUrl, path] headers:headers params:params type:SVNUploadTypePurchase];
}

+ (void)requestWithUrl:(NSString *)url headers:(NSDictionary *)headers params:(NSDictionary *)params type:(SVNUploadType)type {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger count = 3;
        for (int i = 0; i < count; i++) {
            BOOL result = [self requestSyncWithUrl:url headers:headers params:params type:type];
            if (result) {
                break;
            } else {
                sleep(10);
            }
        }
    });
}

+ (BOOL)requestSyncWithUrl:(NSString *)url headers:(NSDictionary *)headers params:(NSDictionary *)params type:(SVNUploadType)type {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL isSuccess = NO;
    if (type == SVNUploadTypePurchase) {
        NSString *name = [self getEventWithType:type status:SVNUploadStatusStart];
        [SVStatisticAnalysis saveEvent:name params:nil];
    }
    [manager POST:url parameters:params headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        isSuccess = YES;
        if (type == SVNUploadTypePurchase) {
            NSString *name = [self getEventWithType:type status:SVNUploadStatusSuccess];
            [SVStatisticAnalysis saveEvent:name params:nil];
        }
        dispatch_semaphore_signal(semaphore);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (type == SVNUploadTypePurchase) {
            NSString *name = [self getEventWithType:type status:SVNUploadStatusFail];
            [SVStatisticAnalysis saveEvent:name params:@{@"type": error.localizedDescription}];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return isSuccess;
}

+ (NSString *)getEventWithType:(SVNUploadType)type status:(SVNUploadStatus)status {
    NSString *name;
    if (type == SVNUploadTypeShow) {
//        switch (status) {
//            case SVNUploadStatusStart:
//                name = @"zs_req";
//                break;
//            case SVNUploadStatusSuccess:
//                name = @"zs_suc";
//                break;
//            case SVNUploadStatusFail:
//                name = @"zs_fail";
//                break;
//        }
    } else if (type == SVNUploadTypePurchase) {
        switch (status) {
            case SVNUploadStatusStart:
                name = @"vapi_request";
                break;
            case SVNUploadStatusSuccess:
                name = @"vapi_success";
                break;
            case SVNUploadStatusFail:
                name = @"vapi_fail";
                break;
        }
    }
    return name;
}

@end
