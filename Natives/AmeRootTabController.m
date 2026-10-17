#import "AmeRootTabController.h"
#import "LiraTheme.h"
#import "LiraLivingWorld.h"
#import "LiraSettingsViewController.h"
#import "LiraLibraryViewController.h"
#import "DownloadViewController.h"
#import "AI/AISessionListViewController.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

NSString * const AmeTabTappedNotification = @"AmeTabTapped";

@interface LiraTabAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property(nonatomic, copy) void (^finished)(void);
@end
@implementation LiraTabAnimator
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)context { return LiraMotionAllowed()?0.26:0.12; }
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
    UIView *container=context.containerView;
    UIView *from=[context viewForKey:UITransitionContextFromViewKey];
    UIView *to=[context viewForKey:UITransitionContextToViewKey];
    UIViewController *toController=[context viewControllerForKey:UITransitionContextToViewControllerKey];
    to.frame=[context finalFrameForViewController:toController];
    [container addSubview:to];
    // Old content is hidden immediately; rapid switches cannot leave stale overlapping snapshots.
    from.hidden=YES; to.alpha=0;
    to.transform=LiraMotionAllowed()?CGAffineTransformMakeTranslation(0,12):CGAffineTransformIdentity;
    [UIView animateWithDuration:[self transitionDuration:context] delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        to.alpha=1; to.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        BOOL cancelled=context.transitionWasCancelled;
        if (cancelled) [to removeFromSuperview]; else [from removeFromSuperview];
        from.hidden=NO; to.alpha=1; to.transform=CGAffineTransformIdentity;
        [context completeTransition:!cancelled];
        if (self.finished) self.finished();
    }];
}
@end

@interface AmeRootTabController () <UITabBarControllerDelegate>
@property(nonatomic, strong) LiraWorldBackdrop *world;
@property(nonatomic, strong) LiraWorldDock *dock;
@property(nonatomic) BOOL transitionInFlight;
@property(nonatomic) NSInteger pendingIndex;
@property(nonatomic) BOOL homeWantsMotion;
@property(nonatomic) BOOL active;
@end

@implementation AmeRootTabController
+ (instancetype)tabControllerWithHomeViewController:(UIViewController *)home {
    AmeRootTabController *tabs=[[self alloc] init];
    tabs.pendingIndex=NSNotFound;
    NSArray *pages=@[home ?: [[UIViewController alloc] init], [[DownloadViewController alloc] init],
        [[AISessionListViewController alloc] init], [[LiraLibraryViewController alloc] init], [[LiraSettingsViewController alloc] init]];
    NSArray *keys=@[@"lira.world.play",@"lira.explore.title",@"tab.ai",@"lira.world.library",@"lira.world.profile"];
    NSMutableArray *controllers=NSMutableArray.array;
    for (NSUInteger i=0;i<pages.count;i++) {
        UIViewController *page=pages[i];
        UINavigationController *nav=[page isKindOfClass:UINavigationController.class]?(id)page:[[UINavigationController alloc] initWithRootViewController:page];
        page.tabBarItem=[[UITabBarItem alloc] initWithTitle:localize(keys[i],nil) image:nil tag:i];
        LiraApplyNavigationAppearance(nav.navigationBar);
        nav.view.backgroundColor=UIColor.clearColor;
        [controllers addObject:nav];
    }
    tabs.viewControllers=controllers; tabs.delegate=tabs; tabs.selectedIndex=0;
    return tabs;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=LiraColor(0x101010);
    self.tabBar.hidden=YES;
    // iOS 18+ adaptive system tabs are not used; the four-destination dock is our UI on every device.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 180000
    if (@available(iOS 18.0,*)) self.mode=UITabBarControllerModeTabBar;
#endif
    self.world=[[LiraWorldBackdrop alloc] initWithFrame:self.view.bounds];
    self.world.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.world atIndex:0];
    self.dock=[[LiraWorldDock alloc] init];
    __weak typeof(self) weakSelf=self;
    self.dock.didSelectDestination=^(NSInteger destination){
        typeof(self) self=weakSelf; if (!self) return;
        NSArray *indices=@[@0,@3,@1,@4];
        NSInteger index=[indices[destination] integerValue];
        [self setSelectedIndex:index];
        [NSNotificationCenter.defaultCenter postNotificationName:AmeTabTappedNotification object:nil userInfo:@{@"index":@(index)}];
    };
    [self.view addSubview:self.dock];
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(sceneChanged:) name:LiraWorldSceneChangedNotification object:nil];
    [center addObserver:self selector:@selector(motionChanged:) name:@"LiraWorldMotionChanged" object:nil];
    [center addObserver:self selector:@selector(appInactive) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(appActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    self.active=YES; self.homeWantsMotion=YES;
    [self updateDock];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; self.active=YES; [self updateDock]; }
- (void)viewDidDisappear:(BOOL)animated { [super viewDidDisappear:animated]; self.world.motionActive=NO; }
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; self.tabBar.hidden=YES;
    [self.view sendSubviewToBack:self.world]; [self.view bringSubviewToFront:self.dock];
    CGFloat width=MIN(920,self.view.bounds.size.width-self.view.safeAreaInsets.left-self.view.safeAreaInsets.right-32);
    CGFloat height=width<540?76:70;
    CGFloat bottom=MAX(12,self.view.safeAreaInsets.bottom+6);
    self.dock.frame=CGRectMake((self.view.bounds.size.width-width)/2,self.view.bounds.size.height-bottom-height,width,height);
    self.world.frame=self.view.bounds;
    // Reserve the dock in the selected navigation stack, including keyboard/rotation updates.
    UIViewController *selected=self.selectedViewController;
    if (selected.isViewLoaded) {
        CGFloat own=selected.additionalSafeAreaInsets.bottom;
        CGFloat inherited=MAX(0,selected.view.safeAreaInsets.bottom-own);
        CGFloat needed=MAX(0,CGRectGetHeight(self.view.bounds)-CGRectGetMinY(self.dock.frame)+8-inherited);
        if (fabs(needed-own)>0.5) {
            UIEdgeInsets insets=selected.additionalSafeAreaInsets; insets.bottom=needed;
            selected.additionalSafeAreaInsets=insets;
        }
    }
}
- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (self.transitionInFlight) { self.pendingIndex=(NSInteger)selectedIndex; return; }
    [super setSelectedIndex:selectedIndex];
    if (self.isViewLoaded) { [self updateDock]; [self.view setNeedsLayout]; }
}
- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    NSUInteger index=[self.viewControllers indexOfObject:selectedViewController];
    if (self.transitionInFlight && index!=NSNotFound) { self.pendingIndex=index; return; }
    [super setSelectedViewController:selectedViewController];
    if (self.isViewLoaded) { [self updateDock]; [self.view setNeedsLayout]; }
}
- (void)updateDock {
    NSInteger destination=self.selectedIndex==0?0:self.selectedIndex==3?1:self.selectedIndex==1?2:3;
    [self.dock setSelectedDestination:destination animated:self.dock.window!=nil];
    self.world.motionActive=self.active && self.homeWantsMotion && self.selectedIndex==0;
}
- (void)sceneChanged:(NSNotification *)note { if ([note.object isKindOfClass:NSString.class]) [self.world showScene:note.object animated:YES]; }
- (void)motionChanged:(NSNotification *)note { self.homeWantsMotion=[note.object boolValue]; [self updateDock]; }
- (void)appInactive { self.active=NO; [self updateDock]; }
- (void)appActive { self.active=YES; [self updateDock]; }
- (BOOL)shouldAutorotate { return AmeGameLandscapeLockActive()?NO:[super shouldAutorotate]; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return AmeGameLandscapeLockActive()?UIInterfaceOrientationMaskLandscape:[super supportedInterfaceOrientations]; }
- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)controller animationControllerForTransitionFromViewController:(UIViewController *)from toViewController:(UIViewController *)to {
    self.transitionInFlight=YES;
    LiraTabAnimator *animator=[[LiraTabAnimator alloc] init];
    __weak typeof(self) weakSelf=self;
    animator.finished=^{
        typeof(self) self=weakSelf; if (!self) return;
        self.transitionInFlight=NO;
        NSInteger pending=self.pendingIndex; self.pendingIndex=NSNotFound;
        [self updateDock]; [self.view setNeedsLayout];
        if (pending!=NSNotFound && pending!=(NSInteger)self.selectedIndex) dispatch_async(dispatch_get_main_queue(),^{ self.selectedIndex=pending; });
    };
    return animator;
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end
