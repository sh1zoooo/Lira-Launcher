#pragma once
#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSNotificationName const LiraWorldSceneChangedNotification;
FOUNDATION_EXPORT NSString *LiraSceneForProfile(NSString *name);
FOUNDATION_EXPORT UIImage *LiraWorldImage(NSString *scene);
FOUNDATION_EXPORT UIColor *LiraMint(void);
FOUNDATION_EXPORT BOOL LiraMotionAllowed(void);

/// Raster scenery is independent of text and controls; never captures touch input.
@interface LiraWorldBackdrop : UIView
@property(nonatomic, getter=isMotionActive) BOOL motionActive;
- (void)showScene:(NSString *)scene animated:(BOOL)animated;
@end

@interface LiraPlayButton : UIControl
@property(nonatomic, copy) NSString *title;
@property(nonatomic, getter=isLaunching) BOOL launching;
@property(nonatomic) double progress;
@end

/// Destination order is Play, Library, Explore, Profile. Controller indices stay unchanged.
@interface LiraWorldDock : UIView
@property(nonatomic) NSInteger selectedDestination;
@property(nonatomic, copy) void (^didSelectDestination)(NSInteger destination);
- (void)setSelectedDestination:(NSInteger)destination animated:(BOOL)animated;
@end
