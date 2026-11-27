#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface VDSModMenuManager : NSObject
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *menuContainer;
@property (nonatomic, strong) UIView *contentPanel;
@property (nonatomic, strong) UIButton *tabFeatureBtn;
@property (nonatomic, strong) UIButton *tabSettingBtn;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, assign) BOOL autoMultiLayer;
@property (nonatomic, assign) BOOL autoMultiQR;
@property (nonatomic, assign) BOOL optimizeExport;
+ (instancetype)sharedInstance;
- (void)setupOverlay;
@end

@implementation VDSModMenuManager

+ (instancetype)sharedInstance {
    static VDSModMenuManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VDSModMenuManager alloc] init];
    });
    return instance;
}

- (UIImage *)loadCharacterBannerImage {
    // Đặt file ảnh của bạn tên là "char_bg.jpg" vào cùng thư mục tweak/bundle hoặc Documents của app
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *imgPath = [docPath stringByAppendingPathComponent:@"char_bg.jpg"];
    UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
    if (!img) {
        img = [UIImage imageNamed:@"char_bg.jpg"];
    }
    return img;
}

- (void)setupOverlay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.overlayWindow) return;

        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        if (activeScene) {
            self.overlayWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        } else {
            self.overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        self.overlayWindow.windowLevel = UIWindowLevelAlert + 100;
        self.overlayWindow.backgroundColor = [UIColor clearColor];
        self.overlayWindow.userInteractionEnabled = YES;

        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.overlayWindow.rootViewController = rootVC;
        [self.overlayWindow makeKeyAndVisible];

        // Nút nổi (Floating Button) - tông xám bạc + viền tím khói
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(20, 140, 48, 48);
        self.floatingBtn.backgroundColor = [UIColor colorWithRed:0.13 green:0.12 blue:0.16 alpha:0.92];
        self.floatingBtn.layer.cornerRadius = 24;
        self.floatingBtn.layer.borderWidth = 1.5;
        self.floatingBtn.layer.borderColor = [UIColor colorWithRed:0.68 green:0.52 blue:0.85 alpha:0.85].CGColor;
        [self.floatingBtn setTitle:@"VDS" forState:UIControlStateNormal];
        [self.floatingBtn setTitleColor:[UIColor colorWithRed:0.88 green:0.86 blue:0.93 alpha:1.0] forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingBtn addGestureRecognizer:pan];
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

        [rootVC.view addSubview:self.floatingBtn];
        [self buildMenuUIInView:rootVC.view];
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *piece = gesture.view;
    CGPoint translation = [gesture translationInView:piece.superview];
    CGPoint newCenter = CGPointMake(piece.center.x + translation.x, piece.center.y + translation.y);

    CGFloat halfW = piece.bounds.size.width / 2.0;
    CGFloat halfH = piece.bounds.size.height / 2.0;
    CGSize screenSize = piece.superview.bounds.size;

    newCenter.x = MIN(MAX(newCenter.x, halfW + 8), screenSize.width - halfW - 8);
    newCenter.y = MIN(MAX(newCenter.y, halfH + 40), screenSize.height - halfH - 30);

    piece.center = newCenter;
    [gesture setTranslation:CGPointZero inView:piece.superview];
}

- (void)buildMenuUIInView:(UIView *)parentView {
    CGFloat w = MIN(parentView.bounds.size.width - 40, 340);
    CGFloat h = 470;

    self.menuContainer = [[UIView alloc] initWithFrame:CGRectMake((parentView.bounds.size.width - w) / 2.0,
                                                                 (parentView.bounds.size.height - h) / 2.0,
                                                                 w, h)];
    self.menuContainer.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:0.97];
    self.menuContainer.layer.cornerRadius = 18;
    self.menuContainer.layer.borderWidth = 1.2;
    self.menuContainer.layer.borderColor = [UIColor colorWithRed:0.58 green:0.46 blue:0.76 alpha:0.75].CGColor;
    self.menuContainer.clipsToBounds = YES;
    self.menuContainer.hidden = YES;

    // Header Banner có ảnh nhân vật tóc bạc mắt tím
    UIView *headerBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 128)];
    UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:headerBox.bounds];
    bgImgView.contentMode = UIViewContentModeScaleAspectFill;
    bgImgView.clipsToBounds = YES;
    UIImage *charImg = [self loadCharacterBannerImage];
    if (charImg) {
        bgImgView.image = charImg;
    } else {
        bgImgView.backgroundColor = [UIColor colorWithRed:0.18 green:0.17 blue:0.22 alpha:1.0];
    }
    [headerBox addSubview:bgImgView];

    // Lớp phủ gradient tối để chữ nổi rõ
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = headerBox.bounds;
    grad.colors = @[
        (id)[UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.35].CGColor,
        (id)[UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:0.95].CGColor
    ];
    [headerBox.layer addSublayer:grad];

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, w - 70, 24)];
    titleLbl.text = @"SILVER VIOLET // VDS";
    titleLbl.textColor = [UIColor colorWithRed:0.90 green:0.88 blue:0.95 alpha:1.0];
    titleLbl.font = [UIFont boldSystemFontOfSize:16];
    [headerBox addSubview:titleLbl];

    UILabel *subLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, w - 70, 18)];
    subLbl.text = @"Local Mode • No Key Required";
    subLbl.textColor = [UIColor colorWithRed:0.74 green:0.58 blue:0.92 alpha:1.0];
    subLbl.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [headerBox addSubview:subLbl];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(w - 44, 12, 32, 32);
    closeBtn.backgroundColor = [UIColor colorWithRed:0.18 green:0.17 blue:0.22 alpha:0.85];
    closeBtn.layer.cornerRadius = 16;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [headerBox addSubview:closeBtn];

    [self.menuContainer addSubview:headerBox];

    // Thanh chuyển Tab: Tính Năng / Cài Đặt
    CGFloat tabY = 136;
    CGFloat tabW = (w - 36) / 2.0;

    self.tabFeatureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tabFeatureBtn.frame = CGRectMake(12, tabY, tabW, 34);
    self.tabFeatureBtn.layer.cornerRadius = 9;
    self.tabFeatureBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.tabFeatureBtn setTitle:@"TÍNH NĂNG" forState:UIControlStateNormal];
    [self.tabFeatureBtn addTarget:self action:@selector(switchToFeatureTab) forControlEvents:UIControlEventTouchUpInside];

    self.tabSettingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tabSettingBtn.frame = CGRectMake(24 + tabW, tabY, tabW, 34);
    self.tabSettingBtn.layer.cornerRadius = 9;
    self.tabSettingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.tabSettingBtn setTitle:@"CÀI ĐẶT" forState:UIControlStateNormal];
    [self.tabSettingBtn addTarget:self action:@selector(switchToSettingTab) forControlEvents:UIControlEventTouchUpInside];

    [self.menuContainer addSubview:self.tabFeatureBtn];
    [self.menuContainer addSubview:self.tabSettingBtn];

    // Khung nội dung
    self.contentPanel = [[UIView alloc] initWithFrame:CGRectMake(12, 180, w - 24, h - 192)];
    [self.menuContainer addSubview:self.contentPanel];

    [self switchToFeatureTab];
    [parentView addSubview:self.menuContainer];
}

- (void)styleActiveTab:(UIButton *)activeBtn inactiveBtn:(UIButton *)inactiveBtn {
    activeBtn.backgroundColor = [UIColor colorWithRed:0.56 green:0.42 blue:0.76 alpha:0.95];
    [activeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    inactiveBtn.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.20 alpha:0.9];
    [inactiveBtn setTitleColor:[UIColor colorWithRed:0.65 green:0.65 blue:0.72 alpha:1.0] forState:UIControlStateNormal];
}

- (void)clearContentPanel {
    for (UIView *sub in self.contentPanel.subviews) {
        [sub removeFromSuperview];
    }
}

- (UIView *)createToggleRowWithTitle:(NSString *)title
                            subtitle:(NSString *)subtitle
                               frame:(CGRect)frame
                              isOn:(BOOL)isOn
                              action:(SEL)action {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.19 alpha:0.92];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.8;
    card.layer.borderColor = [UIColor colorWithRed:0.45 green:0.38 blue:0.58 alpha:0.45].CGColor;

    UILabel *tLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, frame.size.width - 76, 20)];
    tLbl.text = title;
    tLbl.textColor = [UIColor colorWithRed:0.92 green:0.90 blue:0.96 alpha:1.0];
    tLbl.font = [UIFont boldSystemFontOfSize:13];
    [card addSubview:tLbl];

    UILabel *sLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 28, frame.size.width - 76, 32)];
    sLbl.text = subtitle;
    sLbl.textColor = [UIColor colorWithRed:0.65 green:0.65 blue:0.72 alpha:1.0];
    sLbl.font = [UIFont systemFontOfSize:11];
    sLbl.numberOfLines = 2;
    [card addSubview:sLbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(frame.size.width - 62, 16, 51, 31)];
    sw.on = isOn;
    sw.onTintColor = [UIColor colorWithRed:0.60 green:0.44 blue:0.82 alpha:1.0];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [card addSubview:sw];

    return card;
}

- (void)switchToFeatureTab {
    [self styleActiveTab:self.tabFeatureBtn inactiveBtn:self.tabSettingBtn];
    [self clearContentPanel];

    CGFloat cw = self.contentPanel.bounds.size.width;
    [self.contentPanel addSubview:[self createToggleRowWithTitle:@"Nhập Lớp Hàng Loạt"
                                                        subtitle:@"Tự động nạp ảnh/clip vào các layer liên tiếp."
                                                           frame:CGRectMake(0, 0, cw, 66)
                                                            isOn:self.autoMultiLayer
                                                          action:@selector(onToggleMultiLayer:)]];

    [self.contentPanel addSubview:[self createToggleRowWithTitle:@"Nhập Nhiều Mã QR"
                                                        subtitle:@"Áp dụng tuần tự album QR cho từng scene."
                                                           frame:CGRectMake(0, 76, cw, 66)
                                                            isOn:self.autoMultiQR
                                                          action:@selector(onToggleMultiQR:)]];

    [self.contentPanel addSubview:[self createToggleRowWithTitle:@"Tối Ưu Xuất Clip"
                                                        subtitle:@"Ưu tiên tài nguyên khi render/export."
                                                           frame:CGRectMake(0, 152, cw, 66)
                                                            isOn:self.optimizeExport
                                                          action:@selector(onToggleOptimizeExport:)]];
}

- (void)switchToSettingTab {
    [self styleActiveTab:self.tabSettingBtn inactiveBtn:self.tabFeatureBtn];
    [self clearContentPanel];

    CGFloat cw = self.contentPanel.bounds.size.width;
    UIView *infoCard = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, 110)];
    infoCard.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.19 alpha:0.92];
    infoCard.layer.cornerRadius = 12;
    infoCard.layer.borderWidth = 0.8;
    infoCard.layer.borderColor = [UIColor colorWithRed:0.45 green:0.38 blue:0.58 alpha:0.45].CGColor;

    UILabel *infoLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, cw - 24, 90)];
    infoLbl.numberOfLines = 4;
    infoLbl.textColor = [UIColor colorWithRed:0.84 green:0.82 blue:0.90 alpha:1.0];
    infoLbl.font = [UIFont systemFontOfSize:12];
    infoLbl.text = @"• Chế độ: Cá nhân (No Key)\n• Giao diện: Silver Violet UIKit\n• Mẹo: Kéo nút nổi VDS để đổi vị trí\n• Đặt ảnh char_bg.jpg vào Documents để đổi banner";
    [infoCard addSubview:infoLbl];
    [self.contentPanel addSubview:infoCard];

    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(0, 124, cw, 40);
    resetBtn.backgroundColor = [UIColor colorWithRed:0.24 green:0.18 blue:0.32 alpha:0.95];
    resetBtn.layer.cornerRadius = 10;
    [resetBtn setTitle:@"Đặt Lại Vị Trí Nút Nổi" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [resetBtn addTarget:self action:@selector(resetFloatingBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.contentPanel addSubview:resetBtn];
}

- (void)resetFloatingBtn {
    self.floatingBtn.frame = CGRectMake(20, 140, 48, 48);
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    self.menuContainer.hidden = !self.isMenuOpen;
}

- (void)onToggleMultiLayer:(UISwitch *)sender {
    self.autoMultiLayer = sender.isOn;
    // TODO: Gắn hàm hook xử lý multi-layer của Video Star tại đây
}

- (void)onToggleMultiQR:(UISwitch *)sender {
    self.autoMultiQR = sender.isOn;
    // TODO: Gắn hàm hook xử lý batch QR của Video Star tại đây
}

- (void)onToggleOptimizeExport:(UISwitch *)sender {
    self.optimizeExport = sender.isOn;
    // TODO: Gắn hàm hook tối ưu tiến trình xuất file tại đây
}

@end

static void __attribute__((constructor)) vds_init(void) {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[VDSModMenuManager sharedInstance] setupOverlay];
    }];
}
