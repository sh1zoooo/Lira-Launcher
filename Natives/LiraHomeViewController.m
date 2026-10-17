#import "LiraHomeViewController.h"
#import "LiraLivingWorld.h"
#import "LiraTheme.h"
#import "LiraDesignKit.h"
#import "utils.h"
#import "PLProfiles.h"
#import "LauncherRightPanelViewController.h"
#import "AmeLaunchProgress.h"
#import "AvatarManager.h"
#import "authenticator/BaseAuthenticator.h"
#import "ModsManagerViewController.h"
#import "ModpackImportViewController.h"
#import "DownloadHistoryViewController.h"
#import "MinecraftNewsViewController.h"
#import "TerracottaViewController.h"
#import "ModLoaderIconHelper.h"

static NSString *LiraProfileVersion(NSString *name) {
    id value = PLProfiles.current.profiles[name][@"lastVersionId"];
    return [value isKindOfClass:NSString.class] ? value : @"";
}
static NSString *LiraProfileLoader(NSString *name) {
    NSString *lower = LiraProfileVersion(name).lowercaseString;
    for (NSString *loader in @[@"neoforge", @"fabric", @"quilt", @"forge", @"optifine"]) {
        if ([lower containsString:loader]) return [ModLoaderIconHelper displayNameForLoader:loader];
    }
    return @"Vanilla";
}

@interface LiraWorldInstanceCell : UICollectionViewCell
@property(nonatomic, strong) UIImageView *cover;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *versionLabel;
@property(nonatomic, strong) UIImageView *loaderIcon;
- (void)configureProfile:(NSString *)name focused:(BOOL)focused;
@end
@implementation LiraWorldInstanceCell
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.cover=[UIImageView new]; self.cover.contentMode=UIViewContentModeScaleAspectFill;
        self.cover.clipsToBounds=YES; self.cover.layer.cornerCurve=kCACornerCurveContinuous;
        self.nameLabel=[UILabel new]; self.nameLabel.textColor=UIColor.whiteColor;
        self.nameLabel.adjustsFontSizeToFitWidth=YES; self.nameLabel.minimumScaleFactor=0.45; self.nameLabel.numberOfLines=2;
        self.versionLabel=[UILabel new]; self.versionLabel.textColor=LiraColor(0xCCCCCC);
        self.versionLabel.font=LiraFont(UIFontTextStyleSubheadline,17,UIFontWeightBold);
        self.versionLabel.adjustsFontSizeToFitWidth=YES; self.versionLabel.minimumScaleFactor=0.7;
        self.loaderIcon=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LiraBrand/fabric.png"]]; self.loaderIcon.contentMode=UIViewContentModeScaleAspectFit;
        for (UIView *v in @[self.cover,self.nameLabel,self.versionLabel,self.loaderIcon]) [self.contentView addSubview:v];
        self.isAccessibilityElement=YES;
    } return self;
}
- (void)layoutSubviews {
    [super layoutSubviews]; CGFloat w=self.contentView.bounds.size.width,h=self.contentView.bounds.size.height;
    BOOL wide=w>=580; CGFloat side=wide?MIN(h-12,w*0.35):MIN(w-48,MAX(130,h-112));
    self.cover.frame=CGRectMake(wide?0:(w-side)/2,wide?(h-side)/2:0,side,side);
    self.cover.layer.cornerRadius=side*0.17;
    CGFloat left=wide?side+28:8, top=wide?MAX(0,(h-side)/2):side+14;
    CGFloat textWidth=wide?w-left: w-16;
    self.nameLabel.font=LiraFont(UIFontTextStyleLargeTitle,wide?MIN(72,MAX(38,w*0.075)):38,UIFontWeightUltraLight);
    self.nameLabel.textAlignment=wide?NSTextAlignmentLeft:NSTextAlignmentCenter;
    CGFloat titleHeight=wide?MIN(side*0.57,138):58;
    self.nameLabel.frame=CGRectMake(left,top,textWidth,titleHeight);
    CGFloat versionTop=top+titleHeight+(wide?12:4);
    self.versionLabel.textAlignment=wide?NSTextAlignmentLeft:NSTextAlignmentCenter;
    self.versionLabel.frame=CGRectMake(left,versionTop,textWidth-(wide?36:0),28);
    CGFloat versionWidth=MIN(textWidth-36,[self.versionLabel.text sizeWithAttributes:@{NSFontAttributeName:self.versionLabel.font}].width);
    self.loaderIcon.frame=CGRectMake(wide?left+versionWidth+10:(w+versionWidth)/2+7,versionTop+1,26,26);
    if (!wide && !self.loaderIcon.hidden) { self.versionLabel.frame=CGRectMake((w-versionWidth-34)/2,versionTop,versionWidth,28); self.loaderIcon.frame=CGRectMake(CGRectGetMaxX(self.versionLabel.frame)+8,versionTop+1,26,26); }
}
- (void)configureProfile:(NSString *)name focused:(BOOL)focused {
    self.cover.image=LiraProfileCover(name);
    self.nameLabel.text=[name isEqualToString:@"(Default)"]?localize(@"lira.home.default_profile",nil):name;
    NSString *version=LiraProfileVersion(name), *loader=LiraProfileLoader(name);
    // Keep the full underlying version id available to accessibility; the display separates loader metadata.
    NSString *display=version;
    NSRegularExpression *pattern=[NSRegularExpression regularExpressionWithPattern:@"[0-9]+\\.[0-9]+(?:\\.[0-9]+)?" options:0 error:nil];
    NSTextCheckingResult *match=[pattern firstMatchInString:version options:0 range:NSMakeRange(0,version.length)];
    if (match) display=[version substringWithRange:match.range];
    self.versionLabel.text=[NSString stringWithFormat:@"%@  %@",display,loader];
    self.loaderIcon.hidden=![loader.lowercaseString containsString:@"fabric"];
    self.contentView.alpha=focused?1:0.45;
    self.contentView.transform=focused||!LiraMotionAllowed()?CGAffineTransformIdentity:CGAffineTransformMakeScale(0.96,0.96);
    self.accessibilityLabel=[NSString stringWithFormat:@"%@, %@, %@",self.nameLabel.text,version,loader];
    self.accessibilityTraits=UIAccessibilityTraitButton|(focused?UIAccessibilityTraitSelected:0);
    [self setNeedsLayout];
}
@end

@interface LiraHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong) UIScrollView *page;
@property(nonatomic, strong) UIView *canvas;
@property(nonatomic, strong) UIView *heading;
@property(nonatomic, strong) UILabel *greeting;
@property(nonatomic, strong) UIButton *avatar;
@property(nonatomic, strong) UILabel *jitLabel;
@property(nonatomic, strong) UICollectionView *gallery;
@property(nonatomic, strong) UICollectionViewFlowLayout *galleryLayout;
@property(nonatomic, strong) UIPageControl *pages;
@property(nonatomic, strong) LiraPlayButton *playButton;
@property(nonatomic, strong) UILabel *emptyLabel;
@property(nonatomic, strong) UIButton *installButton;
@property(nonatomic, strong) UIButton *moreButton;
@property(nonatomic, copy) NSArray<NSString *> *profiles;
@property(nonatomic, copy) NSDictionary *launchState;
@property(nonatomic) NSInteger focusedIndex;
@property(nonatomic) BOOL selectingProfile;
@property(nonatomic) BOOL draggingGallery;
@property(nonatomic) BOOL visible;
@property(nonatomic) NSUInteger launchRequest;
@property(nonatomic) CGFloat lastWidth;
@end

@implementation LiraHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.tintColor = LiraMint();
    self.page=[UIScrollView new]; self.page.showsVerticalScrollIndicator=NO;
    self.page.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:self.page]; self.canvas=[UIView new]; [self.page addSubview:self.canvas];
    [self buildHeader]; [self buildGallery];
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(stateChanged:) name:AmeRightPanelStateNotification object:nil];
    [center addObserver:self selector:@selector(progressChanged) name:AmeLaunchProgressChangedNotification object:nil];
    for (NSString *name in @[@"SelectedProfileChanged",@"ProfileListChanged",@"VersionListChanged",@"LiraCoverChanged",UIApplicationWillEnterForegroundNotification]) {
        [center addObserver:self selector:@selector(refreshProfiles) name:name object:nil];
    }
    [self refreshProfiles];
}
- (UILabel *)labelWithSize:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *label = [[UILabel alloc] init];
    label.font = LiraFont(UIFontTextStyleBody,size,weight); label.textColor = UIColor.whiteColor;
    label.adjustsFontForContentSizeCategory = YES;
    return label;
}
- (void)buildHeader {
    UIImageView *logo=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LiraBrand/wordmark.png"]];
    logo.contentMode=UIViewContentModeScaleAspectFit; logo.accessibilityLabel=@"Lira Launcher"; logo.isAccessibilityElement=YES;
    self.heading=logo; [self.canvas addSubview:logo];
    self.avatar=[UIButton buttonWithType:UIButtonTypeCustom]; self.avatar.hidden=YES;
    self.jitLabel=[self labelWithSize:11 weight:UIFontWeightMedium]; self.jitLabel.textColor=LiraColor(0x999999);
    self.jitLabel.textAlignment=NSTextAlignmentRight; self.jitLabel.numberOfLines=2;
    [self.canvas addSubview:self.jitLabel];
}
- (void)buildGallery {
    self.galleryLayout=[UICollectionViewFlowLayout new]; self.galleryLayout.scrollDirection=UICollectionViewScrollDirectionHorizontal; self.galleryLayout.minimumLineSpacing=12;
    self.gallery=[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.galleryLayout];
    self.gallery.backgroundColor=UIColor.clearColor; self.gallery.showsHorizontalScrollIndicator=NO;
    self.gallery.decelerationRate=UIScrollViewDecelerationRateFast; self.gallery.dataSource=self; self.gallery.delegate=self;
    [self.gallery registerClass:LiraWorldInstanceCell.class forCellWithReuseIdentifier:@"world"]; [self.canvas addSubview:self.gallery];
    self.emptyLabel=[self labelWithSize:30 weight:UIFontWeightUltraLight]; self.emptyLabel.numberOfLines=0; self.emptyLabel.text=localize(@"lira.world.empty",nil); self.emptyLabel.textAlignment=NSTextAlignmentCenter;
    [self.canvas addSubview:self.emptyLabel];
    self.installButton=[UIButton buttonWithType:UIButtonTypeCustom]; [self.installButton setTitle:localize(@"lira.world.install",nil) forState:UIControlStateNormal];
    [self.installButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; self.installButton.backgroundColor=LiraColor(0x333333); self.installButton.layer.cornerRadius=22;
    [self.installButton addTarget:self action:@selector(downloads) forControlEvents:UIControlEventTouchUpInside]; [self.canvas addSubview:self.installButton];
    self.playButton=[LiraPlayButton new]; self.playButton.title=localize(@"Play",nil); self.playButton.enabled=NO; self.playButton.accessibilityIdentifier=@"lira.play";
    [self.playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside]; [self.canvas addSubview:self.playButton];
    self.pages=[UIPageControl new]; self.pages.pageIndicatorTintColor=LiraColor(0x454545); self.pages.currentPageIndicatorTintColor=LiraColor(0xBBBBBB); self.pages.hidesForSinglePage=YES;
    [self.pages addTarget:self action:@selector(pageChanged) forControlEvents:UIControlEventValueChanged]; [self.canvas addSubview:self.pages];
    self.moreButton=[UIButton buttonWithType:UIButtonTypeCustom]; [self.moreButton setTitle:localize(@"lira.world.tools",nil) forState:UIControlStateNormal];
    self.moreButton.titleLabel.font=LiraFont(UIFontTextStyleFootnote,12,UIFontWeightMedium); [self.moreButton setTitleColor:LiraColor(0xAAAAAA) forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(showTools) forControlEvents:UIControlEventTouchUpInside]; [self.canvas addSubview:self.moreButton];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect safe=UIEdgeInsetsInsetRect(self.view.bounds,self.view.safeAreaInsets); self.page.frame=safe;
    CGFloat w=safe.size.width,h=safe.size.height; BOOL wide=w>=650;
    CGFloat pad=wide?MAX(28,w*0.07):20, logoWidth=MIN(w*0.5,310), logoHeight=logoWidth*78/661;
    self.heading.frame=CGRectMake((w-logoWidth)/2,wide?10:20,logoWidth,logoHeight);
    CGFloat top=CGRectGetMaxY(self.heading.frame)+(wide?18:30);
    CGFloat heroHeight=wide?MAX(142,MIN(360,h-top-128)):MAX(270,MIN(440,h-top-140));
    if (UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory)) heroHeight+=100;
    self.gallery.frame=CGRectMake(pad,top,w-pad*2,heroHeight);
    CGSize size=self.gallery.bounds.size;
    if (!CGSizeEqualToSize(self.galleryLayout.itemSize,size)) {
        self.galleryLayout.itemSize=size; [self.galleryLayout invalidateLayout];
        if (self.profiles.count) [self.gallery setContentOffset:CGPointMake(self.focusedIndex*(size.width+12),0) animated:NO];
    }
    CGFloat playWidth=MIN(w-48,wide?360:420), playX=wide?MAX(pad,(w-playWidth)/2+MIN(60,w*0.05)):(w-playWidth)/2;
    self.playButton.frame=CGRectMake(playX,CGRectGetMaxY(self.gallery.frame)+12,playWidth,wide?54:60);
    self.pages.frame=CGRectMake((w-140)/2,CGRectGetMaxY(self.playButton.frame)+5,140,24);
    self.moreButton.frame=CGRectMake(pad,CGRectGetMaxY(self.pages.frame),100,44);
    self.jitLabel.frame=CGRectMake(w-pad-170,CGRectGetMinY(self.moreButton.frame),170,44);
    CGFloat contentHeight=MAX(h,CGRectGetMaxY(self.moreButton.frame)+6);
    self.canvas.frame=CGRectMake(0,0,w,contentHeight); self.page.contentSize=self.canvas.bounds.size;
    self.emptyLabel.frame=CGRectMake(pad,top+heroHeight/2-70,w-2*pad,90);
    self.installButton.frame=CGRectMake((w-MIN(280,w-48))/2,CGRectGetMaxY(self.emptyLabel.frame)+20,MIN(280,w-48),48);
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; self.visible = YES;
    [self refreshProfiles];
    [NSNotificationCenter.defaultCenter postNotificationName:@"LiraWorldMotionChanged" object:@YES];
    if (LiraMotionAllowed()) {
        self.heading.alpha = 0; self.heading.transform = CGAffineTransformMakeTranslation(0,10);
        [UIView animateWithDuration:0.55 delay:0.03 usingSpringWithDamping:0.9 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self.heading.alpha=1; self.heading.transform=CGAffineTransformIdentity; } completion:nil];
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated]; self.visible=NO; self.launchRequest++;
    self.playButton.launching=NO;
    [NSNotificationCenter.defaultCenter postNotificationName:@"LiraWorldMotionChanged" object:@NO];
}
- (void)refreshProfiles {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(),^{[self refreshProfiles];}); return; }
    if (self.selectingProfile || !self.isViewLoaded) return;
    NSArray *names = [PLProfiles.current.profiles.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableArray *valid = NSMutableArray.array;
    for (NSString *name in names) if (LiraProfileVersion(name).length) [valid addObject:name];
    BOOL changed = ![self.profiles isEqualToArray:valid]; self.profiles = valid;
    NSUInteger selected = [self.profiles indexOfObject:PLProfiles.current.selectedProfileName];
    self.focusedIndex = selected == NSNotFound ? 0 : selected;
    if (changed) [self.gallery reloadData];
    else for (NSIndexPath *path in self.gallery.indexPathsForVisibleItems) {
        [(LiraWorldInstanceCell *)[self.gallery cellForItemAtIndexPath:path] configureProfile:self.profiles[path.item] focused:path.item==self.focusedIndex];
    }
    self.pages.numberOfPages = self.profiles.count; self.pages.currentPage = self.focusedIndex;
    self.emptyLabel.hidden = self.profiles.count > 0; self.installButton.hidden = self.profiles.count > 0;
    self.gallery.hidden = !self.profiles.count; self.playButton.hidden = !self.profiles.count;
    if (!self.draggingGallery && self.galleryLayout.itemSize.width>0) [self.gallery setContentOffset:CGPointMake(self.focusedIndex*(self.galleryLayout.itemSize.width+12),0) animated:NO];
    [self publishScene];
    [NSNotificationCenter.defaultCenter postNotificationName:AmeRightPanelRequestStateNotification object:nil];
}
- (void)publishScene {
    NSString *name = self.profiles.count ? self.profiles[self.focusedIndex] : nil;
    [NSNotificationCenter.defaultCenter postNotificationName:LiraWorldSceneChangedNotification object:LiraSceneForProfile(name)];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section { return self.profiles.count; }
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)path {
    LiraWorldInstanceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"world" forIndexPath:path];
    [cell configureProfile:self.profiles[path.item] focused:path.item==self.focusedIndex]; return cell;
}
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated {
    if (index<0 || index>=(NSInteger)self.profiles.count) return;
    self.focusedIndex=index; self.selectingProfile=YES;
    [PLProfiles.current setSelectedProfileName:self.profiles[index]];
    self.selectingProfile=NO; self.pages.currentPage=index;
    [self publishScene];
    for (NSIndexPath *path in self.gallery.indexPathsForVisibleItems) {
        LiraWorldInstanceCell *cell=(id)[self.gallery cellForItemAtIndexPath:path];
        [UIView animateWithDuration:LiraMotionAllowed()?0.3:0 animations:^{ [cell configureProfile:self.profiles[path.item] focused:path.item==index]; }];
    }
    [self.gallery setContentOffset:CGPointMake(index*(self.galleryLayout.itemSize.width+12),0) animated:animated && LiraMotionAllowed()];
    [NSNotificationCenter.defaultCenter postNotificationName:AmeRightPanelRequestStateNotification object:nil];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)path { [self selectIndex:path.item animated:YES]; }
- (void)pageChanged { [self selectIndex:self.pages.currentPage animated:YES]; }
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { if (scrollView==self.gallery) { self.draggingGallery=YES; self.playButton.enabled=NO; } }
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)offset {
    if (scrollView!=self.gallery || !self.profiles.count) return;
    CGFloat step=self.galleryLayout.itemSize.width+12;
    NSInteger index=MIN((NSInteger)self.profiles.count-1,MAX(0,(NSInteger)llround(offset->x/step)));
    offset->x=index*step;
}
- (void)gallerySettled {
    self.draggingGallery=NO;
    CGFloat step=self.galleryLayout.itemSize.width+12;
    [self selectIndex:(NSInteger)llround(self.gallery.contentOffset.x/MAX(step,1)) animated:NO];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView { if (scrollView==self.gallery) [self gallerySettled]; }
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate { if (scrollView==self.gallery && !decelerate) [self gallerySettled]; }
- (void)stateChanged:(NSNotification *)note {
    NSDictionary *info=note.userInfo.copy;
    dispatch_async(dispatch_get_main_queue(),^{
        self.launchState=info;
        BOOL signedIn=BaseAuthenticator.current!=nil;
        self.greeting.text=signedIn ? [NSString stringWithFormat:localize(@"lira.world.welcome",nil),info[@"user"]?:@""] : localize(@"lira.world.welcome_guest",nil);
        UIImage *avatar=info[@"avatar"];
        if ([avatar isKindOfClass:UIImage.class]) [self.avatar setImage:[avatar imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        self.jitLabel.text=info[@"jit"]?:localize(@"login.jit.checking",nil);
        self.jitLabel.textColor=LiraColor(0xAAAAAA);
        self.playButton.enabled=[info[@"launchEnabled"] boolValue] && !self.draggingGallery;
        if (!self.playButton.launching) self.playButton.title=info[@"launchTitle"]?:localize(@"Play",nil);
    });
}
- (void)progressChanged {
    if (!self.visible || !self.playButton.launching) return;
    self.playButton.progress=AmeLaunchProgressCurrentFraction();
    self.playButton.title=localize(AmeLaunchProgressCurrentKey()?:AmeLaunchStageLocalizationKey(AmeLaunchStagePrepareEnv),nil);
}
- (void)play {
    if (self.playButton.launching || !self.playButton.enabled) return;
    self.playButton.launching=YES; self.playButton.progress=0;
    self.playButton.title=localize(@"lira.world.preparing",nil);
    NSUInteger request=++self.launchRequest;
    if (LiraMotionAllowed()) {
        UIView *portal=[[UIView alloc] initWithFrame:CGRectMake(0,0,80,80)];
        portal.center=[self.canvas convertPoint:self.playButton.center fromView:self.playButton.superview];
        portal.userInteractionEnabled=NO; portal.layer.cornerRadius=40;
        portal.layer.borderColor=LiraMint().CGColor; portal.layer.borderWidth=2;
        portal.layer.shadowColor=LiraMint().CGColor; portal.layer.shadowOpacity=0.8; portal.layer.shadowRadius=24;
        [self.canvas insertSubview:portal belowSubview:self.playButton];
        [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{ portal.transform=CGAffineTransformMakeScale(7,7); portal.alpha=0; } completion:^(BOOL finished){ [portal removeFromSuperview]; }];
    }
    [LauncherRightPanelViewController norightPostAction:@"launch"];
    // A rejected launch or a JIT/account dialog must never leave a fake progress indicator behind.
    __weak typeof(self) weakSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{
        typeof(self) self=weakSelf;
        if (!self || request!=self.launchRequest || !self.visible) return;
        if ([self.launchState[@"launchEnabled"] boolValue]) {
            self.playButton.launching=NO;
            self.playButton.title=self.launchState[@"launchTitle"]?:localize(@"Play",nil);
        }
    });
}
- (void)push:(UIViewController *)vc { [self.navigationController setNavigationBarHidden:NO animated:YES]; [self.navigationController pushViewController:vc animated:YES]; }
- (void)accounts { [LauncherRightPanelViewController norightPostAction:@"accountManager"]; }
- (void)downloads { self.tabBarController.selectedIndex=1; }
- (void)showTools {
    NSMutableArray *actions=NSMutableArray.array;
    NSArray *items=@[
        @[localize(@"lira.cover.choose",nil),@"cover"], @[localize(@"lira.home.account",nil),@"account"],
        @[localize(@"lira.home.mods",nil),@"mods"], @[localize(@"lira.home.import",nil),@"import"],
        @[localize(@"lira.home.downloads",nil),@"downloads"], @[localize(@"lira.home.history",nil),@"history"],
        @[localize(@"lira.home.multiplayer",nil),@"multiplayer"], @[localize(@"lira.home.news",nil),@"news"], @[localize(@"tab.ai",nil),@"ai"]];
    __weak typeof(self) weakSelf=self;
    for (NSArray *item in items) [actions addObject:[LiraSheetAction title:item[0] handler:^{
        typeof(self) self=weakSelf; if (!self) return; NSString *key=item[1];
        if ([key isEqual:@"cover"]) LiraChooseProfileCover(self,PLProfiles.current.selectedProfileName);
        else if ([key isEqual:@"account"]) [self accounts];
        else if ([key isEqual:@"mods"]) { ModsManagerViewController *vc=[ModsManagerViewController new]; vc.profileName=PLProfiles.current.selectedProfileName; [self push:vc]; }
        else if ([key isEqual:@"import"]) [self push:[ModpackImportViewController new]];
        else if ([key isEqual:@"downloads"]) [LauncherRightPanelViewController norightPostAction:@"downloadCenter"];
        else if ([key isEqual:@"history"]) [self push:[DownloadHistoryViewController new]];
        else if ([key isEqual:@"multiplayer"]) [self push:[TerracottaViewController new]];
        else if ([key isEqual:@"news"]) [self push:[MinecraftNewsViewController new]];
        else if ([key isEqual:@"ai"]) self.tabBarController.selectedIndex=2;
    }]];
    LiraPresentSheet(self,localize(@"lira.world.tools",nil),actions);
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end
