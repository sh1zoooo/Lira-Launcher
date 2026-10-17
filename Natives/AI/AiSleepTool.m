#import "utils.h"
//
//  AiSleepTool.m
//  Amethyst
//

#import "AiSleepTool.h"

/// 单次最长等待（防模型传入超大值卡死会话）
static const double kAiSleepMaxSeconds = 120.0;

@implementation AiSleepTool

- (NSString *)name {
    return @"sleep";
}

- (AiToolPermission)permission {
    return AiToolPermissionReadOnly;
}

- (NSString *)summary {
    return localize(@"lira.legacy.239", nil);
}

- (void)execute:(NSDictionary<NSString *, id> *)params
     completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    if (!completion) return;

    double seconds = 1.0;
    id v = params[@"seconds"];
    if ([v isKindOfClass:[NSNumber class]]) {
        seconds = [(NSNumber *)v doubleValue];
    } else if ([v isKindOfClass:[NSString class]]) {
        seconds = [(NSString *)v doubleValue];
    }
    if (seconds < 0) seconds = 0;
    if (seconds > kAiSleepMaxSeconds) seconds = kAiSleepMaxSeconds;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        completion([NSString stringWithFormat:localize(@"lira.legacy.240", nil), seconds], nil);
    });
}

@end
