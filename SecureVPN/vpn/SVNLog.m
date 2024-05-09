//
//  SVNLog.m
//  SecureVPN
//
//  Created by  securevpn on 2024/2/20.
//

#import "SVNLog.h"
#import "SVNConfig.h"

static NSUserDefaults * _groupDefaults = nil;
static NSDateFormatter * _dateFormatter = nil;

@interface SVNLog ()

@property (class, nonatomic, strong) NSUserDefaults *groupDefaults;
@property (class, nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation SVNLog

- (instancetype)initWithText:(NSString *)text level:(VNLogLevel)level source:(VNLogSource)source; {
    self = [super init];
    if (self) {
        self.identifier = [SVNLog.dateFormatter stringFromDate:[NSDate date]];
        self.text = text;
        self.level = level;
        self.source = source;
        
    }
    return self;
}

- (NSString *)logDescription {
    NSString *source;
    switch (self.source) {
        case VNLogSourceMainApp:
            source = @"main";
            break;
        case VNLogSourceTunnel:
            source = @"tunnel";
            break;
        case VNLogSourceOther:
            source = @"other";
            break;
        default:
            source = @"none";
            break;
    }
    
    if (self.level == VNLogLevelInfo) {
        return [NSString stringWithFormat:@"\n<VPN> source: %@\n<VPN-INFO>: %@", source, self.text];
    } else {
        return [NSString stringWithFormat:@"\n<VPN> 请注意，这里有个错误...\n<VPN> 请注意，这里有个错误...\n<VPN> source: %@\n<VPN-Error>: %@", source, self.text];
    }
}

//- (void)encodeWithCoder:(nonnull NSCoder *)coder {
//    [coder encodeObject:self.identifier forKey:@"identifier"];
//    [coder encodeObject:self.text forKey:@"text"];
//    [coder encodeInteger:self.source forKey:@"source"];
//}
//
//- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
//    if (self = [super init]) {
//        self.identifier = [coder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
//        self.text = [coder decodeObjectOfClass:[NSString class] forKey:@"text"];
//        self.source = [coder decodeIntegerForKey:@"source"];
//    }
//    return self;
//}

+ (NSUserDefaults *)groupDefaults {
    if (_groupDefaults == nil) {
        _groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:SVN_GROUP];
    }
    return _groupDefaults;
}

+ (void)setGroupDefaults:(NSUserDefaults *)groupDefaults {
    _groupDefaults = groupDefaults;
}

+ (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyyMMddHHmmss.SSSS";
    }
    return _dateFormatter;
}

+ (void)setDateFormatter:(NSDateFormatter *)dateFormatter {
    _dateFormatter = dateFormatter;
}

+ (void)appendWithText:(NSString *)text level:(VNLogLevel)level source:(VNLogSource)source; {
    SVNLog *log = [[SVNLog alloc] initWithText:text level:level source:source];
    [self append:log];
}

+ (void)append:(SVNLog *)log {
    NSArray *temps = [self.groupDefaults valueForKey:SVN_LOG];
    NSMutableArray *messages;
    if (temps) {
        messages = [temps mutableCopy];
    } else {
        messages = [[NSMutableArray alloc] init];
    }
    
    @try {
        NSError *error = nil;
        NSDictionary *dict = [log dictionaryWithValuesForKeys:@[@"identifier", @"text", @"level", @"source"]];
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"LOG: json error:%@", error.localizedDescription);
            return;
        }
        [messages addObject:data];
        [self.groupDefaults setObject:messages forKey:SVN_LOG];
    } @catch (NSException *exception) {
        NSLog(@"LOG: json exception:%@", exception);
    }
}

+ (NSArray <SVNLog *> *)getValues {
    NSMutableArray <SVNLog *> *logs = [NSMutableArray array];
    NSArray *values = [self.groupDefaults valueForKey:SVN_LOG];
    for (NSData *data in values) {
        SVNLog *log = [self getValueWithData:data];
        [logs addObject:log];
    }
    return logs;
}

+ (SVNLog *)getValueWithData:(NSData *)data {
    SVNLog *log = [[SVNLog alloc] init];
    @try {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) {
            log.text = [NSString stringWithFormat:@"Error on deserialize log data from UserDefaults:%@", error.localizedDescription];
            log.source = VNLogSourceOther;
            log.level = VNLogLevelError;
        } else {
            [log setValuesForKeysWithDictionary:dict];
        }
    } @catch (NSException *exception) {
        log.text = [NSString stringWithFormat:@"Exception on deserialize log data from UserDefaults:%@", exception.reason];
        log.source = VNLogSourceOther;
        log.level = VNLogLevelError;
    }
    return log;
}

+ (void)clean {
    [self.groupDefaults removeObjectForKey:SVN_LOG];
}

@end
