#import "LiraHomeViewController.h"
#import "LiraTheme.h"
#import "utils.h"
#import "PLProfiles.h"
#import "LauncherRightPanelViewController.h"
#import "DownloadViewController.h"
#import "DownloadHistoryViewController.h"
#import "ModsManagerViewController.h"
#import "ShadersManagerViewController.h"
#import "ModpackImportViewController.h"
#import "MinecraftNewsViewController.h"
#import "TerracottaViewController.h"

static NSString * const LiraFavoritesKey = @"lira.favoriteProfiles";

@interface LiraHomeViewController () <UISearchBarDelegate>
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *stack;
@property(nonatomic, strong) UIStackView *profileStack;
@property(nonatomic, strong) UILabel *versionLabel;
@property(nonatomic, strong) UILabel *userLabel;
@property(nonatomic, strong) UILabel *jitLabel;
@property(nonatomic, strong) UILabel *downloadsLabel;
@property(nonatomic, strong) UILabel *storageLabel;
@property(nonatomic, strong) UIButton *playButton;
@property(nonatomic, strong) UIButton *downloadsButton;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) UISegmentedControl *filter;
@property(nonatomic, strong) UIStackView *quickActions;
@property(nonatomic, strong) UIStackView *secondaryActions;
@property(nonatomic, copy) NSDictionary *lastState;
@property(nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation LiraHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.view.tintColor = accentColor();
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scrollView];
    self.stack = [self verticalStack:24];
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:16],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-28],
        [self.stack.centerXAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.centerXAnchor],
        [self.stack.widthAnchor constraintLessThanOrEqualToConstant:1000]
    ]];
    NSLayoutConstraint *width = [self.stack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32];
    width.priority = 999;
    width.active = YES;
    [self buildHeader];
    [self buildLaunchCard];
    [self buildQuickActions];
    [self buildProfiles];
    [self buildStatus];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.scrollView.refreshControl = self.refreshControl;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(stateChanged:) name:AmeRightPanelStateNotification object:nil];
    for (NSString *name in @[@"SelectedProfileChanged", @"ProfileListChanged", @"VersionListChanged", UIApplicationWillEnterForegroundNotification]) {
        [center addObserver:self selector:@selector(refresh) name:name object:nil];
    }
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    BOOL compact = self.view.bounds.size.width < 340 || UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory);
    UILayoutConstraintAxis axis = compact ? UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
    self.quickActions.axis = axis;
    self.secondaryActions.axis = axis;
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (UIStackView *)verticalStack:(CGFloat)spacing {
    UIStackView *s = [[UIStackView alloc] init];
    s.axis = UILayoutConstraintAxisVertical;
    s.spacing = spacing;
    return s;
}

- (UILabel *)label:(NSString *)text style:(UIFontTextStyle)style size:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = LiraFont(style, size, weight);
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = UIColor.labelColor;
    label.numberOfLines = 0;
    return label;
}

- (UIView *)cardWithStack:(UIStackView *)content {
    UIView *card = [[UIView alloc] init];
    LiraStyleCard(card);
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:22],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-22],
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:22],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-22]
    ]];
    return card;
}

- (UIButton *)button:(NSString *)title symbol:(NSString *)symbol action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    b.titleLabel.font = LiraFont(UIFontTextStyleSubheadline, 15, UIFontWeightSemibold);
    b.titleLabel.adjustsFontForContentSizeCategory = YES;
    b.titleLabel.numberOfLines = 0;
    b.contentEdgeInsets = UIEdgeInsetsMake(14, 16, 14, 16);
    b.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5);
    b.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, -5);
    b.layer.cornerRadius = 16;
    b.layer.cornerCurve = kCACornerCurveContinuous;
    b.backgroundColor = LiraSecondarySurface();
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)buildHeader {
    UIStackView *header = [self verticalStack:5];
    [header addArrangedSubview:[self label:@"LIRA" style:UIFontTextStyleCaption1 size:12 weight:UIFontWeightHeavy]];
    [header addArrangedSubview:[self label:localize(@"lira.home.title", nil) style:UIFontTextStyleLargeTitle size:34 weight:UIFontWeightBold]];
    UILabel *subtitle = [self label:localize(@"lira.home.subtitle", nil) style:UIFontTextStyleSubheadline size:15 weight:UIFontWeightRegular];
    subtitle.textColor = UIColor.secondaryLabelColor;
    [header addArrangedSubview:subtitle];
    [self.stack addArrangedSubview:header];
}

- (void)buildLaunchCard {
    UIStackView *content = [self verticalStack:14];
    UIStackView *top = [[UIStackView alloc] init];
    top.alignment = UIStackViewAlignmentCenter;
    top.spacing = 12;
    UILabel *eyebrow = [self label:localize(@"lira.home.selected", nil) style:UIFontTextStyleCaption1 size:12 weight:UIFontWeightSemibold];
    eyebrow.textColor = UIColor.secondaryLabelColor;
    [top addArrangedSubview:eyebrow];
    [top addArrangedSubview:[[UIView alloc] init]];
    UIButton *choose = [self button:localize(@"lira.home.change", nil) symbol:@"chevron.up.chevron.down" action:@selector(chooseVersion)];
    [choose setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [top addArrangedSubview:choose];
    [content addArrangedSubview:top];
    self.versionLabel = [self label:localize(@"lira.home.no_version", nil) style:UIFontTextStyleTitle1 size:28 weight:UIFontWeightBold];
    [content addArrangedSubview:self.versionLabel];
    self.userLabel = [self label:localize(@"lira.home.account", nil) style:UIFontTextStyleSubheadline size:15 weight:UIFontWeightRegular];
    self.userLabel.textColor = UIColor.secondaryLabelColor;
    [content addArrangedSubview:self.userLabel];
    self.playButton = [self button:localize(@"Play", nil) symbol:@"play.fill" action:@selector(play)];
    self.playButton.backgroundColor = accentColor();
    [self.playButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.playButton.tintColor = UIColor.whiteColor;
    self.playButton.titleLabel.font = LiraFont(UIFontTextStyleHeadline, 19, UIFontWeightBold);
    self.playButton.enabled = NO;
    self.playButton.accessibilityIdentifier = @"lira.play";
    [self.playButton.heightAnchor constraintGreaterThanOrEqualToConstant:58].active = YES;
    [content addArrangedSubview:self.playButton];
    [content addArrangedSubview:[self button:localize(@"lira.home.account", nil) symbol:@"person.crop.circle" action:@selector(accounts)]];
    [self.stack addArrangedSubview:[self cardWithStack:content]];
}

- (void)buildQuickActions {
    UIStackView *section = [self verticalStack:12];
    [section addArrangedSubview:[self label:localize(@"lira.home.quick_actions", nil) style:UIFontTextStyleTitle2 size:21 weight:UIFontWeightBold]];
    self.quickActions = [[UIStackView alloc] init];
    self.quickActions.axis = UILayoutConstraintAxisHorizontal;
    self.quickActions.spacing = 10;
    self.quickActions.distribution = UIStackViewDistributionFillEqually;
    [self.quickActions addArrangedSubview:[self button:localize(@"lira.home.add_content", nil) symbol:@"square.and.arrow.down" action:@selector(downloads)]];
    [self.quickActions addArrangedSubview:[self button:localize(@"lira.home.import", nil) symbol:@"shippingbox" action:@selector(importModpack)]];
    [section addArrangedSubview:self.quickActions];
    UIStackView *row = [[UIStackView alloc] init];
    self.secondaryActions = row;
    row.spacing = 10;
    row.distribution = UIStackViewDistributionFillEqually;
    [row addArrangedSubview:[self button:localize(@"lira.home.mods", nil) symbol:@"puzzlepiece.extension" action:@selector(mods)]];
    [row addArrangedSubview:[self button:localize(@"lira.home.multiplayer", nil) symbol:@"person.2" action:@selector(multiplayer)]];
    [section addArrangedSubview:row];
    [self.stack addArrangedSubview:section];
}

- (void)buildProfiles {
    UIStackView *section = [self verticalStack:12];
    [section addArrangedSubview:[self label:localize(@"lira.home.library", nil) style:UIFontTextStyleTitle2 size:21 weight:UIFontWeightBold]];
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.placeholder = localize(@"lira.home.search", nil);
    self.searchBar.delegate = self;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [section addArrangedSubview:self.searchBar];
    self.filter = [[UISegmentedControl alloc] initWithItems:@[localize(@"lira.home.all", nil), localize(@"lira.home.favorites", nil)]];
    [self.filter addTarget:self action:@selector(rebuildProfiles) forControlEvents:UIControlEventValueChanged];
    self.filter.selectedSegmentIndex = 0;
    [section addArrangedSubview:self.filter];
    self.profileStack = [self verticalStack:10];
    [section addArrangedSubview:self.profileStack];
    [section addArrangedSubview:[self button:localize(@"lira.home.manage", nil) symbol:@"square.stack.3d.up" action:@selector(instances)]];
    [self.stack addArrangedSubview:section];
}

- (NSArray<NSString *> *)favorites {
    NSDictionary *all = [NSUserDefaults.standardUserDefaults dictionaryForKey:LiraFavoritesKey];
    NSArray *names = all[PLProfiles.current.profilePath];
    return [names isKindOfClass:NSArray.class] ? names : @[];
}

- (void)rebuildProfiles {
    for (UIView *view in self.profileStack.arrangedSubviews.copy) {
        [self.profileStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    PLProfiles *profiles = PLProfiles.current;
    NSArray *favorites = [self favorites];
    NSString *query = [self.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSArray *names = [profiles.profiles.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        BOOL af = [favorites containsObject:a], bf = [favorites containsObject:b];
        if (af != bf) return af ? NSOrderedAscending : NSOrderedDescending;
        return [a localizedStandardCompare:b];
    }];
    NSUInteger count = 0;
    for (NSString *name in names) {
        NSDictionary *p = profiles.profiles[name];
        NSString *version = [p[@"lastVersionId"] isKindOfClass:NSString.class] ? p[@"lastVersionId"] : @"";
        if (self.filter.selectedSegmentIndex == 1 && ![favorites containsObject:name]) continue;
        if (query.length && [name rangeOfString:query options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound &&
            [version rangeOfString:query options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location == NSNotFound) continue;
        UIStackView *row = [[UIStackView alloc] init];
        row.spacing = 10;
        row.alignment = UIStackViewAlignmentCenter;
        row.layoutMargins = UIEdgeInsetsMake(4, 4, 4, 8);
        row.layoutMarginsRelativeArrangement = YES;
        LiraStyleCard(row);
        BOOL selected = [name isEqualToString:profiles.selectedProfileName];
        NSString *display = [name isEqualToString:@"(Default)"] ? localize(@"lira.home.default_profile", nil) : name;
        UIButton *select = [self button:[NSString stringWithFormat:@"%@\n%@", display, version] symbol:selected ? @"checkmark.circle.fill" : @"cube" action:@selector(selectProfile:)];
        select.backgroundColor = UIColor.clearColor;
        select.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
        select.accessibilityIdentifier = name;
        select.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", display, version];
        select.accessibilityTraits |= selected ? UIAccessibilityTraitSelected : 0;
        [row addArrangedSubview:select];
        BOOL favorite = [favorites containsObject:name];
        UIButton *star = [self button:@"" symbol:favorite ? @"star.fill" : @"star" action:@selector(toggleFavorite:)];
        star.accessibilityIdentifier = name;
        star.accessibilityLabel = localize(favorite ? @"lira.home.unfavorite" : @"lira.home.favorite", nil);
        [star.widthAnchor constraintEqualToConstant:48].active = YES;
        [row addArrangedSubview:star];
        [self.profileStack addArrangedSubview:row];
        count++;
    }
    if (!count) {
        UIStackView *empty = [self verticalStack:8];
        [empty addArrangedSubview:[self label:localize(@"lira.home.empty", nil) style:UIFontTextStyleHeadline size:17 weight:UIFontWeightSemibold]];
        UILabel *hint = [self label:localize(@"lira.home.empty_hint", nil) style:UIFontTextStyleSubheadline size:14 weight:UIFontWeightRegular];
        hint.textColor = UIColor.secondaryLabelColor;
        [empty addArrangedSubview:hint];
        [self.profileStack addArrangedSubview:[self cardWithStack:empty]];
    }
}

- (void)selectProfile:(UIButton *)sender {
    NSString *name = sender.accessibilityIdentifier;
    if (!PLProfiles.current.profiles[name]) return;
    [PLProfiles.current setSelectedProfileName:name];
    [self refresh];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, localize(@"lira.home.profile_selected", nil));
}

- (void)toggleFavorite:(UIButton *)sender {
    NSMutableArray *names = [self favorites].mutableCopy;
    NSString *name = sender.accessibilityIdentifier;
    if ([names containsObject:name]) [names removeObject:name]; else [names addObject:name];
    NSMutableDictionary *all = [[NSUserDefaults.standardUserDefaults dictionaryForKey:LiraFavoritesKey] mutableCopy] ?: NSMutableDictionary.dictionary;
    all[PLProfiles.current.profilePath] = names;
    [NSUserDefaults.standardUserDefaults setObject:all forKey:LiraFavoritesKey];
    [self rebuildProfiles];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { [self rebuildProfiles]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; }

- (void)buildStatus {
    UIStackView *content = [self verticalStack:12];
    [content addArrangedSubview:[self label:localize(@"lira.home.status", nil) style:UIFontTextStyleHeadline size:17 weight:UIFontWeightSemibold]];
    self.jitLabel = [self label:localize(@"login.jit.checking", nil) style:UIFontTextStyleSubheadline size:14 weight:UIFontWeightRegular];
    self.jitLabel.accessibilityIdentifier = @"lira.jit";
    [content addArrangedSubview:self.jitLabel];
    self.storageLabel = [self label:@"" style:UIFontTextStyleSubheadline size:14 weight:UIFontWeightRegular];
    self.storageLabel.textColor = UIColor.secondaryLabelColor;
    [content addArrangedSubview:self.storageLabel];
    self.downloadsLabel = [self label:@"" style:UIFontTextStyleSubheadline size:14 weight:UIFontWeightRegular];
    [content addArrangedSubview:self.downloadsLabel];
    [content addArrangedSubview:[self button:localize(@"lira.home.downloads", nil) symbol:@"arrow.down.circle" action:@selector(downloadCenter)]];
    [content addArrangedSubview:[self button:localize(@"lira.home.history", nil) symbol:@"clock.arrow.circlepath" action:@selector(history)]];
    [content addArrangedSubview:[self button:localize(@"lira.home.news", nil) symbol:@"newspaper" action:@selector(news)]];
    [self.stack addArrangedSubview:[self cardWithStack:content]];
}

- (void)refresh {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(), ^{ [self refresh]; }); return; }
    [self rebuildProfiles];
    NSDictionary *attrs = [NSFileManager.defaultManager attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *bytes = attrs[NSFileSystemFreeSize];
    self.storageLabel.text = bytes ? [NSString stringWithFormat:localize(@"lira.home.storage", nil),
        [NSByteCountFormatter stringFromByteCount:bytes.longLongValue countStyle:NSByteCountFormatterCountStyleFile]] : @"";
    [NSNotificationCenter.defaultCenter postNotificationName:AmeRightPanelRequestStateNotification object:nil];
    [self.refreshControl endRefreshing];
}

- (void)stateChanged:(NSNotification *)note {
    NSDictionary *info = note.userInfo.copy;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lastState = info;
        self.versionLabel.text = info[@"version"] ?: localize(@"lira.home.no_version", nil);
        self.userLabel.text = info[@"user"] ?: localize(@"lira.home.account", nil);
        self.jitLabel.text = info[@"jit"] ?: localize(@"login.jit.checking", nil);
        self.jitLabel.textColor = info[@"jitColor"] ?: UIColor.secondaryLabelColor;
        [self.playButton setTitle:info[@"launchTitle"] ?: localize(@"Play", nil) forState:UIControlStateNormal];
        self.playButton.enabled = [info[@"launchEnabled"] boolValue];
        self.playButton.alpha = self.playButton.enabled ? 1 : 0.55;
        NSString *badge = info[@"dcBadge"];
        self.downloadsLabel.text = badge.length ? [NSString stringWithFormat:localize(@"lira.home.active_downloads", nil), badge, info[@"dcProgress"] ?: @""] : localize(@"lira.home.no_downloads", nil);
    });
}

// Actions use the original launch controller so JIT/auth/download checks stay centralized.
- (void)play { [LauncherRightPanelViewController norightPostAction:@"launch"]; }
- (void)chooseVersion { [LauncherRightPanelViewController norightPostAction:@"versionPicker"]; }
- (void)accounts { [LauncherRightPanelViewController norightPostAction:@"accountManager"]; }
- (void)downloadCenter { [LauncherRightPanelViewController norightPostAction:@"downloadCenter"]; }
- (void)downloads { self.tabBarController.selectedIndex = 1; }
- (void)instances { self.tabBarController.selectedIndex = 3; }
- (void)push:(UIViewController *)vc { [self.navigationController pushViewController:vc animated:YES]; }
- (void)importModpack { [self push:[[ModpackImportViewController alloc] init]]; }
- (void)mods {
    ModsManagerViewController *vc = [[ModsManagerViewController alloc] init];
    vc.profileName = PLProfiles.current.selectedProfileName;
    [self push:vc];
}
- (void)multiplayer { [self push:[[TerracottaViewController alloc] init]]; }
- (void)history { [self push:[[DownloadHistoryViewController alloc] init]]; }
- (void)news { [self push:[[MinecraftNewsViewController alloc] init]]; }
@end
