#import "utils.h"
//
//  AiSettings.m
//  Amethyst
//

#import "AiSettings.h"

@implementation AiSettings

static NSString * const kSelectedProviderIdKey = @"ai.selected_provider_id";
static NSString * const kSafetyModeKey = @"ai.safety_mode";
static NSString * const kMarkdownEnabledKey = @"ai.markdown_enabled";
static NSString * const kSystemPromptKey = @"ai.systemPrompt";

+ (instancetype)sharedSettings {
    static AiSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AiSettings alloc] init];
    });
    return instance;
}

#pragma mark - setters / getters（直接读写 NSUserDefaults，不缓存）

- (nullable NSString *)selectedProviderId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedProviderIdKey];
}

- (void)setSelectedProviderId:(nullable NSString *)selectedProviderId {
    if (selectedProviderId.length == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSelectedProviderIdKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:selectedProviderId forKey:kSelectedProviderIdKey];
    }
}

- (AiSafetyMode)safetyMode {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kSafetyModeKey];
    return (value < AiSafetyModeSafe || value > AiSafetyModeYOLO) ? AiSafetyModeSafe : (AiSafetyMode)value;
}

- (void)setSafetyMode:(AiSafetyMode)safetyMode {
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)safetyMode forKey:kSafetyModeKey];
}

- (BOOL)markdownEnabled {
    // 未显式设置时默认 YES
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kMarkdownEnabledKey];
    if (obj == nil) return YES;
    return [[NSUserDefaults standardUserDefaults] boolForKey:kMarkdownEnabledKey];
}

- (void)setMarkdownEnabled:(BOOL)markdownEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:markdownEnabled forKey:kMarkdownEnabledKey];
}

- (NSString *)systemPrompt {
    NSString *prompt = [[NSUserDefaults standardUserDefaults] stringForKey:kSystemPromptKey];
    if (prompt.length == 0) {
        prompt = [[self class] defaultSystemPrompt];
    }
    return prompt;
}

- (void)setSystemPrompt:(NSString *)systemPrompt {
    [[NSUserDefaults standardUserDefaults] setObject:systemPrompt ?: @"" forKey:kSystemPromptKey];
}

+ (NSString *)defaultSystemPrompt {
    return localize(@"lira.legacy.286", nil);
}

@end