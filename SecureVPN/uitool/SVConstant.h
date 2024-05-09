//
//  SVConstant.h
//  SecureVPN
//
//  Created by  securevpn on 2024/2/25.
//

#ifndef SVConstant_h
#define SVConstant_h

#import <UIKit/UIKit.h>

static inline CGFloat SVBottom(void) {
    return ((UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject]).windows.firstObject.safeAreaInsets.bottom > 0 ? 25 : 10;
}

static inline CGFloat SVTabHeight(void) {
    return 49;
}

static inline CGFloat SVScreenWidth(void) {
    return CGRectGetWidth(UIScreen.mainScreen.bounds);
}

static inline CGFloat SVSafeAreaBottom(void) {
    return ((UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject]).windows.firstObject.safeAreaInsets.bottom;
}

static inline CGFloat SVScreenHeight(void) {
    return CGRectGetHeight(UIScreen.mainScreen.bounds);
}

static inline CGFloat SVScreenScale(void) {
    return UIScreen.mainScreen.scale;
}

static BOOL IS_STATUS_BAR_FIRST = YES;
static CGFloat STATUS_BAR_HEIGHT = 0;

static inline CGFloat SVStatusHeight(void) {
    if (IS_STATUS_BAR_FIRST) {
        IS_STATUS_BAR_FIRST = NO;
        STATUS_BAR_HEIGHT = ((UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject]).statusBarManager.statusBarFrame.size.height;
    }
    return STATUS_BAR_HEIGHT;
}

static inline CGFloat SVNavHeight(void) {
    return 44 + SVStatusHeight();
}
#endif /* SVConstant_h */
