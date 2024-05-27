//
//  GoogleMobileAdsConsentManager.h
//  SecureVPN
//
//  Created by SSSS on 27/5/2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GoogleMobileAdsConsentManager : NSObject

@property(class, atomic, readonly, strong, nonnull) GoogleMobileAdsConsentManager *sharedInstance;

- (void)gatherConsentFromConsentPresentationViewController:(UIViewController *)viewController
                                  consentGatheringComplete:
                                 (void (^)(NSError *_Nullable))consentGatheringComplete;

@end

NS_ASSUME_NONNULL_END
