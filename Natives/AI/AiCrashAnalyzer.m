#import "utils.h"
//
//  AiCrashAnalyzer.m
//  Amethyst
//

#import "AiCrashAnalyzer.h"

@implementation AiCrashAnalyzer

- (NSString *)name {
    return @"match_known_errors";
}

- (AiToolPermission)permission {
    return AiToolPermissionReadOnly;
}

- (NSString *)summary {
    return localize(@"lira.legacy.345", nil);
}

/// 单个匹配规则：catgeory + alternatives（每组 alt 的关键词需全部命中才算该 alt 匹配）
- (NSArray<NSDictionary *> *)ruleTable {
    return @[
        @{
            @"category": localize(@"lira.legacy.346", nil),
            @"alternatives": @[
                @[@"OutOfMemoryError"],
            ],
            @"explanation": localize(@"lira.legacy.347", nil),
            @"suggestions": @[
                localize(@"lira.legacy.348", nil),
                localize(@"lira.legacy.349", nil),
                localize(@"lira.legacy.350", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.351", nil),
            @"alternatives": @[
                @[@"Failed to initialize JNI", @"META-INF"],
                @[@"java.lang.UnsatisfiedLinkError"],
            ],
            @"explanation": localize(@"lira.legacy.352", nil),
            @"suggestions": @[
                localize(@"lira.legacy.353", nil),
                localize(@"lira.legacy.354", nil),
                localize(@"lira.legacy.355", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.356", nil),
            @"alternatives": @[
                @[@"OpenGL", @"GLFW error"],
                @[@"GLX"],
            ],
            @"explanation": localize(@"lira.legacy.357", nil),
            @"suggestions": @[
                localize(@"lira.legacy.358", nil),
                localize(@"lira.legacy.359", nil),
                localize(@"lira.legacy.360", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.361", nil),
            @"alternatives": @[
                @[@"Unsupported Java version"],
                @[@"Java 8"],
            ],
            @"explanation": localize(@"lira.legacy.362", nil),
            @"suggestions": @[
                localize(@"lira.legacy.363", nil),
                localize(@"lira.legacy.364", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.365", nil),
            @"alternatives": @[
                @[@"Zombie"],
                @[@"invalid range"],
            ],
            @"explanation": localize(@"lira.legacy.366", nil),
            @"suggestions": @[
                localize(@"lira.legacy.367", nil),
                localize(@"lira.legacy.368", nil),
            ],
        },
        // ===== iOS 环境已知错误（enhance-ai-agent Task 17）=====
        @{
            @"category": localize(@"lira.legacy.369", nil),
            @"alternatives": @[
                @[@"Magic Keyboard", @"crash"],
                @[@"妙控键盘"],
            ],
            @"explanation": localize(@"lira.legacy.371", nil),
            @"suggestions": @[
                localize(@"lira.legacy.372", nil),
                localize(@"lira.legacy.373", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.374", nil),
            @"alternatives": @[
                @[@"26.2", @"OpenGL", @"syntax"],
                @[@"GL_INVALID_OPERATION", @"syntax error"],
            ],
            @"explanation": localize(@"lira.legacy.375", nil),
            @"suggestions": @[
                localize(@"lira.legacy.376", nil),
                localize(@"lira.legacy.377", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.378", nil),
            @"alternatives": @[
                @[@"26.3-Snapshot4"],
                @[@"SDL3"],
            ],
            @"explanation": localize(@"lira.legacy.379", nil),
            @"suggestions": @[
                localize(@"lira.legacy.380", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.381", nil),
            @"alternatives": @[
                @[@"启动器", @"闪退"],
                @[@"launcher", @"SIGKILL"],
            ],
            @"explanation": localize(@"lira.legacy.384", nil),
            @"suggestions": @[
                localize(@"lira.legacy.385", nil),
                localize(@"lira.legacy.386", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.387", nil),
            @"alternatives": @[
                @[@"LWJGL", @"UnsatisfiedLinkError"],
                @[@"LWJGL", @"no such function"],
                @[@"LWJGL", @"NoSuchMethodError"],
            ],
            @"explanation": localize(@"lira.legacy.388", nil),
            @"suggestions": @[
                localize(@"lira.legacy.389", nil),
                localize(@"lira.legacy.390", nil),
            ],
        },
        @{
            @"category": localize(@"lira.legacy.391", nil),
            @"alternatives": @[
                @[@"JIT", @"SIGSEGV"],
                @[@"JIT", @"SIGTRAP"],
                @[@"ptrace", @"debugged"],
            ],
            @"explanation": localize(@"lira.legacy.392", nil),
            @"suggestions": @[
                localize(@"lira.legacy.393", nil),
                localize(@"lira.legacy.394", nil),
            ],
        },
    ];
}

- (void)execute:(NSDictionary<NSString *, id> *)params
     completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    if (!completion) return;

    NSString *log = params[@"log"];
    NSString *crash = params[@"crashReport"];
    if (![log isKindOfClass:[NSString class]]) log = nil;
    if (![crash isKindOfClass:[NSString class]]) crash = nil;

    if (log.length == 0 && crash.length == 0) {
        NSError *err = [NSError errorWithDomain:@"AiTool" code:400
                                       userInfo:@{NSLocalizedDescriptionKey: localize(@"lira.legacy.395", nil)}];
        completion(nil, err);
        return;
    }

    NSString *combined = [NSString stringWithFormat:@"%@\n%@", (log ?: @""), (crash ?: @"")];

    // 内置规则匹配
    NSDictionary *matchedResult = nil;
    for (NSDictionary *rule in [self ruleTable]) {
        BOOL ruleMatched = NO;
        for (NSArray *alternative in rule[@"alternatives"]) {
            BOOL allHit = YES;
            for (NSString *keyword in alternative) {
                if ([combined rangeOfString:keyword options:NSCaseInsensitiveSearch].location == NSNotFound) {
                    allHit = NO;
                    break;
                }
            }
            if (allHit) { ruleMatched = YES; break; }
        }
        if (ruleMatched) {
            matchedResult = @{
                @"matched": @YES,
                @"category": rule[@"category"],
                @"explanation": rule[@"explanation"],
                @"suggestions": rule[@"suggestions"],
            };
            break;
        }
    }

    if (!matchedResult) {
        matchedResult = @{
            @"matched": @NO,
            @"category": localize(@"i18n_str_121", nil),
            @"explanation": @"没有匹配到已知错误类型，无法直接定位原因。",
            @"suggestions": @[
                @"再尝试启动一次，观察是否必现。",
                @"把完整日志或导出的崩溃报告发给社区/开发者在论坛反馈。",
                @"临时关闭模组和光影，逐个排查是否为某个资源导致。",
            ],
        };
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:matchedResult options:0 error:nil];
    NSString *resultJSON = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{}";
    completion(resultJSON, nil);
}

@end