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
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x101117 : 0xF4F5FA);
    }];
}
static inline UIColor *LiraSurface(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x1C1E28 : 0xFFFFFF);
    }];
}
static inline UIColor *LiraSecondarySurface(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return LiraColor(t.userInterfaceStyle == UIUserInterfaceStyleDark ? 0x262938 : 0xECEEF6);
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
