//
//  SVPoolManager.h
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


NS_ASSUME_NONNULL_BEGIN

@interface SVPoolManager : NSObject
@property (nonatomic, strong) NSPersistentContainer *persistentContainer;
+ (SVPoolManager *)shared;
- (void)savePool;
@end

NS_ASSUME_NONNULL_END
