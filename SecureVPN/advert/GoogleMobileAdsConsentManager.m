//
//  GoogleMobileAdsConsentManager.m
//  SecureVPN
//
//  Created by SSSS on 27/5/2024.
//

#import "GoogleMobileAdsConsentManager.h"
#import <UserMessagingPlatform/UserMessagingPlatform.h>


@implementation GoogleMobileAdsConsentManager

+ (instancetype)sharedInstance {
  static GoogleMobileAdsConsentManager *shared;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[GoogleMobileAdsConsentManager alloc] init];
  });
  return shared;
}

- (void)gatherConsentFromConsentPresentationViewController:(UIViewController *)viewController
                                  consentGatheringComplete:
                                      (void (^)(NSError *_Nullable))consentGatheringComplete {
    

  UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    
    
  // For testing purposes, you can force a UMPDebugGeography of EEA or not EEA.
//  UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
//#if DEBUG
//    debugSettings.testDeviceIdentifiers = @[ @"8D54C86D-DCA2-45FF-8835-906E6D972B19" ];
//    debugSettings.geography = UMPDebugGeographyEEA;
//#endif

//  parameters.debugSettings = debugSettings;

  // Requesting an update to consent information should be called on every app launch.
  [UMPConsentInformation.sharedInstance
      requestConsentInfoUpdateWithParameters:nil
                           completionHandler:^(NSError *_Nullable requestConsentError) {
                             if (requestConsentError) {
                               consentGatheringComplete(requestConsentError);
                             } else {
//                               [UMPConsentForm
//                                   loadAndPresentIfRequiredFromViewController:viewController
//                                                            completionHandler:^(
//                                                                NSError
//                                                                    *_Nullable loadAndPresentError) {
//                                                              // Consent has been gathered.
//                                                              consentGatheringComplete(
//                                                                  loadAndPresentError);
//                                                            }];
                             }
                           }];
}






@end
