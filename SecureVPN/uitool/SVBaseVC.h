//
//  SVBaseVC.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVBaseVC : UIViewController

@property (nonatomic, assign) BOOL vcIsDid;
@property (nonatomic, assign) BOOL vcIsShowAding;

- (void)didVC;
@end

NS_ASSUME_NONNULL_END
