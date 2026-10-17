// Simulator-only host: production UI with explicit fixtures, no JVM, network or account access.
#import <UIKit/UIKit.h>
#import "LiraHomeViewController.h"
#import "AmeRootTabController.h"
#import "LiraLivingWorld.h"
#import "PLProfiles.h"
#import "AmeLaunchProgress.h"
#import "LauncherPreferences.h"

NSString *localize(NSString *key, NSString *comment) {
    NSString *path=[NSBundle.mainBundle pathForResource:@"ru" ofType:@"lproj"];
    return [[NSBundle bundleWithPath:path] localizedStringForKey:key value:key table:nil];
}
UIColor *accentColor(void) { return LiraMint(); }
id getPrefObject(NSString *key) { return nil; }
void setPrefObject(NSString *key,id value) {}
BOOL AmeGameLandscapeLockActive(void) { return NO; }

@implementation PLProfiles
+ (instancetype)current {
    static PLProfiles *profiles; static dispatch_once_t once;
    dispatch_once(&once,^{
        profiles=[PLProfiles new]; profiles.profilePath=@"/preview-only";
        BOOL empty=[NSUserDefaults.standardUserDefaults boolForKey:@"EmptyLibrary"];
        profiles.profileDict=[@{@"profiles":empty?NSMutableDictionary.dictionary:[@{
            @"Adventure": [@{@"lastVersionId":@"1.21.1-fabric"} mutableCopy],
            @"Nether": [@{@"lastVersionId":@"1.20.4-forge"} mutableCopy],
            @"Vanilla": [@{@"lastVersionId":@"1.21.1"} mutableCopy]} mutableCopy]} mutableCopy];
    }); return profiles;
}
- (NSMutableDictionary *)profiles { return (id)self.profileDict[@"profiles"]; }
- (NSString *)selectedProfileName { return [NSUserDefaults.standardUserDefaults stringForKey:@"PreviewProfile"]?:@"Adventure"; }
- (void)setSelectedProfileName:(NSString *)name {
    [NSUserDefaults.standardUserDefaults setObject:name forKey:@"PreviewProfile"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"SelectedProfileChanged" object:nil];
}
@end
@interface BaseAuthenticator : NSObject @end
@implementation BaseAuthenticator
+ (id)current { return [self new]; }
@end
@interface ModLoaderIconHelper : NSObject @end
@implementation ModLoaderIconHelper
+ (NSString *)displayNameForLoader:(NSString *)loader { return loader.capitalizedString; }
@end
NSString *const AmeRightPanelStateNotification=@"AmeRightPanelState";
NSString *const AmeRightPanelRequestStateNotification=@"AmeRightPanelRequestState";
NSString *const AmeRightPanelActionNotification=@"AmeRightPanelAction";
@interface LauncherRightPanelViewController:NSObject @end
@implementation LauncherRightPanelViewController
+ (void)norightPostAction:(NSString *)action { NSLog(@"Preview action: %@ (game backend intentionally absent)",action); }
@end
#define STUB_PAGE(name) @interface name:UIViewController @property(nonatomic, strong) NSString *profileName; @end @implementation name @end
STUB_PAGE(ModsManagerViewController)
STUB_PAGE(ModpackImportViewController)
STUB_PAGE(DownloadHistoryViewController)
STUB_PAGE(MinecraftNewsViewController)
STUB_PAGE(TerracottaViewController)
STUB_PAGE(ProfileSettingsViewController)
STUB_PAGE(VersionManagerViewController)
STUB_PAGE(DownloadViewController)
STUB_PAGE(AISessionListViewController)

@interface PreviewHome:LiraHomeViewController @end
@implementation PreviewHome
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [self.navigationController setNavigationBarHidden:YES animated:NO]; }
@end

@interface PreviewApp:NSObject <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) AmeRootTabController *tabs;
@property(nonatomic, strong) PreviewHome *home;
@end
@implementation PreviewApp
- (void)state {
    [NSNotificationCenter.defaultCenter postNotificationName:AmeRightPanelStateNotification object:nil userInfo:@{
        @"user":@"Алекс",@"jit":@"JIT · готов",@"jitColor":LiraMint(),@"launchTitle":@"Играть",@"launchEnabled":@YES}];
}
- (void)snapshot:(NSString *)name {
    [self.window layoutIfNeeded];
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithBounds:self.window.bounds];
    UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){[self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:YES];}];
    NSString *documents=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
    [UIImagePNGRepresentation(image) writeToFile:[documents stringByAppendingPathComponent:[name stringByAppendingString:@".png"]] atomically:YES];
}
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window { return [NSUserDefaults.standardUserDefaults boolForKey:@"Landscape"]?UIInterfaceOrientationMaskLandscapeLeft:UIInterfaceOrientationMaskPortrait; }
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds]; self.window.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    self.home=[PreviewHome new]; self.tabs=[AmeRootTabController tabControllerWithHomeViewController:self.home];
    self.window.rootViewController=self.tabs; [self.window makeKeyAndVisible];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(state) name:AmeRightPanelRequestStateNotification object:nil];
    [self state];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        NSCAssert([UIImage imageNamed:@"LiraBrand/wordmark.png"] && [UIImage imageNamed:@"LiraBrand/fabric.png"],@"Bundled artwork missing");
        UIView *dock=[self.tabs valueForKey:@"dock"];
        NSCAssert(CGRectGetMinY(dock.frame)>0 && CGRectGetMaxY(dock.frame)<=self.window.bounds.size.height,@"Dock outside window");
        LiraPlayButton *play=[self.home valueForKey:@"playButton"];
        UIScrollView *page=[self.home valueForKey:@"page"];
        NSCAssert(play.bounds.size.height>=44,@"Play hit target too small");
        NSCAssert(page.contentSize.height+1>=page.bounds.size.height,@"Scroll content collapsed");
        [self snapshot:@"01-home"];
        // Repeated requests exercise queued native tab transitions.
        self.tabs.selectedIndex=3; self.tabs.selectedIndex=4; self.tabs.selectedIndex=3;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
            NSCAssert(self.tabs.selectedIndex==3,@"Rapid tab navigation lost final destination");
            [self snapshot:@"02-library"];
            self.tabs.selectedIndex=4;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
                [self snapshot:@"03-profile"];
                self.tabs.selectedIndex=0;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
                    NSCAssert(self.tabs.selectedIndex==0,@"Cannot return home");
                    NSString *documents=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
                    [@"PASS: production UI mounted, artwork loaded, hit target/scroll geometry and rapid tab navigation checked. Fixtures only; no game launch verification.\n" writeToFile:[documents stringByAppendingPathComponent:@"result.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                });
            });
        });
    }); return YES;
}
@end
int main(int argc,char **argv) { @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(PreviewApp.class)); } }
