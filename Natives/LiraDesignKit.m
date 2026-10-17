#import "LiraDesignKit.h"
#import "LiraLivingWorld.h"
#import "LiraTheme.h"
#import "PLProfiles.h"
#import "utils.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

static NSString *LiraCoverScope(void) { return [PLProfiles.current.profilePath stringByResolvingSymlinksInPath]?:NSHomeDirectory(); }
static NSString *LiraCoverFolder(void) { return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"Lira/Covers"]; }
UIImage *LiraProfileCover(NSString *name) {
    NSDictionary *map=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"lira.profileCovers"];
    NSString *file=map[LiraCoverScope()][name?:@""];
    if ([file isKindOfClass:NSString.class] && [file isEqualToString:file.lastPathComponent]) {
        static NSCache *cache; static dispatch_once_t once;
        dispatch_once(&once,^{ cache=[NSCache new]; cache.totalCostLimit=32*1024*1024; });
        UIImage *image=[cache objectForKey:file];
        if (!image) { image=[UIImage imageWithContentsOfFile:[LiraCoverFolder() stringByAppendingPathComponent:file]]; if (image) [cache setObject:image forKey:file cost:(NSUInteger)(image.size.width*image.size.height*4)]; }
        if (image) return image;
    }
    // An honest abstract cover for profiles without artwork. Never invents a saved-world preview.
    static UIImage *fallback; static dispatch_once_t once;
    dispatch_once(&once,^{
        UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(420,420)];
        fallback=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){
            CGContextRef c=context.CGContext;
            NSArray *colors=@[(id)LiraColor(0x454545).CGColor,(id)LiraColor(0x161616).CGColor];
            CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB(); CGGradientRef gradient=CGGradientCreateWithColors(space,(__bridge CFArrayRef)colors,NULL);
            CGContextDrawLinearGradient(c,gradient,CGPointZero,CGPointMake(420,420),0); CGGradientRelease(gradient); CGColorSpaceRelease(space);
            UIBezierPath *p=[UIBezierPath bezierPath];
            [p moveToPoint:CGPointMake(210,115)]; [p addLineToPoint:CGPointMake(300,165)]; [p addLineToPoint:CGPointMake(300,265)];
            [p addLineToPoint:CGPointMake(210,315)]; [p addLineToPoint:CGPointMake(120,265)]; [p addLineToPoint:CGPointMake(120,165)]; [p closePath];
            [p moveToPoint:CGPointMake(120,165)]; [p addLineToPoint:CGPointMake(210,215)]; [p addLineToPoint:CGPointMake(300,165)];
            [p moveToPoint:CGPointMake(210,215)]; [p addLineToPoint:CGPointMake(210,315)];
            [[UIColor whiteColor] setStroke]; p.lineWidth=4; p.lineJoinStyle=kCGLineJoinRound; [p stroke];
        }];
    }); return fallback;
}
void LiraStyleSearchBar(UISearchBar *bar) {
    bar.searchBarStyle=UISearchBarStyleMinimal; bar.backgroundImage=[UIImage new];
    bar.tintColor=LiraMint(); bar.searchTextField.backgroundColor=LiraColor(0x292929);
    bar.searchTextField.textColor=UIColor.whiteColor; bar.searchTextField.layer.cornerRadius=18;
    bar.searchTextField.layer.cornerCurve=kCACornerCurveContinuous;
    bar.searchTextField.font=LiraFont(UIFontTextStyleBody,16,UIFontWeightRegular);
    bar.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
}

@interface LiraSegmentControl ()
@property(nonatomic, strong) NSArray<UIButton *> *buttons;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *,NSNumber *> *widths;
@property(nonatomic, strong) UIView *indicator;
@end
@implementation LiraSegmentControl
- (instancetype)initWithItems:(NSArray<NSString *> *)items {
    if ((self=[super initWithFrame:CGRectZero])) {
        self.widths=NSMutableDictionary.dictionary; self.layer.cornerRadius=18; self.clipsToBounds=YES;
        self.backgroundColor=LiraColor(0x242424); self.selectedSegmentTintColor=LiraColor(0x444444);
        self.indicator=[UIView new]; self.indicator.userInteractionEnabled=NO; self.indicator.layer.cornerRadius=15;
        self.indicator.layer.borderWidth=0.5; self.indicator.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.18].CGColor;
        [self addSubview:self.indicator];
        NSMutableArray *buttons=NSMutableArray.array;
        for (NSUInteger i=0;i<items.count;i++) {
            UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom]; button.tag=i;
            [button setTitle:items[i] forState:UIControlStateNormal]; button.titleLabel.font=LiraFont(UIFontTextStyleFootnote,13,UIFontWeightSemibold);
            button.titleLabel.adjustsFontSizeToFitWidth=YES; button.titleLabel.minimumScaleFactor=0.7;
            [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button]; [buttons addObject:button];
        } self.buttons=buttons; self.selectedSegmentIndex=0;
    } return self;
}
- (CGSize)intrinsicContentSize { return CGSizeMake(UIViewNoIntrinsicMetric,44); }
- (void)layoutSubviews {
    [super layoutSubviews]; CGFloat x=3; CGFloat available=MAX(0,self.bounds.size.width-6);
    CGFloat total=0; for (NSNumber *width in self.widths.allValues) total+=width.doubleValue;
    for (UIButton *button in self.buttons) {
        CGFloat w=total>0?available*[self.widths[@(button.tag)] doubleValue]/total:available/MAX(1,self.buttons.count);
        button.frame=CGRectMake(x,3,w,MAX(0,self.bounds.size.height-6)); x+=w;
    }
    self.indicator.backgroundColor=LiraColor(0x454545);
    if (self.selectedSegmentIndex>=0 && self.selectedSegmentIndex<(NSInteger)self.buttons.count) self.indicator.frame=self.buttons[self.selectedSegmentIndex].frame;
}
- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)index { self.widths[@(index)]=@(width); [self setNeedsLayout]; }
- (void)setTitleTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state {
    for (UIButton *button in self.buttons) { if (attributes[NSFontAttributeName]) button.titleLabel.font=attributes[NSFontAttributeName]; }
}
- (void)setSelectedSegmentIndex:(NSInteger)index {
    _selectedSegmentIndex=index;
    for (UIButton *button in self.buttons) {
        [button setTitleColor:button.tag==index?UIColor.whiteColor:LiraColor(0xA3A3A3) forState:UIControlStateNormal];
        button.accessibilityTraits=UIAccessibilityTraitButton|(button.tag==index?UIAccessibilityTraitSelected:0);
    }
    if (index>=0 && index<(NSInteger)self.buttons.count) {
        [UIView animateWithDuration:self.window && LiraMotionAllowed()?0.32:0 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self.indicator.frame=self.buttons[index].frame; } completion:nil];
    }
}
- (void)tap:(UIButton *)button { self.selectedSegmentIndex=button.tag; [self sendActionsForControlEvents:UIControlEventValueChanged]; }
@end

@implementation LiraSheetAction
+ (instancetype)title:(NSString *)title handler:(void (^)(void))handler { LiraSheetAction *action=[self new]; action.title=title; action.handler=handler; return action; }
@end
@interface LiraSheet:UIViewController
@property(nonatomic, copy) NSArray<LiraSheetAction *> *actions;
@property(nonatomic, copy) NSString *heading;
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIButton *scrim;
@end
@implementation LiraSheet
- (void)viewDidLoad {
    [super viewDidLoad]; self.view.accessibilityViewIsModal=YES;
    self.scrim=[UIButton buttonWithType:UIButtonTypeCustom]; self.scrim.frame=self.view.bounds;
    self.scrim.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.scrim.backgroundColor=[UIColor colorWithWhite:0 alpha:0.65]; self.scrim.accessibilityLabel=localize(@"Cancel",nil);
    [self.scrim addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:self.scrim];
    self.panel=[UIView new]; self.panel.backgroundColor=LiraColor(0x222222); self.panel.layer.cornerRadius=30;
    self.panel.layer.borderWidth=0.5; self.panel.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.15].CGColor;
    self.panel.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:self.panel];
    UIScrollView *scroll=[UIScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints=NO; [self.panel addSubview:scroll];
    UIStackView *stack=[UIStackView new]; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=7; stack.translatesAutoresizingMaskIntoConstraints=NO; [scroll addSubview:stack];
    UILabel *title=[UILabel new]; title.text=self.heading; title.font=LiraFont(UIFontTextStyleTitle2,24,UIFontWeightLight); title.textColor=UIColor.whiteColor; title.numberOfLines=0;
    [stack addArrangedSubview:title]; [stack setCustomSpacing:18 afterView:title];
    for (NSUInteger i=0;i<self.actions.count+1;i++) {
        UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom]; button.tag=i;
        NSString *text=i==self.actions.count?localize(@"Cancel",nil):self.actions[i].title;
        [button setTitle:text forState:UIControlStateNormal]; [button setTitleColor:i==self.actions.count?LiraColor(0xAFAFAF):UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font=LiraFont(UIFontTextStyleBody,17,UIFontWeightMedium); button.titleLabel.numberOfLines=0; button.titleLabel.textAlignment=NSTextAlignmentCenter;
        button.backgroundColor=i==self.actions.count?UIColor.clearColor:LiraColor(0x303030); button.layer.cornerRadius=17;
        [button.heightAnchor constraintGreaterThanOrEqualToConstant:52].active=YES;
        [button addTarget:self action:@selector(choose:) forControlEvents:UIControlEventTouchUpInside]; [stack addArrangedSubview:button];
    }
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.panel.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [self.panel.widthAnchor constraintLessThanOrEqualToConstant:520],
        [self.panel.leadingAnchor constraintGreaterThanOrEqualToAnchor:safe.leadingAnchor constant:16],
        [self.panel.trailingAnchor constraintLessThanOrEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.panel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12],
        [self.panel.topAnchor constraintGreaterThanOrEqualToAnchor:safe.topAnchor constant:12],
        [scroll.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:18], [scroll.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-18],
        [scroll.topAnchor constraintEqualToAnchor:self.panel.topAnchor constant:24], [scroll.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor constant:-12],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor], [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor], [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
    NSLayoutConstraint *width=[self.panel.widthAnchor constraintEqualToAnchor:safe.widthAnchor constant:-32]; width.priority=999; width.active=YES;
    NSLayoutConstraint *height=[scroll.heightAnchor constraintEqualToAnchor:stack.heightAnchor]; height.priority=750; height.active=YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated]; if (!LiraMotionAllowed()) return;
    self.panel.transform=CGAffineTransformMakeTranslation(0,32); self.panel.alpha=0; self.scrim.alpha=0;
    [UIView animateWithDuration:0.38 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:0 animations:^{self.panel.transform=CGAffineTransformIdentity; self.panel.alpha=1; self.scrim.alpha=1;} completion:nil];
}
- (BOOL)accessibilityPerformEscape { [self close]; return YES; }
- (void)close { [self finish:nil]; }
- (void)choose:(UIButton *)button { [self finish:button.tag<(NSInteger)self.actions.count?self.actions[button.tag].handler:nil]; }
- (void)finish:(void (^)(void))handler {
    self.view.userInteractionEnabled=NO;
    [UIView animateWithDuration:LiraMotionAllowed()?0.18:0 animations:^{ self.view.alpha=0; } completion:^(BOOL finished){ [self dismissViewControllerAnimated:NO completion:handler]; }];
}
@end
void LiraPresentSheet(UIViewController *presenter, NSString *title, NSArray<LiraSheetAction *> *actions) {
    LiraSheet *sheet=[LiraSheet new]; sheet.heading=title; sheet.actions=actions; sheet.modalPresentationStyle=UIModalPresentationOverFullScreen;
    [presenter presentViewController:sheet animated:NO completion:nil];
}

@interface LiraCoverPicker:NSObject <UIDocumentPickerDelegate>
@property(nonatomic, weak) UIViewController *presenter;
@property(nonatomic, copy) NSString *profile;
@property(nonatomic, copy) NSString *scope;
@end
static char LiraPickerAssociation;
@implementation LiraCoverPicker
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url=urls.firstObject; BOOL access=[url startAccessingSecurityScopedResource];
    NSNumber *size=nil; [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
    UIImage *image=nil;
    if (size.unsignedLongLongValue<=20*1024*1024) {
        CGImageSourceRef source=CGImageSourceCreateWithURL((__bridge CFURLRef)url,NULL);
        if (source) {
            CGImageRef thumbnail=CGImageSourceCreateThumbnailAtIndex(source,0,(__bridge CFDictionaryRef)@{(id)kCGImageSourceCreateThumbnailFromImageAlways:@YES,(id)kCGImageSourceThumbnailMaxPixelSize:@1024,(id)kCGImageSourceCreateThumbnailWithTransform:@YES});
            if (thumbnail) { image=[UIImage imageWithCGImage:thumbnail]; CGImageRelease(thumbnail); }
            CFRelease(source);
        }
    }
    if (access) [url stopAccessingSecurityScopedResource];
    BOOL success=NO;
    if (image) {
        NSString *file=[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"png"];
        [NSFileManager.defaultManager createDirectoryAtPath:LiraCoverFolder() withIntermediateDirectories:YES attributes:nil error:nil];
        success=[UIImagePNGRepresentation(image) writeToFile:[LiraCoverFolder() stringByAppendingPathComponent:file] atomically:YES];
        if (success) {
            NSMutableDictionary *all=[[NSUserDefaults.standardUserDefaults dictionaryForKey:@"lira.profileCovers"] mutableCopy]?:NSMutableDictionary.dictionary;
            NSMutableDictionary *scope=[all[self.scope] mutableCopy]?:NSMutableDictionary.dictionary;
            NSString *old=scope[self.profile]; scope[self.profile]=file; all[self.scope]=scope;
            [NSUserDefaults.standardUserDefaults setObject:all forKey:@"lira.profileCovers"];
            if (old.length && [old isEqualToString:old.lastPathComponent]) [NSFileManager.defaultManager removeItemAtPath:[LiraCoverFolder() stringByAppendingPathComponent:old] error:nil];
            [NSNotificationCenter.defaultCenter postNotificationName:@"LiraCoverChanged" object:nil];
        }
    }
    UIViewController *presenter=self.presenter;
    [controller dismissViewControllerAnimated:YES completion:^{
        if (!success) LiraPresentSheet(presenter,localize(@"lira.cover.error",nil),@[]);
    }];
    objc_setAssociatedObject(presenter,&LiraPickerAssociation,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller { objc_setAssociatedObject(self.presenter,&LiraPickerAssociation,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
@end
void LiraChooseProfileCover(UIViewController *presenter, NSString *profileName) {
    if (!profileName.length) return;
    LiraCoverPicker *delegate=[LiraCoverPicker new]; delegate.presenter=presenter; delegate.profile=profileName; delegate.scope=LiraCoverScope();
    objc_setAssociatedObject(presenter,&LiraPickerAssociation,delegate,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeImport];
    picker.delegate=delegate; picker.allowsMultipleSelection=NO;
    [presenter presentViewController:picker animated:YES completion:nil];
}
