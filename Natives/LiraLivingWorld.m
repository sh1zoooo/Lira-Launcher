#import "LiraLivingWorld.h"
#import "LiraTheme.h"
#import "utils.h"
#import <QuartzCore/QuartzCore.h>

NSNotificationName const LiraWorldSceneChangedNotification = @"LiraWorldSceneChanged";
UIColor *LiraMint(void) { return LiraColor(0x6AF0B7); }
BOOL LiraMotionAllowed(void) { return !UIAccessibilityIsReduceMotionEnabled(); }
NSString *LiraSceneForProfile(NSString *name) {
    // Decorative scenes are stable across launches; they do not claim to preview a saved world.
    if (!name.length || [name isEqualToString:@"(Default)"]) return @"forest";
    const unsigned char *bytes = (const unsigned char *)name.UTF8String;
    uint32_t hash = 2166136261u;
    while (bytes && *bytes) { hash ^= *bytes++; hash *= 16777619u; }
    return (hash & 1u) ? @"forest" : @"nether";
}
UIImage *LiraWorldImage(NSString *scene) {
    return [UIImage imageNamed:[NSString stringWithFormat:@"LiraWorlds/%@.png", [scene isEqualToString:@"nether"] ? @"nether" : @"forest"]];
}

@interface LiraWorldBackdrop ()
@property(nonatomic, strong) UIView *landscape;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UIImageView *outgoing;
@property(nonatomic, strong) CAGradientLayer *shade;
@property(nonatomic, copy) NSString *scene;
@end
@implementation LiraWorldBackdrop
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;
        self.backgroundColor = LiraColor(0x04160F);
        self.landscape = [[UIView alloc] init];
        [self addSubview:self.landscape];
        self.imageView = [[UIImageView alloc] init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.landscape addSubview:self.imageView];
        self.outgoing = [[UIImageView alloc] init];
        self.outgoing.contentMode = UIViewContentModeScaleAspectFill;
        self.outgoing.clipsToBounds = YES;
        self.outgoing.alpha = 0;
        [self.landscape addSubview:self.outgoing];
        self.shade = [CAGradientLayer layer];
        self.shade.colors = @[(id)[UIColor colorWithWhite:0 alpha:0.28].CGColor,
            (id)[UIColor colorWithWhite:0 alpha:0.03].CGColor,
            (id)[LiraColor(0x00160D) colorWithAlphaComponent:0.7].CGColor,
            (id)[LiraColor(0x001209) colorWithAlphaComponent:0.97].CGColor];
        self.shade.locations = @[@0, @0.36, @0.7, @1];
        [self.layer addSublayer:self.shade];
        [self showScene:@"forest" animated:NO];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateMotion) name:UIAccessibilityReduceMotionStatusDidChangeNotification object:nil];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.landscape.bounds = CGRectInset(self.bounds, -28, -28);
    self.landscape.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.imageView.frame = self.landscape.bounds;
    self.outgoing.frame = self.landscape.bounds;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    self.shade.frame = self.bounds;
    [CATransaction commit];
}
- (void)showScene:(NSString *)scene animated:(BOOL)animated {
    if ([self.scene isEqualToString:scene]) return;
    self.scene = scene;
    [self.outgoing.layer removeAllAnimations];
    self.outgoing.image = self.imageView.image;
    self.imageView.image = LiraWorldImage(scene);
    if (animated && self.window && LiraMotionAllowed() && self.outgoing.image) {
        self.outgoing.alpha = 1;
        [UIView animateWithDuration:0.65 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{ self.outgoing.alpha = 0; } completion:nil];
    } else self.outgoing.alpha = 0;
}
- (void)setMotionActive:(BOOL)motionActive { _motionActive = motionActive; [self updateMotion]; }
- (void)didMoveToWindow { [super didMoveToWindow]; [self updateMotion]; }
- (void)updateMotion {
    [self.landscape.layer removeAnimationForKey:@"lira.breathe"];
    for (UIMotionEffect *effect in self.landscape.motionEffects.copy) [self.landscape removeMotionEffect:effect];
    if (!self.motionActive || !self.window || !LiraMotionAllowed()) return;
    UIInterpolatingMotionEffect *x = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    x.minimumRelativeValue = @(-12); x.maximumRelativeValue = @12;
    UIInterpolatingMotionEffect *y = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    y.minimumRelativeValue = @(-9); y.maximumRelativeValue = @9;
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init]; group.motionEffects = @[x,y];
    [self.landscape addMotionEffect:group];
    CABasicAnimation *breath = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    breath.fromValue = @1; breath.toValue = @1.025; breath.duration = 14;
    breath.autoreverses = YES; breath.repeatCount = HUGE_VALF;
    breath.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.landscape.layer addAnimation:breath forKey:@"lira.breathe"];
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end

@interface LiraPlayButton ()
@property(nonatomic, strong) CAGradientLayer *fill;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIImageView *arrow;
@property(nonatomic, strong) UIView *arrowDisc;
@property(nonatomic, strong) CAShapeLayer *ring;
@property(nonatomic, strong) CAShapeLayer *contour;
@end
@implementation LiraPlayButton
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.layer.shadowColor = LiraMint().CGColor;
        self.layer.shadowOpacity = 0.35; self.layer.shadowRadius = 20;
        self.layer.shadowOffset = CGSizeMake(0,4);
        self.fill = [CAGradientLayer layer];
        self.fill.colors = @[(id)LiraColor(0xB7FFDB).CGColor, (id)LiraColor(0x40DE9C).CGColor];
        self.fill.startPoint = CGPointMake(0,0); self.fill.endPoint = CGPointMake(1,1);
        self.fill.cornerCurve = kCACornerCurveContinuous;
        [self.layer addSublayer:self.fill];
        self.contour = [CAShapeLayer layer]; self.contour.fillColor = UIColor.clearColor.CGColor;
        self.contour.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:0.45].CGColor;
        self.contour.lineWidth = 1; [self.layer addSublayer:self.contour];
        self.titleLabel = [[UILabel alloc] init]; self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = LiraFont(UIFontTextStyleTitle2, 23, UIFontWeightHeavy);
        self.titleLabel.textColor = LiraColor(0x003E29);
        self.titleLabel.adjustsFontForContentSizeCategory = YES;
        self.titleLabel.adjustsFontSizeToFitWidth = YES; self.titleLabel.minimumScaleFactor = 0.65;
        self.titleLabel.userInteractionEnabled = NO;
        [self addSubview:self.titleLabel];
        self.arrowDisc = [[UIView alloc] init]; self.arrowDisc.backgroundColor = [LiraColor(0x007344) colorWithAlphaComponent:0.7];
        self.arrowDisc.userInteractionEnabled = NO; [self addSubview:self.arrowDisc];
        self.arrow = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold]]];
        self.arrow.tintColor = LiraColor(0xC7FFE7); self.arrow.contentMode = UIViewContentModeCenter;
        [self.arrowDisc addSubview:self.arrow];
        self.ring = [CAShapeLayer layer]; self.ring.fillColor = UIColor.clearColor.CGColor;
        self.ring.strokeColor = LiraColor(0xCEFFEB).CGColor; self.ring.lineWidth = 2;
        self.ring.lineCap = kCALineCapRound; self.ring.strokeEnd = 0;
        [self.arrowDisc.layer addSublayer:self.ring];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(motionChanged) name:UIAccessibilityReduceMotionStatusDidChangeNotification object:nil];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat h = self.bounds.size.height, w = self.bounds.size.width, side = MIN(h-16,48);
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    self.fill.frame = self.bounds; self.fill.cornerRadius = h/2;
    self.contour.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds,0.5,0.5) cornerRadius:h/2].CGPath;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:h/2].CGPath;
    self.arrowDisc.frame = CGRectMake(w-side-9,(h-side)/2,side,side); self.arrowDisc.layer.cornerRadius = side/2;
    self.arrow.frame = self.arrowDisc.bounds;
    self.ring.frame = self.arrowDisc.bounds;
    self.ring.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.arrowDisc.bounds,3,3)].CGPath;
    self.titleLabel.frame = CGRectMake(16,4,MAX(0,w-side-40),h-8);
    [CATransaction commit];
}
- (void)setTitle:(NSString *)title { _title = [title copy]; self.titleLabel.text = title; self.accessibilityLabel = title; }
- (void)setEnabled:(BOOL)enabled { [super setEnabled:enabled]; self.alpha = enabled ? 1 : 0.55; self.accessibilityTraits = UIAccessibilityTraitButton | (enabled ? 0 : UIAccessibilityTraitNotEnabled); }
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:LiraMotionAllowed() ? 0.13 : 0 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.97,0.97) : CGAffineTransformIdentity;
        self.layer.shadowOpacity = highlighted ? 0.12 : 0.35;
    }];
}
- (void)setLaunching:(BOOL)launching { _launching = launching; [self motionChanged]; }
- (void)motionChanged {
    [self.arrowDisc.layer removeAnimationForKey:@"lira.portal"];
    self.arrow.image = [UIImage systemImageNamed:self.launching ? @"sparkles" : @"chevron.right"];
    self.ring.strokeEnd = self.launching ? MAX(0.18, self.progress) : 0;
    if (self.launching && self.window && LiraMotionAllowed()) {
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @0; spin.toValue = @(M_PI*2); spin.duration = 1.6; spin.repeatCount = HUGE_VALF;
        [self.arrowDisc.layer addAnimation:spin forKey:@"lira.portal"];
    }
}
- (void)setProgress:(double)progress {
    _progress = fmax(0,fmin(1,progress));
    self.ring.strokeEnd = self.launching ? MAX(0.18,_progress) : 0;
    self.accessibilityValue = self.launching ? [NSString stringWithFormat:@"%.0f%%", _progress*100] : nil;
}
- (void)didMoveToWindow { [super didMoveToWindow]; [self motionChanged]; }
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end

@interface LiraDockButton : UIButton
@end
@implementation LiraDockButton
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width=self.bounds.size.width, height=self.bounds.size.height;
    BOOL narrow=self.superview.bounds.size.width<524;
    if (narrow) {
        self.imageView.frame=CGRectMake((width-23)/2,8,23,23);
        self.titleLabel.frame=CGRectMake(3,35,width-6,19);
        self.titleLabel.textAlignment=NSTextAlignmentCenter;
    } else {
        CGFloat text=MIN(width-48,[self.currentTitle sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}].width);
        CGFloat start=(width-text-33)/2;
        self.imageView.frame=CGRectMake(start,(height-23)/2,23,23);
        self.titleLabel.frame=CGRectMake(start+33,0,text,height);
        self.titleLabel.textAlignment=NSTextAlignmentLeft;
    }
    self.imageView.contentMode=UIViewContentModeScaleAspectFit;
}
@end

@interface LiraWorldDock ()
@property(nonatomic, strong) UIVisualEffectView *material;
@property(nonatomic, strong) UIView *selection;
@property(nonatomic, strong) NSArray<UIButton *> *buttons;
@property(nonatomic, strong) UIStackView *row;
@end
@implementation LiraWorldDock
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.layer.cornerCurve = kCACornerCurveContinuous; self.layer.borderWidth = 1;
        self.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.2].CGColor;
        self.clipsToBounds = YES;
        self.material = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        self.material.userInteractionEnabled = NO; [self addSubview:self.material];
        self.backgroundColor = [LiraColor(0x031B12) colorWithAlphaComponent:0.88];
        self.selection = [[UIView alloc] init]; self.selection.userInteractionEnabled = NO;
        self.selection.backgroundColor = [LiraMint() colorWithAlphaComponent:0.19];
        self.selection.layer.borderWidth = 0.8;
        self.selection.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.35].CGColor;
        [self addSubview:self.selection];
        self.row = [[UIStackView alloc] init]; self.row.distribution = UIStackViewDistributionFillEqually;
        [self addSubview:self.row];
        NSArray *keys = @[@"lira.world.play", @"lira.world.library", @"lira.explore.title", @"lira.world.profile"];
        NSArray *icons = @[@"gamecontroller", @"books.vertical", @"safari", @"person.crop.circle"];
        NSMutableArray *buttons = NSMutableArray.array;
        for (NSUInteger i=0;i<keys.count;i++) {
            UIButton *button = [LiraDockButton buttonWithType:UIButtonTypeSystem]; button.tag = i;
            [button setImage:[UIImage systemImageNamed:icons[i] withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
            [button setTitle:localize(keys[i],nil) forState:UIControlStateNormal];
            button.accessibilityLabel = localize(keys[i],nil);
            button.accessibilityIdentifier = [NSString stringWithFormat:@"lira.destination.%lu",(unsigned long)i];
            button.titleLabel.font = LiraFont(UIFontTextStyleCaption1,12,UIFontWeightSemibold);
            button.titleLabel.adjustsFontSizeToFitWidth = YES; button.titleLabel.minimumScaleFactor = 0.8;
            [button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.row addArrangedSubview:button]; [buttons addObject:button];
        }
        self.buttons = buttons;
        [self setSelectedDestination:0 animated:NO];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = MIN(38,self.bounds.size.height/2);
    self.material.frame = self.bounds;
    self.row.frame = CGRectInset(self.bounds,8,7);
    for (UIButton *button in self.buttons) [button setNeedsLayout];
    self.selection.frame = [self selectionFrame];
    self.selection.layer.cornerRadius = self.selection.bounds.size.height/2;
}
- (CGRect)selectionFrame {
    CGFloat width = MAX(0,self.bounds.size.width-16)/4;
    return CGRectMake(8+self.selectedDestination*width,7,width,self.bounds.size.height-14);
}
- (void)setSelectedDestination:(NSInteger)destination { [self setSelectedDestination:destination animated:NO]; }
- (void)setSelectedDestination:(NSInteger)destination animated:(BOOL)animated {
    _selectedDestination = MIN(3,MAX(0,destination));
    for (UIButton *b in self.buttons) {
        BOOL selected = b.tag == _selectedDestination;
        b.tintColor = selected ? LiraMint() : LiraColor(0xAAC5B7);
        [b setTitleColor:b.tintColor forState:UIControlStateNormal];
        b.accessibilityTraits = UIAccessibilityTraitButton | (selected ? UIAccessibilityTraitSelected : 0);
    }
    if (animated && LiraMotionAllowed()) {
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self.selection.frame = [self selectionFrame]; } completion:nil];
    } else self.selection.frame = [self selectionFrame];
}
- (void)tapped:(UIButton *)button { if (self.didSelectDestination) self.didSelectDestination(button.tag); }
@end
