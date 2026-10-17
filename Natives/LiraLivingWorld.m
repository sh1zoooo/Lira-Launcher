#import "LiraLivingWorld.h"
#import "LiraTheme.h"
#import "utils.h"
#import <QuartzCore/QuartzCore.h>

NSNotificationName const LiraWorldSceneChangedNotification = @"LiraWorldSceneChanged";
UIColor *LiraMint(void) { return LiraColor(0xECEBEC); }
BOOL LiraMotionAllowed(void) { return !UIAccessibilityIsReduceMotionEnabled(); }
NSString *LiraSceneForProfile(NSString *name) { return @"graphite"; }
UIImage *LiraWorldImage(NSString *scene) { return [UIImage imageNamed:@"LiraBrand/wordmark.png"]; }

@interface LiraWorldBackdrop ()
@property(nonatomic, strong) CAGradientLayer *gradient;
@end
@implementation LiraWorldBackdrop
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.userInteractionEnabled=NO; self.backgroundColor=LiraColor(0x101010);
        self.gradient=[CAGradientLayer layer];
        self.gradient.colors=@[(id)LiraColor(0x323232).CGColor,(id)LiraColor(0x171717).CGColor,(id)LiraColor(0x0B0B0B).CGColor];
        self.gradient.startPoint=CGPointMake(0,0); self.gradient.endPoint=CGPointMake(0.9,0.8);
        [self.layer addSublayer:self.gradient];
    } return self;
}
- (void)layoutSubviews { [super layoutSubviews]; [CATransaction begin]; [CATransaction setDisableActions:YES]; self.gradient.frame=self.bounds; [CATransaction commit]; }
- (void)setMotionActive:(BOOL)active { _motionActive=active; }
- (void)showScene:(NSString *)scene animated:(BOOL)animated {} // Graphite intentionally has no scenic wallpaper.
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
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.08; self.layer.shadowRadius = 18;
        self.layer.shadowOffset = CGSizeMake(0,4);
        self.fill = [CAGradientLayer layer];
        self.fill.colors = @[(id)LiraColor(0x171719).CGColor, (id)LiraColor(0x3F4043).CGColor];
        self.fill.startPoint = CGPointMake(0,0); self.fill.endPoint = CGPointMake(1,1);
        self.fill.cornerCurve = kCACornerCurveContinuous;
        [self.layer addSublayer:self.fill];
        self.contour = [CAShapeLayer layer]; self.contour.fillColor = UIColor.clearColor.CGColor;
        self.contour.strokeColor = [UIColor.whiteColor colorWithAlphaComponent:0.13].CGColor;
        self.contour.lineWidth = 0.5; [self.layer addSublayer:self.contour];
        self.titleLabel = [[UILabel alloc] init]; self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = LiraFont(UIFontTextStyleTitle2, 23, UIFontWeightSemibold);
        self.titleLabel.textColor = LiraColor(0xEEEEEE);
        self.titleLabel.adjustsFontForContentSizeCategory = YES;
        self.titleLabel.adjustsFontSizeToFitWidth = YES; self.titleLabel.minimumScaleFactor = 0.65;
        self.titleLabel.userInteractionEnabled = NO;
        [self addSubview:self.titleLabel];
        self.arrowDisc = [[UIView alloc] init]; self.arrowDisc.backgroundColor = [LiraColor(0xFFFFFF) colorWithAlphaComponent:0.05];
        self.arrowDisc.userInteractionEnabled = NO; [self addSubview:self.arrowDisc];
        self.arrow = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold]]];
        self.arrow.tintColor = LiraColor(0xE6E6E6); self.arrow.contentMode = UIViewContentModeCenter;
        [self.arrowDisc addSubview:self.arrow];
        self.ring = [CAShapeLayer layer]; self.ring.fillColor = UIColor.clearColor.CGColor;
        self.ring.strokeColor = LiraColor(0xFFFFFF).CGColor; self.ring.lineWidth = 2;
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
    self.titleLabel.frame = CGRectMake(20,4,MAX(0,w-40),h-8);
    self.arrowDisc.hidden=!self.launching;
    [CATransaction commit];
}
- (void)setTitle:(NSString *)title { _title = [title copy]; self.titleLabel.text = title; self.accessibilityLabel = title; }
- (void)setEnabled:(BOOL)enabled { [super setEnabled:enabled]; self.alpha = enabled ? 1 : 0.55; self.accessibilityTraits = UIAccessibilityTraitButton | (enabled ? 0 : UIAccessibilityTraitNotEnabled); }
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:LiraMotionAllowed() ? 0.13 : 0 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.97,0.97) : CGAffineTransformIdentity;
        self.layer.shadowOpacity = highlighted ? 0.04 : 0.08;
    }];
}
- (void)setLaunching:(BOOL)launching { _launching = launching; [self motionChanged]; [self setNeedsLayout]; }
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

static UIImage *LiraDockIcon(NSUInteger index) {
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(28,28)];
    return [[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){
        [UIColor.whiteColor setStroke]; UIBezierPath *p=[UIBezierPath bezierPath]; p.lineWidth=1.8; p.lineCapStyle=kCGLineCapRound; p.lineJoinStyle=kCGLineJoinRound;
        if (index==0) {
            [p moveToPoint:CGPointMake(8,7)]; [p addCurveToPoint:CGPointMake(3,22) controlPoint1:CGPointMake(3,8) controlPoint2:CGPointMake(1,22)];
            [p addCurveToPoint:CGPointMake(10,19) controlPoint1:CGPointMake(6,24) controlPoint2:CGPointMake(8,19)];
            [p addLineToPoint:CGPointMake(18,19)]; [p addCurveToPoint:CGPointMake(25,22) controlPoint1:CGPointMake(20,19) controlPoint2:CGPointMake(22,24)];
            [p addCurveToPoint:CGPointMake(20,7) controlPoint1:CGPointMake(27,22) controlPoint2:CGPointMake(25,8)]; [p closePath]; [p stroke];
            p=[UIBezierPath bezierPath]; p.lineWidth=1.8; [p moveToPoint:CGPointMake(7,12)]; [p addLineToPoint:CGPointMake(13,12)]; [p moveToPoint:CGPointMake(10,9)]; [p addLineToPoint:CGPointMake(10,15)]; [p stroke];
            [UIColor.whiteColor setFill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(18,10,2.5,2.5)] fill]; [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(21,14,2.5,2.5)] fill];
        } else if (index==1) {
            for (NSUInteger i=0;i<3;i++) { UIBezierPath *book=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(4+i*7,6-(i%2)*2,5,19+(i%2)*2) cornerRadius:1]; book.lineWidth=1.8; [book stroke]; }
        } else if (index==2) {
            p=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(3,3,22,22)]; p.lineWidth=1.8; [p stroke];
            p=[UIBezierPath bezierPath]; [p moveToPoint:CGPointMake(19,8)]; [p addLineToPoint:CGPointMake(16,17)]; [p addLineToPoint:CGPointMake(9,20)]; [p addLineToPoint:CGPointMake(12,11)]; [p closePath]; [UIColor.whiteColor setFill]; [p fill];
        } else {
            p=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(3,3,22,22)]; p.lineWidth=1.8; [p stroke];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(10,7,8,8)] fill];
            p=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(7,17,14,7) cornerRadius:4]; [p fill];
        }
    }] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

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
        self.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.12].CGColor;
        self.clipsToBounds = YES;
        self.material = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        self.material.userInteractionEnabled = NO; [self addSubview:self.material];
        self.backgroundColor = [LiraColor(0x292929) colorWithAlphaComponent:0.9];
        self.selection = [[UIView alloc] init]; self.selection.userInteractionEnabled = NO;
        self.selection.backgroundColor = [LiraMint() colorWithAlphaComponent:0.10];
        self.selection.layer.borderWidth = 0.8;
        self.selection.layer.borderColor = [LiraMint() colorWithAlphaComponent:0.25].CGColor;
        [self addSubview:self.selection];
        self.row = [[UIStackView alloc] init]; self.row.distribution = UIStackViewDistributionFillEqually;
        [self addSubview:self.row];
        NSArray *keys = @[@"lira.world.play", @"lira.world.library", @"lira.explore.title", @"lira.world.profile"];
        NSMutableArray *buttons = NSMutableArray.array;
        for (NSUInteger i=0;i<keys.count;i++) {
            UIButton *button = [LiraDockButton buttonWithType:UIButtonTypeSystem]; button.tag = i;
            [button setImage:LiraDockIcon(i) forState:UIControlStateNormal];
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
        b.tintColor = selected ? LiraMint() : LiraColor(0xAFAFAF);
        [b setTitleColor:b.tintColor forState:UIControlStateNormal];
        b.accessibilityTraits = UIAccessibilityTraitButton | (selected ? UIAccessibilityTraitSelected : 0);
    }
    if (animated && LiraMotionAllowed()) {
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{ self.selection.frame = [self selectionFrame]; } completion:nil];
    } else self.selection.frame = [self selectionFrame];
}
- (void)tapped:(UIButton *)button { if (self.didSelectDestination) self.didSelectDestination(button.tag); }
@end
