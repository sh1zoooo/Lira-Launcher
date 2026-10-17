#import "LiraHomeViewController.h"
#import "LiraLivingWorld.h"
#import "LiraTheme.h"
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
@property(nonatomic, strong) UILabel *gameLabel;
@property(nonatomic, strong) UILabel *versionLabel;
@property(nonatomic, strong) UILabel *loaderLabel;
@property(nonatomic, strong) UIStackView *details;
- (void)configureProfile:(NSString *)name focused:(BOOL)focused;
@end
@implementation LiraWorldInstanceCell
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.cover = [[UIImageView alloc] init]; self.cover.translatesAutoresizingMaskIntoConstraints = NO;
        self.cover.contentMode = UIViewContentModeScaleAspectFill; self.cover.clipsToBounds = YES;
        self.cover.layer.cornerRadius = 22; self.cover.layer.cornerCurve = kCACornerCurveContinuous;
        self.cover.layer.borderWidth = 1.3; self.cover.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.6].CGColor;
        [self.contentView addSubview:self.cover];
        self.details = [[UIStackView alloc] init]; self.details.axis = UILayoutConstraintAxisVertical;
        self.details.spacing = 5; self.details.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.details];
        self.nameLabel = [[UILabel alloc] init]; self.nameLabel.font = LiraFont(UIFontTextStyleCaption1,12,UIFontWeightSemibold);
        self.nameLabel.textColor = LiraColor(0xBCE7CE);
        self.gameLabel = [[UILabel alloc] init];
        self.gameLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle1] scaledFontForFont:[UIFont fontWithName:@"AvenirNextCondensed-Heavy" size:38] ?: [UIFont boldSystemFontOfSize:36]];
        self.gameLabel.text = @"MINECRAFT"; self.gameLabel.textColor = LiraColor(0xF0F7EB);
        self.gameLabel.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.8]; self.gameLabel.shadowOffset = CGSizeMake(0,3);
        self.versionLabel = [[UILabel alloc] init]; self.versionLabel.font = LiraFont(UIFontTextStyleTitle3,20,UIFontWeightBold);
        self.versionLabel.textColor = UIColor.whiteColor;
        self.loaderLabel = [[UILabel alloc] init]; self.loaderLabel.font = LiraFont(UIFontTextStyleSubheadline,14,UIFontWeightMedium);
        self.loaderLabel.textColor = LiraColor(0xA5EBC6);
        for (UILabel *label in @[self.nameLabel,self.gameLabel,self.versionLabel,self.loaderLabel]) {
            label.adjustsFontForContentSizeCategory = YES; label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.65;
            [self.details addArrangedSubview:label];
        }
        NSLayoutConstraint *coverWidth=[self.cover.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor multiplier:0.30];
        coverWidth.priority=999;
        [NSLayoutConstraint activateConstraints:@[
            [self.cover.widthAnchor constraintLessThanOrEqualToConstant:128], coverWidth,
            [self.cover.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.cover.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.cover.heightAnchor constraintEqualToAnchor:self.cover.widthAnchor multiplier:1.08],
            [self.cover.heightAnchor constraintLessThanOrEqualToAnchor:self.contentView.heightAnchor constant:-8],
            [self.details.leadingAnchor constraintEqualToAnchor:self.cover.trailingAnchor constant:18],
            [self.details.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-6],
            [self.details.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
        ]];
        self.isAccessibilityElement = YES;
    }
    return self;
}
- (void)configureProfile:(NSString *)name focused:(BOOL)focused {
    self.cover.image = LiraWorldImage(LiraSceneForProfile(name));
    self.nameLabel.text = [name isEqualToString:@"(Default)"] ? localize(@"lira.home.default_profile",nil) : name;
    self.versionLabel.text = LiraProfileVersion(name);
    self.loaderLabel.text = [NSString stringWithFormat:@"◈  %@", LiraProfileLoader(name)];
    self.contentView.alpha = focused ? 1 : 0.55;
    self.contentView.transform = focused || !LiraMotionAllowed() ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.90,0.90);
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@",self.nameLabel.text,self.versionLabel.text,self.loaderLabel.text];
    self.accessibilityTraits = UIAccessibilityTraitButton | (focused ? UIAccessibilityTraitSelected : 0);
}
@end

@interface LiraHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property(nonatomic, strong) UIScrollView *page;
@property(nonatomic, strong) UIView *canvas;
@property(nonatomic, strong) UIStackView *heading;
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
@property(nonatomic, strong) NSLayoutConstraint *skyHeight;
@property(nonatomic, strong) NSLayoutConstraint *galleryHeight;
@end

@implementation LiraHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.tintColor = LiraMint();
    self.page = [[UIScrollView alloc] init]; self.page.translatesAutoresizingMaskIntoConstraints = NO;
    self.page.showsVerticalScrollIndicator = NO;
    self.page.alwaysBounceVertical = NO;
    [self.view addSubview:self.page];
    self.canvas = [[UIView alloc] init]; self.canvas.translatesAutoresizingMaskIntoConstraints = NO;
    [self.page addSubview:self.canvas];
    [NSLayoutConstraint activateConstraints:@[
        [self.page.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.page.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.page.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.page.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.canvas.leadingAnchor constraintEqualToAnchor:self.page.contentLayoutGuide.leadingAnchor],
        [self.canvas.trailingAnchor constraintEqualToAnchor:self.page.contentLayoutGuide.trailingAnchor],
        [self.canvas.topAnchor constraintEqualToAnchor:self.page.contentLayoutGuide.topAnchor],
        [self.canvas.bottomAnchor constraintEqualToAnchor:self.page.contentLayoutGuide.bottomAnchor],
        [self.canvas.widthAnchor constraintEqualToAnchor:self.page.frameLayoutGuide.widthAnchor],
        [self.canvas.heightAnchor constraintGreaterThanOrEqualToAnchor:self.page.frameLayoutGuide.heightAnchor]
    ]];
    [self buildHeader]; [self buildGallery];
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(stateChanged:) name:AmeRightPanelStateNotification object:nil];
    [center addObserver:self selector:@selector(progressChanged) name:AmeLaunchProgressChangedNotification object:nil];
    for (NSString *name in @[@"SelectedProfileChanged",@"ProfileListChanged",@"VersionListChanged",UIApplicationWillEnterForegroundNotification]) {
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
    self.heading = [[UIStackView alloc] init]; self.heading.axis = UILayoutConstraintAxisVertical;
    self.heading.spacing = 2; self.heading.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *wordmark = [self labelWithSize:40 weight:UIFontWeightHeavy];
    wordmark.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleLargeTitle] scaledFontForFont:[UIFont fontWithName:@"AvenirNext-Heavy" size:40] ?: [UIFont boldSystemFontOfSize:40]];
    wordmark.attributedText = [[NSAttributedString alloc] initWithString:@"LIRA✦" attributes:@{NSKernAttributeName:@2, NSForegroundColorAttributeName:LiraColor(0xD1FFE7)}];
    [self.heading addArrangedSubview:wordmark];
    self.greeting = [self labelWithSize:15 weight:UIFontWeightMedium]; self.greeting.numberOfLines = 2;
    [self.heading addArrangedSubview:self.greeting];
    [self.canvas addSubview:self.heading];
    self.avatar = [UIButton buttonWithType:UIButtonTypeSystem]; self.avatar.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatar.backgroundColor = [LiraColor(0x002B19) colorWithAlphaComponent:0.8];
    self.avatar.layer.cornerRadius = 17; self.avatar.clipsToBounds = YES;
    self.avatar.layer.borderWidth = 1; self.avatar.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.5].CGColor;
    [self.avatar setImage:[UIImage systemImageNamed:@"person.crop.square.fill"] forState:UIControlStateNormal];
    self.avatar.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatar.accessibilityLabel = localize(@"lira.home.account",nil);
    [self.avatar addTarget:self action:@selector(accounts) forControlEvents:UIControlEventTouchUpInside];
    [self.canvas addSubview:self.avatar];
    self.jitLabel = [self labelWithSize:11 weight:UIFontWeightSemibold]; self.jitLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.jitLabel.text = localize(@"login.jit.checking",nil); self.jitLabel.textColor = LiraMint();
    self.jitLabel.numberOfLines = 2; self.jitLabel.textAlignment = NSTextAlignmentRight;
    [self.canvas addSubview:self.jitLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.heading.topAnchor constraintEqualToAnchor:self.canvas.topAnchor constant:18],
        [self.heading.leadingAnchor constraintEqualToAnchor:self.canvas.leadingAnchor constant:24],
        [self.heading.trailingAnchor constraintLessThanOrEqualToAnchor:self.avatar.leadingAnchor constant:-16],
        [self.avatar.topAnchor constraintEqualToAnchor:self.heading.topAnchor constant:4],
        [self.avatar.trailingAnchor constraintEqualToAnchor:self.canvas.trailingAnchor constant:-24],
        [self.avatar.widthAnchor constraintEqualToConstant:48], [self.avatar.heightAnchor constraintEqualToConstant:48],
        [self.jitLabel.topAnchor constraintEqualToAnchor:self.avatar.bottomAnchor constant:7],
        [self.jitLabel.trailingAnchor constraintEqualToAnchor:self.avatar.trailingAnchor],
        [self.jitLabel.widthAnchor constraintLessThanOrEqualToConstant:130]
    ]];
}
- (void)buildGallery {
    UIView *sky = [[UIView alloc] init]; sky.translatesAutoresizingMaskIntoConstraints = NO; sky.userInteractionEnabled = NO;
    [self.canvas addSubview:sky];
    self.skyHeight = [sky.heightAnchor constraintEqualToConstant:160];
    self.galleryLayout = [[UICollectionViewFlowLayout alloc] init];
    self.galleryLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.galleryLayout.minimumLineSpacing = 12;
    self.galleryLayout.sectionInset = UIEdgeInsetsMake(0,24,0,24);
    self.gallery = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.galleryLayout];
    self.gallery.translatesAutoresizingMaskIntoConstraints = NO; self.gallery.backgroundColor = UIColor.clearColor;
    self.gallery.showsHorizontalScrollIndicator = NO; self.gallery.decelerationRate = UIScrollViewDecelerationRateFast;
    self.gallery.dataSource = self; self.gallery.delegate = self;
    self.galleryHeight = [self.gallery.heightAnchor constraintEqualToConstant:170];
    [self.gallery registerClass:LiraWorldInstanceCell.class forCellWithReuseIdentifier:@"world"];
    [self.canvas addSubview:self.gallery];
    self.emptyLabel = [self labelWithSize:24 weight:UIFontWeightBold]; self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.numberOfLines = 0; self.emptyLabel.text = localize(@"lira.world.empty",nil);
    [self.canvas addSubview:self.emptyLabel];
    self.installButton = [UIButton buttonWithType:UIButtonTypeSystem]; self.installButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.installButton setTitle:localize(@"lira.world.install",nil) forState:UIControlStateNormal];
    [self.installButton setTitleColor:LiraMint() forState:UIControlStateNormal];
    self.installButton.titleLabel.font = LiraFont(UIFontTextStyleHeadline,17,UIFontWeightSemibold);
    [self.installButton addTarget:self action:@selector(downloads) forControlEvents:UIControlEventTouchUpInside];
    [self.canvas addSubview:self.installButton];
    self.playButton = [[LiraPlayButton alloc] init]; self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.playButton.title = localize(@"Play",nil); self.playButton.enabled = NO;
    self.playButton.accessibilityIdentifier = @"lira.play";
    [self.playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [self.canvas addSubview:self.playButton];
    self.pages = [[UIPageControl alloc] init]; self.pages.translatesAutoresizingMaskIntoConstraints = NO;
    self.pages.pageIndicatorTintColor = [LiraMint() colorWithAlphaComponent:0.2]; self.pages.currentPageIndicatorTintColor = LiraMint();
    self.pages.hidesForSinglePage = YES;
    [self.pages addTarget:self action:@selector(pageChanged) forControlEvents:UIControlEventValueChanged];
    [self.canvas addSubview:self.pages];
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem]; self.moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.moreButton setTitle:localize(@"lira.world.tools",nil) forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis.circle"] forState:UIControlStateNormal];
    self.moreButton.titleLabel.font = LiraFont(UIFontTextStyleSubheadline,14,UIFontWeightMedium);
    self.moreButton.imageEdgeInsets = UIEdgeInsetsMake(0,-5,0,5);
    [self.moreButton setTitleColor:LiraColor(0xBDE4CD) forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(showTools) forControlEvents:UIControlEventTouchUpInside];
    [self.canvas addSubview:self.moreButton];
    NSLayoutConstraint *playWidth = [self.playButton.widthAnchor constraintEqualToAnchor:self.canvas.widthAnchor constant:-48]; playWidth.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
        [sky.topAnchor constraintEqualToAnchor:self.heading.bottomAnchor constant:16],
        [sky.leadingAnchor constraintEqualToAnchor:self.canvas.leadingAnchor], self.skyHeight,
        [self.gallery.topAnchor constraintEqualToAnchor:sky.bottomAnchor],
        [self.gallery.leadingAnchor constraintEqualToAnchor:self.canvas.leadingAnchor],
        [self.gallery.trailingAnchor constraintEqualToAnchor:self.canvas.trailingAnchor],
        self.galleryHeight,
        [self.emptyLabel.leadingAnchor constraintEqualToAnchor:self.canvas.leadingAnchor constant:24],
        [self.emptyLabel.trailingAnchor constraintEqualToAnchor:self.canvas.trailingAnchor constant:-24],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.gallery.centerYAnchor constant:-18],
        [self.installButton.topAnchor constraintEqualToAnchor:self.emptyLabel.bottomAnchor constant:12],
        [self.installButton.leadingAnchor constraintEqualToAnchor:self.emptyLabel.leadingAnchor],
        [self.installButton.heightAnchor constraintGreaterThanOrEqualToConstant:44],
        [self.playButton.topAnchor constraintEqualToAnchor:self.gallery.bottomAnchor constant:12],
        [self.playButton.leadingAnchor constraintEqualToAnchor:self.canvas.leadingAnchor constant:24],
        playWidth, [self.playButton.widthAnchor constraintLessThanOrEqualToConstant:520],
        [self.playButton.heightAnchor constraintEqualToConstant:64],
        [self.pages.topAnchor constraintEqualToAnchor:self.playButton.bottomAnchor constant:8],
        [self.pages.centerXAnchor constraintEqualToAnchor:self.playButton.centerXAnchor],
        [self.pages.heightAnchor constraintEqualToConstant:24],
        [self.moreButton.topAnchor constraintEqualToAnchor:self.pages.bottomAnchor constant:0],
        [self.moreButton.leadingAnchor constraintEqualToAnchor:self.playButton.leadingAnchor],
        [self.moreButton.heightAnchor constraintGreaterThanOrEqualToConstant:44],
        [self.moreButton.bottomAnchor constraintEqualToAnchor:self.canvas.bottomAnchor constant:-12]
    ]];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width, height = self.page.bounds.size.height;
    // Retain scenery on large screens; short landscape screens scroll vertically instead of clipping controls.
    CGFloat galleryHeight=UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory)?260:170;
    self.galleryHeight.constant=galleryHeight;
    self.skyHeight.constant = MAX(24, height - 368 - self.heading.bounds.size.height - (galleryHeight-170));
    if (fabs(width-self.lastWidth)>1 || self.galleryLayout.itemSize.height!=galleryHeight) {
        self.lastWidth = width;
        self.galleryLayout.itemSize = CGSizeMake(MIN(560,MAX(260,width*0.82)),galleryHeight);
        [self.galleryLayout invalidateLayout];
        if (self.profiles.count) [self.gallery setContentOffset:CGPointMake(self.focusedIndex*(self.galleryLayout.itemSize.width+12),0) animated:NO];
    }
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
        self.jitLabel.textColor=info[@"jitColor"]?:LiraMint();
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
    UIAlertController *sheet=[UIAlertController alertControllerWithTitle:localize(@"lira.world.tools",nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *items=@[
        @[localize(@"lira.home.mods",nil),@"mods"], @[localize(@"lira.home.import",nil),@"import"],
        @[localize(@"lira.home.downloads",nil),@"downloads"], @[localize(@"lira.home.history",nil),@"history"],
        @[localize(@"lira.home.multiplayer",nil),@"multiplayer"], @[localize(@"lira.home.news",nil),@"news"],
        @[localize(@"tab.ai",nil),@"ai"]];
    __weak typeof(self) weakSelf=self;
    for (NSArray *item in items) [sheet addAction:[UIAlertAction actionWithTitle:item[0] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        typeof(self) self=weakSelf; if (!self) return;
        NSString *key=item[1];
        if ([key isEqual:@"mods"]) { ModsManagerViewController *vc=[[ModsManagerViewController alloc] init]; vc.profileName=PLProfiles.current.selectedProfileName; [self push:vc]; }
        else if ([key isEqual:@"import"]) [self push:[[ModpackImportViewController alloc] init]];
        else if ([key isEqual:@"downloads"]) [LauncherRightPanelViewController norightPostAction:@"downloadCenter"];
        else if ([key isEqual:@"history"]) [self push:[[DownloadHistoryViewController alloc] init]];
        else if ([key isEqual:@"multiplayer"]) [self push:[[TerracottaViewController alloc] init]];
        else if ([key isEqual:@"news"]) [self push:[[MinecraftNewsViewController alloc] init]];
        else if ([key isEqual:@"ai"]) self.tabBarController.selectedIndex=2;
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:localize(@"Cancel",nil) style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView=self.moreButton;
    sheet.popoverPresentationController.sourceRect=self.moreButton.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end
