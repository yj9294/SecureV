//
//  SVAdAllType.h
//  SecureVPN
//
//  Created by  sevurevpn on 2024/3/7.
//

#ifndef SVAdAllType_h
#define SVAdAllType_h

typedef NS_ENUM(NSUInteger, SVAdvertLocationType) {
    SVAdvertLocationTypeLaunch = 0, //启动插屏
    SVAdvertLocationTypeVpn, //vpn连接/断开插屏
    SVAdvertLocationTypeClick, //判断用户模式，点击服务器入口按钮、browser、map
    SVAdvertLocationTypeBack, //返回插屏
    SVAdvertLocationTypeHomeNative, //主页原生广告
    SVAdvertLocationTypeResultNative, //连接结果页原生广告
    SVAdvertLocationTypeMapNative, //地图页原生广告
    SVAdvertLocationTypeUnknow,
};

typedef NS_ENUM(NSUInteger, SVAdvertType) {
    SVAdvertTypeInterstitial = 0,
    SVAdvertTypeOpen,
    SVAdvertTypeNative,
//    SVAdvertTypeBanner,
};

#endif /* SVAdAllType_h */
