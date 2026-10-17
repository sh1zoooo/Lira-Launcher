#import "utils.h"
//
//  AiAskTool.m
//  Amethyst
//

#import "AiAskTool.h"
#import <UIKit/UIKit.h>

@implementation AiAskTool

- (NSString *)name {
    return @"ask";
}

- (AiToolPermission)permission {
    return AiToolPermissionReadOnly;
}

- (NSString *)summary {
    return localize(@"lira.legacy.330", nil);
}

#pragma mark - 视图控制器定位

- (UIViewController * _Nullable)topmostPresentableViewController {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!keyWindow) keyWindow = [[UIApplication sharedApplication] windows].firstObject;
    if (!keyWindow) keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *top = keyWindow.rootViewController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    return top;
}

#pragma mark - 参数解析

- (NSArray<NSDictionary *> *)parseSteps:(NSDictionary *)params {
    id questionsValue = params[@"questions"];
    NSArray *questionsArray = nil;

    if ([questionsValue isKindOfClass:[NSArray class]]) {
        questionsArray = questionsValue;
    } else if ([questionsValue isKindOfClass:[NSString class]] && [(NSString *)questionsValue length] > 0) {
        NSData *data = [(NSString *)questionsValue dataUsingEncoding:NSUTF8StringEncoding];
        id parsed = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([parsed isKindOfClass:[NSArray class]]) questionsArray = parsed;
    }

    NSMutableArray *steps = [NSMutableArray array];
    if (questionsArray) {
        for (id item in questionsArray) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            id question = item[@"question"];
            if (![question isKindOfClass:[NSString class]] || [(NSString *)question length] == 0) continue;
            NSMutableArray *options = [NSMutableArray array];
            if ([item[@"options"] isKindOfClass:[NSArray class]]) {
                for (id opt in item[@"options"]) {
                    if ([opt isKindOfClass:[NSString class]] && [(NSString *)opt length] > 0) {
                        [options addObject:opt];
                    }
                }
            }
            BOOL allowCustom = [item[@"allowCustom"] isKindOfClass:[NSNumber class]] && [item[@"allowCustom"] boolValue];
            [steps addObject:@{
                @"question": question,
                @"options": options,
                @"allowCustom": @(allowCustom),
            }];
        }
    } else {
        // 单问形式
        id question = params[@"question"];
        if ([question isKindOfClass:[NSString class]] && [(NSString *)question length] > 0) {
            NSMutableArray *options = [NSMutableArray array];
            if ([params[@"options"] isKindOfClass:[NSArray class]]) {
                for (id opt in params[@"options"]) {
                    if ([opt isKindOfClass:[NSString class]] && [(NSString *)opt length] > 0) [options addObject:opt];
                }
            }
            BOOL allowCustom = [params[@"allowCustom"] isKindOfClass:[NSNumber class]] && [params[@"allowCustom"] boolValue];
            [steps addObject:@{
                @"question": question,
                @"options": options,
                @"allowCustom": @(allowCustom),
            }];
        }
    }
    return steps;
}

#pragma mark - 执行

- (void)execute:(NSDictionary<NSString *, id> *)params
     completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    if (!completion) return;
    NSArray *steps = [self parseSteps:params];
    if (steps.count == 0) {
        NSError *err = [NSError errorWithDomain:@"AiTool" code:400
                                       userInfo:@{NSLocalizedDescriptionKey: localize(@"lira.legacy.331", nil)}];
        completion(nil, err);
        return;
    }
    // UI 一律主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentStepAtIndex:0 steps:steps answers:[NSMutableArray array] completion:completion];
    });
}

- (void)presentStepAtIndex:(NSUInteger)index
                     steps:(NSArray *)steps
                   answers:(NSMutableArray *)answers
                completion:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    // 全部问完 → 产出结果
    if (index >= steps.count) {
        NSDictionary *result = @{@"answers": answers};
        NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
        completion(data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{\"answers\":[]}", nil);
        return;
    }

    NSDictionary *step = steps[index];
    NSString *question = step[@"question"];
    NSArray *options = step[@"options"];
    BOOL allowCustom = [step[@"allowCustom"] boolValue];

    UIViewController *presentingVC = [self topmostPresentableViewController];
    if (!presentingVC) {
        // 无可用 VC：取消处理
        NSDictionary *cancelled = @{@"cancelled": @YES};
        NSData *data = [NSJSONSerialization dataWithJSONObject:cancelled options:0 error:nil];
        completion(data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{\"cancelled\":true}", nil);
        return;
    }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:[NSString stringWithFormat:@"%lu. %@", (unsigned long)(index + 1), question]
                         message:nil
                  preferredStyle:UIAlertControllerStyleAlert];

    // 选项按钮
    for (NSString *option in options) {
        [alert addAction:[UIAlertAction actionWithTitle:option
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [answers addObject:@{@"question": question, @"answer": option}];
            [self presentStepAtIndex:(index + 1) steps:steps answers:answers completion:completion];
        }]];
    }

    // 自定义输入
    if (allowCustom) {
        [alert addAction:[UIAlertAction actionWithTitle:localize(@"lira.legacy.332", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            UIViewController *presenting2 = [self topmostPresentableViewController];
            UIAlertController *textAlert = [UIAlertController
                alertControllerWithTitle:[NSString stringWithFormat:@"%lu. %@", (unsigned long)(index + 1), question]
                                 message:localize(@"lira.legacy.333", nil)
                          preferredStyle:UIAlertControllerStyleAlert];
            [textAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = localize(@"lira.legacy.334", nil);
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            }];
            [textAlert addAction:[UIAlertAction actionWithTitle:localize(@"i18n_str_44", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *submit) {
                NSString *text = [textAlert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [answers addObject:@{@"question": question, @"answer": (text.length ? text : @"")}];
                [self presentStepAtIndex:(index + 1) steps:steps answers:answers completion:completion];
            }]];
            [textAlert addAction:[UIAlertAction actionWithTitle:localize(@"resman.common.cancel", nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *cancel) {
                [self finishWithCancel:completion];
            }]];
            if (presenting2) [presenting2 presentViewController:textAlert animated:YES completion:nil];
            else [self finishWithCancel:completion];
        }]];
    }

    // 取消
    [alert addAction:[UIAlertAction actionWithTitle:localize(@"resman.common.cancel", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        [self finishWithCancel:completion];
    }]];

    [presentingVC presentViewController:alert animated:YES completion:nil];
}

- (void)finishWithCancel:(void (^)(NSString * _Nullable result, NSError * _Nullable error))completion {
    NSDictionary *cancelled = @{@"cancelled": @YES};
    NSData *data = [NSJSONSerialization dataWithJSONObject:cancelled options:0 error:nil];
    completion(data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{\"cancelled\":true}", nil);
}

@end