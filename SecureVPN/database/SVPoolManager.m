//
//  SVPoolManager.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import "SVPoolManager.h"
#import <UIKit/UIApplication.h>

@implementation SVPoolManager

static SVPoolManager *instance = nil;
+ (SVPoolManager *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVPoolManager alloc] init];
    });
    return instance;
}

- (NSPersistentContainer *)persistentContainer {
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"SecureVPN"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                NSLog(@"secure pool path: %@", [storeDescription.URL absoluteString]);
                if (error) {
                    NSLog(@"%@", [NSString stringWithFormat:@"secure pool error %@, %@", error, error.userInfo]);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

- (void)savePool; {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"%@", [NSString stringWithFormat:@"secure pool error %@, %@", error, error.userInfo]);
        abort();
    }
}

@end
