#pragma once
#import <UIKit/UIKit.h>
#import "LauncherPreferences.h"

// Shared semantic tokens. Dynamic colors keep every surface readable in both themes.
static inline UIColor *LiraColor(unsigned int rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 255)/255.0
                           green:((rgb >> 8) & 255)/255.0 blue:(rgb & 255)/255.0 alpha:1];
}
static inline UIColor *LiraBackground(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x04170F : 0xF2F7F3);
    }];
}
static inline UIColor *LiraSurface(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x0C271C : 0xFFFFFF);
    }];
}
static inline UIColor *LiraSecondarySurface(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x153A2B : 0xE4EFE7);
    }];
}
static inline UIFont *LiraFont(UIFontTextStyle style, CGFloat size, UIFontWeight weight) {
    return [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:[UIFont systemFontOfSize:size weight:weight]];
}
static inline void LiraStyleCard(UIView *view) {
    view.backgroundColor = LiraSurface();
    view.layer.cornerRadius = 22;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.clipsToBounds = YES;
}
static inline void LiraApplyNavigationAppearance(UINavigationBar *bar) {
    UINavigationBarAppearance *a = [[UINavigationBarAppearance alloc] init];
    [a configureWithOpaqueBackground];
    a.backgroundColor = LiraBackground();
    a.shadowColor = UIColor.clearColor;
    a.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.labelColor,
                             NSFontAttributeName: LiraFont(UIFontTextStyleHeadline, 17, UIFontWeightSemibold)};
    a.largeTitleTextAttributes = @{NSForegroundColorAttributeName: UIColor.labelColor,
                                  NSFontAttributeName: LiraFont(UIFontTextStyleLargeTitle, 32, UIFontWeightBold)};
    bar.standardAppearance = a;
    bar.scrollEdgeAppearance = a;
    bar.compactAppearance = a;
    bar.tintColor = accentColor();
}
