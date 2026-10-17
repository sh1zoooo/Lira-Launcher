#import "LiraLibraryViewController.h"
#import "LiraLivingWorld.h"
#import "LiraTheme.h"
#import "PLProfiles.h"
#import "ProfileSettingsViewController.h"
#import "VersionManagerViewController.h"
#import "utils.h"

@interface LiraLibraryCell : UICollectionViewCell
@property(nonatomic, strong) UIImageView *cover;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *versionLabel;
@end
@implementation LiraLibraryCell
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.contentView.backgroundColor=LiraColor(0x0B281D);
        self.contentView.layer.cornerRadius=24; self.contentView.clipsToBounds=YES;
        self.cover=[[UIImageView alloc] init]; self.cover.contentMode=UIViewContentModeScaleAspectFill; self.cover.clipsToBounds=YES;
        self.nameLabel=[[UILabel alloc] init]; self.nameLabel.font=LiraFont(UIFontTextStyleHeadline,18,UIFontWeightBold);
        self.nameLabel.textColor=UIColor.whiteColor; self.nameLabel.numberOfLines=2;
        self.versionLabel=[[UILabel alloc] init]; self.versionLabel.font=LiraFont(UIFontTextStyleCaption1,12,UIFontWeightMedium);
        self.versionLabel.textColor=LiraMint(); self.versionLabel.numberOfLines=2;
        for (UIView *v in @[self.cover,self.nameLabel,self.versionLabel]) { v.translatesAutoresizingMaskIntoConstraints=NO; [self.contentView addSubview:v]; }
        [NSLayoutConstraint activateConstraints:@[
            [self.cover.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [self.cover.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [self.cover.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [self.cover.heightAnchor constraintEqualToAnchor:self.contentView.heightAnchor multiplier:0.57],
            [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],
            [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14],
            [self.nameLabel.topAnchor constraintEqualToAnchor:self.cover.bottomAnchor constant:12],
            [self.versionLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
            [self.versionLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],
            [self.versionLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:5],
            [self.versionLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12]
        ]];
        self.isAccessibilityElement=YES;
    } return self;
}
@end

@interface LiraLibraryViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>
@property(nonatomic, strong) UICollectionView *grid;
@property(nonatomic, strong) UISearchBar *search;
@property(nonatomic, strong) UISegmentedControl *filter;
@property(nonatomic, strong) UILabel *empty;
@property(nonatomic, strong) NSArray<NSString *> *names;
@end
@implementation LiraLibraryViewController
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=localize(@"lira.world.library",nil);
    self.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    self.view.backgroundColor=LiraColor(0x04170F);
    self.navigationItem.rightBarButtonItems=@[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(install)],
        [[UIBarButtonItem alloc] initWithTitle:localize(@"lira.library.manage",nil) style:UIBarButtonItemStylePlain target:self action:@selector(manage)]];
    self.search=[[UISearchBar alloc] init]; self.search.delegate=self; self.search.searchBarStyle=UISearchBarStyleMinimal;
    self.search.placeholder=localize(@"lira.home.search",nil);
    self.filter=[[UISegmentedControl alloc] initWithItems:@[localize(@"lira.home.all",nil),localize(@"lira.home.favorites",nil)]];
    self.filter.selectedSegmentIndex=0; self.filter.selectedSegmentTintColor=LiraColor(0x24553D);
    [self.filter addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init]; layout.minimumInteritemSpacing=16; layout.minimumLineSpacing=20;
    self.grid=[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.grid.backgroundColor=UIColor.clearColor; self.grid.dataSource=self; self.grid.delegate=self;
    self.grid.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag; self.grid.alwaysBounceVertical=YES;
    self.grid.contentInset=UIEdgeInsetsMake(18,20,20,20);
    [self.grid registerClass:LiraLibraryCell.class forCellWithReuseIdentifier:@"world"];
    self.empty=[[UILabel alloc] init]; self.empty.text=localize(@"lira.home.empty",nil); self.empty.textAlignment=NSTextAlignmentCenter;
    self.empty.textColor=LiraColor(0xABC4B5); self.empty.numberOfLines=0;
    for (UIView *v in @[self.search,self.filter,self.grid]) { v.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:v]; }
    [NSLayoutConstraint activateConstraints:@[
        [self.search.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.search.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:12],
        [self.search.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-12],
        [self.filter.topAnchor constraintEqualToAnchor:self.search.bottomAnchor constant:8],
        [self.filter.leadingAnchor constraintEqualToAnchor:self.search.leadingAnchor constant:8],
        [self.filter.trailingAnchor constraintEqualToAnchor:self.search.trailingAnchor constant:-8],
        [self.grid.topAnchor constraintEqualToAnchor:self.filter.bottomAnchor constant:4],
        [self.grid.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.grid.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [self.grid.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; [self.navigationController setNavigationBarHidden:NO animated:animated];
    LiraApplyNavigationAppearance(self.navigationController.navigationBar); [self refresh];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; [self.grid.collectionViewLayout invalidateLayout]; }
- (NSString *)scope { return [PLProfiles.current.profilePath stringByResolvingSymlinksInPath]?:NSHomeDirectory(); }
- (NSArray *)favorites {
    id names=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"lira.favoriteProfiles"][[self scope]];
    return [names isKindOfClass:NSArray.class]?names:@[];
}
- (void)refresh {
    NSString *query=[self.search.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]?:@"";
    NSArray *favorites=[self favorites]; NSMutableArray *names=NSMutableArray.array;
    for (NSString *name in [PLProfiles.current.profiles.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
        NSString *version=PLProfiles.current.profiles[name][@"lastVersionId"]?:@"";
        if (self.filter.selectedSegmentIndex==1 && ![favorites containsObject:name]) continue;
        if (query.length && [name rangeOfString:query options:NSCaseInsensitiveSearch].location==NSNotFound && [version rangeOfString:query options:NSCaseInsensitiveSearch].location==NSNotFound) continue;
        [names addObject:name];
    }
    self.names=names; self.grid.backgroundView=names.count?nil:self.empty; [self.grid reloadData];
}
- (NSInteger)collectionView:(UICollectionView *)collection numberOfItemsInSection:(NSInteger)section { return self.names.count; }
- (UICollectionViewCell *)collectionView:(UICollectionView *)collection cellForItemAtIndexPath:(NSIndexPath *)path {
    LiraLibraryCell *cell=[collection dequeueReusableCellWithReuseIdentifier:@"world" forIndexPath:path];
    NSString *name=self.names[path.item]; BOOL selected=[name isEqualToString:PLProfiles.current.selectedProfileName];
    NSString *display=[name isEqualToString:@"(Default)"]?localize(@"lira.home.default_profile",nil):name;
    cell.cover.image=LiraWorldImage(LiraSceneForProfile(name));
    cell.nameLabel.text=[NSString stringWithFormat:@"%@%@",[[self favorites] containsObject:name]?@"★ ":@"",display];
    cell.versionLabel.text=PLProfiles.current.profiles[name][@"lastVersionId"]?:@"";
    cell.contentView.layer.borderWidth=selected?2:0;
    cell.contentView.layer.borderColor=LiraMint().CGColor;
    cell.accessibilityLabel=[NSString stringWithFormat:@"%@, %@",display,cell.versionLabel.text];
    cell.accessibilityTraits=UIAccessibilityTraitButton|(selected?UIAccessibilityTraitSelected:0);
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collection layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)path {
    CGFloat available=collection.bounds.size.width-40; NSInteger columns=MAX(1,MIN(4,(NSInteger)((available+16)/190)));
    CGFloat width=floor((available-16*(columns-1))/columns);
    return CGSizeMake(width,UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory)?width+160:width+92);
}
- (void)collectionView:(UICollectionView *)collection didSelectItemAtIndexPath:(NSIndexPath *)path {
    [PLProfiles.current setSelectedProfileName:self.names[path.item]];
    [self.search resignFirstResponder]; self.tabBarController.selectedIndex=0;
}
- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collection contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)path point:(CGPoint)point {
    NSString *name=self.names[path.item]; __weak typeof(self) weakSelf=self;
    return [UIContextMenuConfiguration configurationWithIdentifier:name previewProvider:nil actionProvider:^UIMenu *(NSArray *suggested){
        UIAction *favorite=[UIAction actionWithTitle:localize([[weakSelf favorites] containsObject:name]?@"lira.library.unfavorite":@"lira.library.favorite",nil) image:[UIImage systemImageNamed:@"star"] identifier:nil handler:^(UIAction *action){
            typeof(self) self=weakSelf; if (!self) return;
            NSMutableArray *names=[[self favorites] mutableCopy];
            if ([names containsObject:name]) [names removeObject:name]; else [names addObject:name];
            NSMutableDictionary *all=[[NSUserDefaults.standardUserDefaults dictionaryForKey:@"lira.favoriteProfiles"] mutableCopy]?:NSMutableDictionary.dictionary;
            all[[self scope]]=names; [NSUserDefaults.standardUserDefaults setObject:all forKey:@"lira.favoriteProfiles"]; [self refresh];
        }];
        UIAction *settings=[UIAction actionWithTitle:localize(@"lira.library.configure",nil) image:[UIImage systemImageNamed:@"slider.horizontal.3"] identifier:nil handler:^(UIAction *action){
            ProfileSettingsViewController *page=[[ProfileSettingsViewController alloc] init]; page.profileName=name;
            [weakSelf.navigationController pushViewController:page animated:YES];
        }];
        return [UIMenu menuWithTitle:@"" children:@[favorite,settings]];
    }];
}
- (void)install { self.tabBarController.selectedIndex=1; }
- (void)manage { [self.navigationController pushViewController:[[VersionManagerViewController alloc] init] animated:YES]; }
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text { [self refresh]; }
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; }
@end
