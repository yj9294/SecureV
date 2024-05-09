//
//  SVDbAdvertHandle.m
//  SecureVPN
//
//  Created by  securevpn on 2024/1/2.
//

#import "SVDbAdvertHandle.h"
#import "SVPoolManager.h"

@implementation SVDbAdvertHandle

+ (NSArray <SVPosterModel *> *)saveDatas:(NSArray <SVPosterModel *> *)list {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval allSeconds = 24 * 60 * 60;
    NSArray *datas = [NSArray arrayWithArray:list];
    NSMutableArray <SVPosterModel *> *models = [NSMutableArray arrayWithCapacity:list.count];
    NSManagedObjectContext *ctx = [SVPoolManager shared].persistentContainer.viewContext;
    for (SVPosterModel *data in datas) {
        NSPredicate *perdicate = [NSPredicate predicateWithFormat:@"name = %@", data.name];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"AdEntity"];
        NSError *error = nil;
        [request setPredicate:perdicate];
        NSArray *result = [ctx executeFetchRequest:request error:&error];
        if (result.count > 0) {
            AdEntity *entity = result.firstObject;
            entity.name = data.name;
            if (data.cck > 0) {
                entity.cck = data.cck;
            }
                
            if (data.csw > 0) {
                entity.csw = data.csw;
            }
                
            if (data.tut > 0) {
                entity.tut = data.tut;
            }
                
            NSTimeInterval timeInterval = fabs(entity.tut - time);
            if (timeInterval > allSeconds) {
                entity.csw = 0;
                entity.cck = 0;
                entity.tut = time;
            }
            [models addObject:[self sv_modelWithEntity:entity oldData:data]];
        } else {
            //本地没有对应数据
            NSEntityDescription *description = [NSEntityDescription entityForName:@"AdEntity" inManagedObjectContext:ctx];
            AdEntity *entity = (AdEntity *)[[NSManagedObject alloc] initWithEntity:description insertIntoManagedObjectContext:ctx];
            entity.name = data.name;
            entity.tut = time;
            entity.csw = 0;
            entity.cck = 0;
            [models addObject:[self sv_modelWithEntity:entity oldData:data]];
        }
    }
    NSError *error = nil;
    @try {
        [ctx save:&error];
    } @catch (NSException *exception) {
        NSLog(@"pool: %@", exception);
    } @finally {
        
    }
    return models;
}

+ (SVPosterModel *)sv_modelWithEntity:(AdEntity *)entity oldData:(SVPosterModel *)data {
    SVPosterModel *model = [[SVPosterModel alloc] init];
    model.cck = entity.cck;
    model.csw = entity.csw;
    model.tut = entity.tut;
    model.name = entity.name;
    model.msw = data.msw;
    model.posty = data.posty;
    model.mck = data.mck;
    model.tld = data.tld;
    model.tsw = data.tsw;
    model.tsld = data.tsld;
    model.advertList = data.advertList;
    
    if (data.isw == 0) {
        model.isw = NO;
    } else {
        model.isw = YES;
    }
    if (data.ild == 0) {
        model.ild = NO;
    } else {
        model.ild = YES;
    }
    return model;
}

@end
