//
//  SVPop.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVPop : UIView

@property (nonatomic, strong) UIView *overlayView;
- (void)show;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
