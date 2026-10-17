#import "utils.h"
//
//  AiDownloadProbe.m
//  Amethyst
//

#import "AiDownloadProbe.h"
#import "DownloadTaskManager.h"
#import "DownloadTaskItem.h"

@interface AiDownloadProbe ()
@property (nonatomic, copy) NSString *internalName;
@end

@implementation AiDownloadProbe

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _internalName = [name copy] ?: @"";
    }
    return self;
}

- (NSString *)name {
    return self.internalName;
}

- (AiToolPermission)permission {
    return AiToolPermissionReadOnly;
}

- (NSString *)summary {
    return localize(@"lira.legacy.223", nil);
}

+ (NSString *)stateName:(DownloadTaskState)state {
    switch (state) {
        case DownloadTaskStatePending:     return localize(@"i18n_str_124", nil);
        case DownloadTaskStateDownloading: return localize(@"i18n_str_138", nil);
        case DownloadTaskStatePaused:      return localize(@"i18n_str_125", nil);
        case DownloadTaskStateCompleted:   return localize(@"i18n_str_126", nil);
        case DownloadTaskStateCancelled:   return localize(@"i18n_str_127", nil);
        case DownloadTaskStateFailed:      return localize(@"i18n_str_108", nil);
    }
    return localize(@"i18n_str_121", nil);
}

- (void)execute:(NSDictionary<NSString *, id> *)params
     completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    if (!completion) return;

    NSArray<DownloadTaskItem *> *tasks = [[DownloadTaskManager sharedManager] allTasks];

    if (tasks.count == 0) {
        completion(@"当前没有下载任务。", nil);
        return;
    }

    NSMutableArray *items = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSNumber *> *summary = [NSMutableDictionary dictionary];
    for (DownloadTaskItem *task in tasks) {
        NSString *state = [AiDownloadProbe stateName:task.state];
        summary[state] = @((summary[state] ? [summary[state] integerValue] : 0) + 1);
        NSString *name = task.displayName.length > 0 ? task.displayName : (task.resourceName ?: @"");
        [items addObject:@{
            @"taskId": task.taskId ?: @"",
            @"name": name ?: @"",
            @"type": task.resourceType ?: @"",
            @"state": state,
            @"progress": @(task.progress),
            @"downloadedBytes": @(task.downloadedSize),
            @"totalBytes": @(task.totalSize),
            @"speed": @(task.speed),
            @"downloadSource": task.downloadSource ?: @"",
        }];
    }

    NSDictionary *result = @{
        @"count": @(items.count),
        @"tasks": items,
        @"summary": summary,
    };
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (!data || jsonError) {
        completion([NSString stringWithFormat:localize(@"lira.legacy.231", nil),
                    (unsigned long)items.count, jsonError.localizedDescription ?: localize(@"i18n_str_97", nil)], nil);
        return;
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    completion(json ?: @"序列化下载任务失败", nil);
}

@end
