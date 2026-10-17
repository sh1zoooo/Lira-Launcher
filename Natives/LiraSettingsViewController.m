#import "LiraSettingsViewController.h"
#import "LiraTheme.h"
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

@interface LiraSettingsViewController () <UISearchResultsUpdating>
@property(nonatomic, strong) UISearchController *search;
@property(nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *sections;
@property(nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *visibleSections;
@end

@implementation LiraSettingsViewController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"tab.settings", nil);
    self.view.backgroundColor = LiraBackground();
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 76;
    self.tableView.separatorColor = LiraSecondarySurface();
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.search = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.search.searchResultsUpdater = self;
    self.search.obscuresBackgroundDuringPresentation = NO;
    self.search.searchBar.placeholder = localize(@"lira.settings.search", nil);
    self.navigationItem.searchController = self.search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
    self.sections = @[
        @[@{@"key": @"lira.settings.theme", @"detail": @"lira.settings.theme_detail", @"icon": @"circle.lefthalf.filled", @"action": @"theme"},
          @{@"key": @"preference.lang.title", @"detail": @"lira.settings.language_detail", @"icon": @"globe", @"class": @"LauncherLanguageViewController"},
          @{@"key": @"lira.settings.background", @"detail": @"lira.settings.background_detail", @"icon": @"photo", @"class": @"BackgroundSettingsViewController"}],
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
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    LiraApplyNavigationAppearance(self.navigationController.navigationBar);
    [self.tableView reloadData];
}
- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
    NSString *query = [controller.searchBar.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"setting"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"setting"];
    NSDictionary *item = self.visibleSections[path.section][path.row];
    cell.backgroundColor = LiraSurface();
    cell.textLabel.text = localize(item[@"key"], nil);
    cell.textLabel.font = LiraFont(UIFontTextStyleBody, 17, UIFontWeightSemibold);
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = localize(item[@"detail"], nil);
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.detailTextLabel.numberOfLines = 0;
    cell.imageView.image = [UIImage systemImageNamed:item[@"icon"]];
    cell.imageView.tintColor = accentColor();
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    NSDictionary *item = self.visibleSections[path.section][path.row];
    if ([item[@"action"] isEqualToString:@"theme"]) { [self chooseTheme:path]; return; }
    Class cls = NSClassFromString(item[@"class"]);
    if (cls && [cls isSubclassOfClass:UIViewController.class]) {
        UIViewController *vc = [[cls alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)chooseTheme:(NSIndexPath *)path {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:localize(@"lira.settings.theme", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *values = @[@"auto", @"light", @"dark"];
    NSArray *keys = @[@"lira.settings.system", @"lira.settings.light", @"lira.settings.dark"];
    for (NSUInteger i = 0; i < values.count; i++) {
        NSString *value = values[i];
        [sheet addAction:[UIAlertAction actionWithTitle:localize(keys[i], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            setPrefObject(@"general.ui_theme", value);
            [NSNotificationCenter.defaultCenter postNotificationName:@"UIThemeChanged" object:nil];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path];
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}
@end
