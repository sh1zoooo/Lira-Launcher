#import "LiraSettingsViewController.h"
#import "LiraTheme.h"
#import "LiraLivingWorld.h"
#import "LiraDesignKit.h"
#import "PLProfiles.h"
#import "utils.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherLanguageViewController.h"
#import "BackgroundSettingsViewController.h"
#import "LauncherPrefManageJREViewController.h"
#import "LauncherPrefContCfgViewController.h"
#import "LauncherPrefGameDirViewController.h"
#import "DownloadHistoryViewController.h"
#import "DownloadTasksViewController.h"
#import "AccountListViewController.h"

@interface LiraSettingCell : UITableViewCell
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UILabel *heading;
@property(nonatomic, strong) UILabel *detail;
@property(nonatomic, strong) UIImageView *symbol;
@end
@implementation LiraSettingCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    if ((self=[super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])) {
        self.backgroundColor=UIColor.clearColor; self.selectionStyle=UITableViewCellSelectionStyleNone;
        self.panel=[[UIView alloc] init]; self.panel.backgroundColor=LiraColor(0x262626);
        self.panel.layer.cornerRadius=20; self.panel.layer.borderWidth=0.5;
        self.panel.layer.borderColor=[LiraMint() colorWithAlphaComponent:0.16].CGColor;
        self.heading=[[UILabel alloc] init]; self.heading.font=LiraFont(UIFontTextStyleBody,17,UIFontWeightSemibold);
        self.heading.textColor=UIColor.whiteColor; self.heading.numberOfLines=0;
        self.detail=[[UILabel alloc] init]; self.detail.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.detail.textColor=LiraColor(0xAFAFAF); self.detail.numberOfLines=0;
        self.symbol=[[UIImageView alloc] init]; self.symbol.tintColor=LiraMint(); self.symbol.contentMode=UIViewContentModeScaleAspectFit;
        UIStackView *text=[[UIStackView alloc] initWithArrangedSubviews:@[self.heading,self.detail]]; text.axis=UILayoutConstraintAxisVertical; text.spacing=4;
        UIImageView *arrow=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]]; arrow.tintColor=LiraColor(0x999999); arrow.contentMode=UIViewContentModeScaleAspectFit;
        self.panel.translatesAutoresizingMaskIntoConstraints=NO; [self.contentView addSubview:self.panel];
        for (UIView *v in @[self.symbol,text,arrow]) { v.translatesAutoresizingMaskIntoConstraints=NO; [self.panel addSubview:v]; }
        [NSLayoutConstraint activateConstraints:@[
            [self.panel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [self.panel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [self.panel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
            [self.panel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
            [self.symbol.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:16],
            [self.symbol.centerYAnchor constraintEqualToAnchor:self.panel.centerYAnchor],
            [self.symbol.widthAnchor constraintEqualToConstant:26],[self.symbol.heightAnchor constraintEqualToConstant:26],
            [text.leadingAnchor constraintEqualToAnchor:self.symbol.trailingAnchor constant:14],
            [text.topAnchor constraintEqualToAnchor:self.panel.topAnchor constant:17],
            [text.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor constant:-17],
            [text.trailingAnchor constraintEqualToAnchor:arrow.leadingAnchor constant:-12],
            [arrow.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-17],
            [arrow.centerYAnchor constraintEqualToAnchor:self.panel.centerYAnchor],
            [arrow.widthAnchor constraintEqualToConstant:10]
        ]];
        self.heading.adjustsFontForContentSizeCategory=YES; self.detail.adjustsFontForContentSizeCategory=YES;
    } return self;
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [UIView animateWithDuration:LiraMotionAllowed()?0.16:0 animations:^{ self.panel.alpha=highlighted?0.65:1; }];
}
@end

@interface LiraSettingsViewController () <UISearchBarDelegate>
@property(nonatomic, strong) UISearchBar *search;
@property(nonatomic, strong) UIImageView *brand;
@property(nonatomic, strong) UILabel *profileHeading;
@property(nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *sections;
@property(nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *visibleSections;
@end

@implementation LiraSettingsViewController
- (instancetype)init { return [super initWithStyle:UITableViewStylePlain]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"lira.world.profile", nil);
    self.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    self.view.backgroundColor = LiraBackground();
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 76;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:LiraSettingCell.class forCellReuseIdentifier:@"setting"];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.search=[UISearchBar new]; self.search.delegate=self; self.search.placeholder=localize(@"lira.settings.search",nil); LiraStyleSearchBar(self.search);
    [self buildProfileHeader];
    self.sections = @[
        @[@{@"key": @"lira.cover.choose", @"detail": @"lira.cover.detail", @"icon": @"photo", @"action": @"cover"},
          @{@"key": @"preference.lang.title", @"detail": @"lira.settings.language_detail", @"icon": @"globe", @"class": @"LauncherLanguageViewController"}],
        @[@{@"key": @"lira.settings.accounts", @"detail": @"lira.settings.accounts_detail", @"icon": @"person.crop.circle", @"class": @"AccountListViewController"},
          @{@"key": @"lira.settings.java", @"detail": @"lira.settings.java_detail", @"icon": @"cpu", @"class": @"LauncherPrefManageJREViewController"},
          @{@"key": @"lira.settings.controls", @"detail": @"lira.settings.controls_detail", @"icon": @"gamecontroller", @"class": @"LauncherPrefContCfgViewController"},
          @{@"key": @"lira.settings.folders", @"detail": @"lira.settings.folders_detail", @"icon": @"folder", @"class": @"LauncherPrefGameDirViewController"}],
        @[@{@"key": @"lira.home.downloads", @"detail": @"lira.settings.downloads_detail", @"icon": @"arrow.down.circle", @"class": @"DownloadTasksViewController"},
          @{@"key": @"lira.home.history", @"detail": @"lira.settings.history_detail", @"icon": @"clock.arrow.circlepath", @"class": @"DownloadHistoryViewController"},
          @{@"key": @"lira.settings.advanced", @"detail": @"lira.settings.advanced_detail", @"icon": @"slider.horizontal.3", @"class": @"LauncherPreferencesViewController"}]
    ];
    self.visibleSections = self.sections;
    LiraApplyNavigationAppearance(self.navigationController.navigationBar);
}
- (void)buildProfileHeader {
    UIView *hero=[[UIView alloc] initWithFrame:CGRectMake(0,0,400,232)];
    UIImageView *logo=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LiraBrand/wordmark.png"]];
    self.brand=logo; logo.frame=CGRectMake(24,24,260,31); logo.contentMode=UIViewContentModeScaleAspectFit; [hero addSubview:logo];
    UILabel *caption=[[UILabel alloc] initWithFrame:CGRectMake(24,76,350,60)];
    self.profileHeading=caption; caption.autoresizingMask=UIViewAutoresizingFlexibleWidth; caption.text=localize(@"lira.world.profile",nil);
    caption.textColor=UIColor.whiteColor; caption.font=LiraFont(UIFontTextStyleLargeTitle,40,UIFontWeightUltraLight); [hero addSubview:caption];
    self.search.frame=CGRectMake(12,156,376,56); self.search.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    [hero addSubview:self.search]; self.tableView.tableHeaderView=hero;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    LiraApplyNavigationAppearance(self.navigationController.navigationBar);
    [self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)text {
    NSString *query = [bar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSMutableArray *sections = NSMutableArray.array;
    for (NSArray *section in self.sections) {
        NSMutableArray *rows = NSMutableArray.array;
        for (NSDictionary *item in section) {
            NSString *haystack = [NSString stringWithFormat:@"%@ %@", localize(item[@"key"], nil), localize(item[@"detail"], nil)];
            if (!query.length || [haystack rangeOfString:query options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) [rows addObject:item];
        }
        [sections addObject:rows];
    }
    self.visibleSections = sections;
    [self.tableView reloadData];
    if (![sections[0] count] && ![sections[1] count] && ![sections[2] count]) {
        UILabel *empty = [[UILabel alloc] init];
        empty.text = localize(@"lira.home.empty", nil);
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = UIColor.secondaryLabelColor;
        self.tableView.backgroundView = empty;
    } else self.tableView.backgroundView = nil;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.visibleSections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [self.visibleSections[section] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self.visibleSections[section] count]) return nil;
    return localize(@[@"lira.settings.appearance", @"lira.settings.game", @"lira.settings.tools"][section], nil);
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 2 ? localize(@"lira.settings.footer", nil) : nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    LiraSettingCell *cell=[tableView dequeueReusableCellWithIdentifier:@"setting" forIndexPath:path];
    NSDictionary *item=self.visibleSections[path.section][path.row];
    cell.heading.text=localize(item[@"key"],nil);
    cell.detail.text=localize(item[@"detail"],nil);
    cell.symbol.image=[UIImage systemImageNamed:item[@"icon"]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    NSDictionary *item = self.visibleSections[path.section][path.row];
    if ([item[@"action"] isEqualToString:@"cover"]) { LiraChooseProfileCover(self,PLProfiles.current.selectedProfileName); return; }
    Class cls = NSClassFromString(item[@"class"]);
    if (cls && [cls isSubclassOfClass:UIViewController.class]) {
        UIViewController *vc = [[cls alloc] init];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header=self.tableView.tableHeaderView;
    CGFloat width=self.tableView.bounds.size.width;
    BOOL compact=width>600 && self.tableView.bounds.size.height<500;
    CGFloat height=compact?124:232;
    if (fabs(header.bounds.size.width-width)>0.5 || fabs(header.bounds.size.height-height)>0.5) {
        header.frame=CGRectMake(0,0,width,height); self.tableView.tableHeaderView=header;
    }
    self.brand.frame=compact?CGRectMake(24,16,220,26):CGRectMake(24,24,MIN(260,width-48),31);
    self.profileHeading.frame=compact?CGRectMake(270,5,MAX(0,width-294),48):CGRectMake(24,76,MAX(0,width-48),60);
    self.profileHeading.font=LiraFont(UIFontTextStyleLargeTitle,compact?30:40,UIFontWeightUltraLight);
    self.search.frame=CGRectMake(12,compact?60:156,MAX(0,width-24),56);
}
- (void)viewWillDisappear:(BOOL)animated { [super viewWillDisappear:animated]; [self.navigationController setNavigationBarHidden:NO animated:animated]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar { [bar resignFirstResponder]; }
@end
