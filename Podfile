platform :ios, '13.0'
use_frameworks!
use_modular_headers!
target 'SecureVPN' do
  pod 'IQKeyboardManager'
  pod 'lottie-ios'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseRemoteConfig'
  pod 'Google-Mobile-Ads-SDK'
  pod 'YYText'
  pod 'Masonry'
  pod 'AFNetworking'
  pod 'MBProgressHUD'
  pod 'GoogleMobileAdsMediationFacebook'
  pod 'NetSpeed'
  pod 'FBSDKCoreKit'
end

target 'Tunnel' do
  pod 'OpenVPNAdapter', :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git', :tag => '0.8.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
    end
  end
end