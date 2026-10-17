#import <UIKit/UIKit.h>
FOUNDATION_EXPORT UIImage *LiraProfileCover(NSString *profileName);
FOUNDATION_EXPORT void LiraChooseProfileCover(UIViewController *presenter, NSString *profileName);
FOUNDATION_EXPORT void LiraStyleSearchBar(UISearchBar *bar);

@interface LiraSegmentControl : UIControl
@property(nonatomic) NSInteger selectedSegmentIndex;
@property(nonatomic, strong) UIColor *selectedSegmentTintColor;
- (instancetype)initWithItems:(NSArray<NSString *> *)items;
- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)index;
- (void)setTitleTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state;
@end

@interface LiraSheetAction : NSObject
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) void (^handler)(void);
+ (instancetype)title:(NSString *)title handler:(void (^)(void))handler;
@end
FOUNDATION_EXPORT void LiraPresentSheet(UIViewController *presenter, NSString *title, NSArray<LiraSheetAction *> *actions);
