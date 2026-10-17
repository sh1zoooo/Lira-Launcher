#import <UIKit/UIKit.h>
/// Internal controller indices remain Home=0, Explore=1, AI=2, Library=3, Profile=4.
/// The visible custom dock maps Play/Library/Explore/Profile onto those indices.
extern NSString * const AmeTabTappedNotification;
@interface AmeRootTabController : UITabBarController
+ (instancetype)tabControllerWithHomeViewController:(UIViewController *)home;
@end
