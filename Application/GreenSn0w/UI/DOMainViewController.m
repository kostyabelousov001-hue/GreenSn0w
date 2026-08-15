//
//  DOMainViewController.m
//  GreenSn0w
//
//  Created by GreenSn0w on 13/08/2026.
//

#import "DOMainViewController.h"
#import "DOUIManager.h"
#import "DOEnvironmentManager.h"
#import "DOJailbreaker.h"
#import "DOGlobalAppearance.h"
#import "DOUpdateViewController.h"
#import "DOLogCrashViewController.h"
#import "DOTerminalLogView.h"
#import "DORampageOverlayView.h"
#import "DOPkgManagerPickerView.h"
#import "DOSettingsController.h"
#import "DOPreferenceManager.h"
#import <pthread.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <libjailbreak/libjailbreak.h>

static UIColor *CLIColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UIColor *CLIGreen(void)        { return CLIColor(0.05, 0.05, 0.05, 1.0); }
static UIColor *CLILightGreen(void)   { return CLIColor(0.15, 0.15, 0.15, 1.0); }
static UIColor *CLIDimGreen(void)     { return CLIColor(0.42, 0.42, 0.42, 1.0); }
static UIColor *CLIDim(void)          { return CLIColor(0.55, 0.55, 0.55, 1.0); }

static UIFont *CLIFont(CGFloat size)
{
    return [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular];
}

@interface DOMainViewController ()

@property (nonatomic) UIStackView *cliStackView;
@property (nonatomic) UILabel *jailbreakRowCursor;
@property (nonatomic) UIButton *jailbreakRow;
@property (nonatomic) UIButton *settingsRow;
@property (nonatomic) UIButton *logsRow;
@property (nonatomic) UIButton *crashRow;
@property (nonatomic) UIButton *hideRow;
@property (nonatomic) UIButton *updateRow;
@property (nonatomic) UILabel *promptBlock;
@property (nonatomic) UILabel *statusLabel;
@property (nonatomic) NSTimer *blinkTimer;
@property (nonatomic) BOOL isJailbreaking;
@property(nonatomic) BOOL hideStatusBar;
@property(nonatomic) BOOL hideHomeIndicator;
@property (nonatomic) DORampageOverlayView *rampageOverlay;

@end

@implementation DOMainViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupTerminalUI];

    _blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.53 target:self selector:@selector(blinkTick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_blinkTimer forMode:NSRunLoopCommonModes];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if ([[DOUIManager sharedInstance] environmentUpdateAvailable]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupUpdateRow];
            });
        }
        else if ([[DOUIManager sharedInstance] isUpdateAvailable]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setupUpdateRow];
            });
        }
    });
}

- (void)dealloc
{
    [_blinkTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rampageLogLine:(NSNotification *)notification
{
    [_rampageOverlay incrementCounter];
}

#pragma mark - Terminal UI

- (void)setupTerminalUI
{
    _cliStackView = [[UIStackView alloc] init];
    _cliStackView.axis = UILayoutConstraintAxisVertical;
    _cliStackView.alignment = UIStackViewAlignmentLeading;
    _cliStackView.spacing = 0;
    _cliStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_cliStackView];

    CGFloat rowFontSize = [DOGlobalAppearance isSmallDevice] ? 14.0 : 16.0;
    CGFloat logoFontSize = [DOGlobalAppearance isSmallDevice] ? 9.0 : 11.0;

    // ASCII logo
    NSString *logo =
        @"  ___                  ___      __\n"
        @" / __|_ _ ___ ___ _ _ / __|_ _ /  \\__ __ __\n"
        @"| (_ | '_/ -_) -_) ' \\\\__ \\ ' \\ () \\ V  V /\n"
        @" \\___|_| \\___\\___|_||_|___/_||_\\__/ \\_/\\_/";

    UILabel *logoLabel = [[UILabel alloc] init];
    logoLabel.numberOfLines = 0;
    logoLabel.font = CLIFont(logoFontSize);
    logoLabel.textColor = CLIGreen();
    logoLabel.text = logo;
    [_cliStackView addArrangedSubview:logoLabel];

    [self addSpacer:16];

    // System info block
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
    NSString *supportString = [[DOEnvironmentManager sharedManager] versionSupportString];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSArray<NSString *> *infoLines = @[
        [NSString stringWithFormat:@"device   : %@", [self deviceModelName]],
        [NSString stringWithFormat:@"ios      : %@", iosVersion],
        [NSString stringWithFormat:@"build    : %@", appVersion],
        [NSString stringWithFormat:@"support  : %@", supportString],
    ];

    for (NSString *infoLine in infoLines) {
        UILabel *infoLabel = [[UILabel alloc] init];
        infoLabel.font = CLIFont(rowFontSize - 3.0);
        infoLabel.textColor = CLIDimGreen();
        infoLabel.text = infoLine;
        [_cliStackView addArrangedSubview:infoLabel];
    }

    [self addSpacer:20];
    [self addSeparator];

    // Menu rows
    _jailbreakRow = [self makeRowWithTitle:@"" color:CLIGreen() action:@selector(jailbreakRowPressed)];
    _settingsRow = [self makeRowWithTitle:@"settings" color:CLILightGreen() action:@selector(settingsRowPressed)];
    _logsRow = [self makeRowWithTitle:@"logs" color:CLILightGreen() action:@selector(logsRowPressed)];
    _crashRow = [self makeRowWithTitle:@"crash" color:CLILightGreen() action:@selector(crashRowPressed)];
    _hideRow = [self makeRowWithTitle:@"hide" color:CLILightGreen() action:@selector(hideRowPressed)];
    _updateRow = [self makeRowWithTitle:@"update" color:CLILightGreen() action:@selector(updateRowPressed)];

    [self addRowWithCursor:YES button:_jailbreakRow rowTitle:@""];
    [self addRowWithCursor:NO button:_settingsRow rowTitle:@"settings"];
    [self addRowWithCursor:NO button:_logsRow rowTitle:@"logs"];
    [self addRowWithCursor:NO button:_crashRow rowTitle:@"crash"];
    [self addRowWithCursor:NO button:_hideRow rowTitle:@"hide"];
    [self addRowWithCursor:NO button:_updateRow rowTitle:@"update"];
    _updateRow.hidden = YES;

    [self addSpacer:20];
    [self addSeparator];

    // Prompt
    UIStackView *promptStack = [[UIStackView alloc] init];
    promptStack.axis = UILayoutConstraintAxisHorizontal;
    promptStack.spacing = 4;
    promptStack.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *promptLabel = [[UILabel alloc] init];
    promptLabel.font = CLIFont(rowFontSize - 1.0);
    promptLabel.textColor = CLIDimGreen();
    promptLabel.text = @"greensn0w:~$";
    [promptStack addArrangedSubview:promptLabel];

    _promptBlock = [[UILabel alloc] init];
    _promptBlock.font = CLIFont(rowFontSize - 1.0);
    _promptBlock.textColor = CLIGreen();
    _promptBlock.text = @"█";
    [promptStack addArrangedSubview:_promptBlock];

    [_cliStackView addArrangedSubview:promptStack];

    // Status line (echoes last command)
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.font = CLIFont(rowFontSize - 4.0);
    _statusLabel.textColor = CLIDim();
    _statusLabel.text = @"tap a line below";
    [_cliStackView addArrangedSubview:_statusLabel];

    [self addSpacer:8];

    [NSLayoutConstraint activateConstraints:@[
        [_cliStackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:[self topOffset]],
        [_cliStackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_cliStackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:34],
        [_cliStackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-34],
    ]];

    [self updateRowStates];
}

- (CGFloat)topOffset
{
    CGFloat safeTop = [[UIApplication sharedApplication] keyWindow].safeAreaInsets.top ?: 20;
    return safeTop * 0.3;
}

- (NSString *)deviceModelName
{
    struct utsname name;
    uname(&name);
    return [NSString stringWithUTF8String:name.machine];
}

- (UILabel *)makeSeparatorLabel
{
    UILabel *separator = [[UILabel alloc] init];
    separator.font = CLIFont(13.0);
    separator.textColor = CLIDim();
    separator.text = @"--------------------------------------------------";
    return separator;
}

- (void)addSeparator
{
    [_cliStackView addArrangedSubview:[self makeSeparatorLabel]];
}

- (void)addSpacer:(CGFloat)height
{
    UIView *spacer = [[UIView alloc] init];
    spacer.translatesAutoresizingMaskIntoConstraints = NO;
    [_cliStackView addArrangedSubview:spacer];
    [NSLayoutConstraint activateConstraints:@[
        [spacer.heightAnchor constraintEqualToConstant:height],
    ]];
}

- (UIButton *)makeRowWithTitle:(NSString *)title color:(UIColor *)color action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: CLIFont(16.0),
        NSForegroundColorAttributeName: color,
    }] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)addRowWithCursor:(BOOL)hasCursor button:(UIButton *)button rowTitle:(NSString *)rowTitle
{
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisHorizontal;
    rowStack.spacing = 8;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *cursorLabel = [[UILabel alloc] init];
    cursorLabel.font = CLIFont(16.0);
    cursorLabel.textColor = CLIGreen();
    cursorLabel.text = hasCursor ? @">" : @" ";
    cursorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    if (hasCursor) {
        _jailbreakRowCursor = cursorLabel;
    }
    [rowStack addArrangedSubview:cursorLabel];
    [NSLayoutConstraint activateConstraints:@[
        [cursorLabel.widthAnchor constraintEqualToConstant:12],
    ]];

    [rowStack addArrangedSubview:button];

    [_cliStackView addArrangedSubview:rowStack];

    [NSLayoutConstraint activateConstraints:@[
        [rowStack.heightAnchor constraintEqualToConstant:34],
    ]];

    if (hasCursor) {
        [button setAttributedTitle:[[NSAttributedString alloc] initWithString:rowTitle attributes:@{
            NSFontAttributeName: CLIFont(16.0),
            NSForegroundColorAttributeName: CLIGreen(),
        }] forState:UIControlStateNormal];
    }
}

- (void)updateRowStates
{
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    BOOL isJailbroken = [envManager isJailbroken];
    BOOL isSupported = [envManager isSupported];

    NSString *title;
    UIColor *color;
    BOOL enabled = YES;

    if (!isSupported) {
        title = @"unsupported";
        color = CLIDimGreen();
        enabled = NO;
    }
    else if (isJailbroken) {
        BOOL removeJailbreakEnabled = [[DOPreferenceManager sharedManager] boolPreferenceValueForKey:@"removeJailbreakEnabled" fallback:NO];
        if (removeJailbreakEnabled) {
            title = @"unjailbreak";
            color = CLIGreen();
        }
        else {
            title = @"jailbroken";
            color = CLIDimGreen();
            enabled = NO;
        }
    }
    else {
        title = @"jailbreak";
        color = CLIGreen();
    }

    [_jailbreakRow setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: CLIFont(16.0),
        NSForegroundColorAttributeName: color,
    }] forState:UIControlStateNormal];
    _jailbreakRow.userInteractionEnabled = enabled;

    // Hide row
    BOOL hideJailbreakButtonShown = (isJailbroken || (envManager.isInstalledThroughTrollStore && envManager.isBootstrapped && !envManager.isJailbreakHidden));
    _hideRow.hidden = !hideJailbreakButtonShown;
    NSString *hideTitle = envManager.isJailbreakHidden ? @"unhide" : @"hide";
    [_hideRow setAttributedTitle:[[NSAttributedString alloc] initWithString:hideTitle attributes:@{
        NSFontAttributeName: CLIFont(16.0),
        NSForegroundColorAttributeName: CLILightGreen(),
    }] forState:UIControlStateNormal];
}

- (void)setupUpdateRow
{
    _updateRow.hidden = NO;
}

- (void)blinkTick
{
    BOOL visible = (_jailbreakRowCursor.alpha < 0.5) || (_promptBlock.alpha < 0.5);
    _jailbreakRowCursor.alpha = visible ? 1.0 : 0.0;
    _promptBlock.alpha = visible ? 1.0 : 0.0;
}

- (void)echo:(NSString *)command result:(NSString *)result
{
    _statusLabel.textColor = CLIDimGreen();
    _statusLabel.text = [NSString stringWithFormat:@"$ %@   %@", command, result];
    _statusLabel.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        _statusLabel.alpha = 1.0;
    }];
}

#pragma mark - Row Actions

- (void)jailbreakRowPressed
{
    [self echo:@"jailbreak" result:@"starting..."];
    [self startJailbreak];
}

- (void)settingsRowPressed
{
    [self echo:@"settings" result:@"opening..."];
    [self.navigationController pushViewController:[[DOSettingsController alloc] init] animated:YES];
}

- (void)logsRowPressed
{
    [self echo:@"logs" result:@"opening..."];
    [self.navigationController pushViewController:[[DOLogCrashViewController alloc] initWithTitle:DOLocalizedString(@"Log_Error")] animated:YES];
}

- (void)hideRowPressed
{
    DOEnvironmentManager *envManager = [DOEnvironmentManager sharedManager];
    BOOL hidden = ![envManager isJailbreakHidden];
    [envManager setJailbreakHidden:hidden];
    [self echo:hidden ? @"hide" : @"unhide" result:hidden ? @"jailbreak hidden ✓" : @"jailbreak unhidden ✓"];
    [self updateRowStates];
}

- (void)crashRowPressed
{
    [self echo:@"crash" result:@"checking..."];
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *crashReportPath = [docsDir stringByAppendingPathComponent:@"last_crash.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:crashReportPath]) {
        NSString *crashInfo = [NSString stringWithContentsOfFile:crashReportPath encoding:NSUTF8StringEncoding error:nil] ?: @"Unknown crash";
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Last crash" message:crashInfo preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSFileManager defaultManager] removeItemAtPath:crashReportPath error:nil];
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Last crash" message:@"No crash report found" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)updateRowPressed
{
    [self echo:@"update" result:@"checking releases..."];
    NSString *releaseFrom = [[DOUIManager sharedInstance] getLaunchedReleaseTag];
    NSString *releaseTo = [[DOUIManager sharedInstance] getLatestReleaseTag];
    if ([[DOUIManager sharedInstance] environmentUpdateAvailable]) {
        releaseFrom = [[DOEnvironmentManager sharedManager] jailbrokenVersion];
        releaseTo = [[DOUIManager sharedInstance] getLaunchedReleaseTag];
    }
    [self.navigationController pushViewController:[[DOUpdateViewController alloc] initFromTag:releaseFrom toTag:releaseTo] animated:YES];
}

#pragma mark - Jailbreak

- (void)startJailbreak
{
    if (_isJailbreaking) return;
    _isJailbreaking = YES;

    [[DOUIManager sharedInstance] startLogCapture];

    [UIView animateWithDuration:0.3 animations:^{
        _cliStackView.alpha = 0;
    }];

    DOTerminalLogView *logView = [[DOTerminalLogView alloc] init];
    logView.translatesAutoresizingMaskIntoConstraints = NO;
    logView.alpha = 0;
    [self.view addSubview:logView];
    [NSLayoutConstraint activateConstraints:@[
        [logView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [logView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [logView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [logView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    void (^showLogAndRun)(void) = ^{
        [[DOUIManager sharedInstance] setLogView:logView];
        [UIView animateWithDuration:0.25 animations:^{
            logView.alpha = 1;
        } completion:^(BOOL finished) {
            BOOL rampageEnabled = [[DOPreferenceManager sharedManager] boolPreferenceValueForKey:@"rampageModeEnabled" fallback:NO];
            if (rampageEnabled && !_rampageOverlay) {
                _rampageOverlay = [[DORampageOverlayView alloc] init];
                _rampageOverlay.translatesAutoresizingMaskIntoConstraints = NO;
                [self.view addSubview:_rampageOverlay];
                [NSLayoutConstraint activateConstraints:@[
                    [_rampageOverlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                    [_rampageOverlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                    [_rampageOverlay.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                    [_rampageOverlay.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:1.0/3.0],
                ]];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rampageLogLine:) name:@"DORampageLogLineNotification" object:nil];
            }
        }];
        [self runJailbreak];
    };

    if ([[DOUIManager sharedInstance] enabledPackageManagerKeys].count == 0) {
        DOPkgManagerPickerView *pickerView = [[DOPkgManagerPickerView alloc] initWithCallback:^(BOOL success) {
            [pickerView removeFromSuperview];
            showLogAndRun();
        }];
        pickerView.translatesAutoresizingMaskIntoConstraints = NO;
        pickerView.alpha = 0;
        [self.view addSubview:pickerView];
        [NSLayoutConstraint activateConstraints:@[
            [pickerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [pickerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [pickerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [pickerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
        [UIView animateWithDuration:0.25 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            pickerView.alpha = 1.0;
        } completion:nil];
    }
    else {
        showLogAndRun();
    }
}

- (void)runJailbreak
{
    DOJailbreaker *jailbreaker = [[DOJailbreaker alloc] init];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if ([jailbreaker contiguousMappingWorkaroundNeeded]) {
            cpu_subtype_t cpuFamily = 0;
            size_t cpuFamilySize = sizeof(cpuFamily);
            sysctlbyname("hw.cpufamily", &cpuFamily, &cpuFamilySize, NULL, 0);
            NSString *workaroundMessage = DOLocalizedString(@"Respring_Required_Message");
            if (cpuFamily == CPUFAMILY_ARM_TYPHOON) {
                workaroundMessage = [workaroundMessage stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", DOLocalizedString(@"Respring_Required_Notice_A8")]];
            }

            UIAlertController *contiguousMappingWorkaroundAlertController = [UIAlertController alertControllerWithTitle:DOLocalizedString(@"Respring_Required") message:workaroundMessage preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DOLocalizedString(@"Respring_Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                exit(0);
            }];

            UIAlertAction *workaroundAction = [UIAlertAction actionWithTitle:DOLocalizedString(@"Apply_Workaround") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [jailbreaker applyContiguousMappingWorkaround];
            }];

            [contiguousMappingWorkaroundAlertController addAction:cancelAction];
            [contiguousMappingWorkaroundAlertController addAction:workaroundAction];
            contiguousMappingWorkaroundAlertController.preferredAction = workaroundAction;

            dispatch_async(dispatch_get_main_queue(), ^{
                _isJailbreaking = NO;
                [self presentViewController:contiguousMappingWorkaroundAlertController animated:YES completion:nil];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.hideHomeIndicator = YES;
        });

        NSError *error;
        BOOL didRemove = NO;
        BOOL showLogs = YES;
        [jailbreaker runWithError:&error didRemoveJailbreak:&didRemove showLogs:&showLogs];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error && showLogs) {
                [[DOUIManager sharedInstance] sendLog:[NSString stringWithFormat:@"Jailbreak failed with error: %@", error] debug:NO];
                [self.navigationController pushViewController:[[DOLogCrashViewController alloc] initWithTitle:[error localizedDescription]] animated:YES];
            }
            else if (error && !showLogs) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DOLocalizedString(@"Log_Error") message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *rebootAction = [UIAlertAction actionWithTitle:DOLocalizedString(@"Button_Reboot") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    exec_cmd_trusted(JBROOT_PATH("/sbin/reboot"), NULL);
                }];
                [alertController addAction:rebootAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else if (didRemove) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:DOLocalizedString(@"Removed_Jailbreak_Alert_Title") message:DOLocalizedString(@"Removed_Jailbreak_Alert_Message") preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *rebootAction = [UIAlertAction actionWithTitle:DOLocalizedString(@"Button_Close") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    exit(0);
                }];
                [alertController addAction:rebootAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else {
                [[DOUIManager sharedInstance] completeJailbreak];
                [self fadeToBlack: ^{
                    [jailbreaker finalize];
                }];
            }
        });
    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateRowStates];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *crashReportPath = [docsDir stringByAppendingPathComponent:@"last_crash.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:crashReportPath]) {
        NSString *crashInfo = [NSString stringWithContentsOfFile:crashReportPath encoding:NSUTF8StringEncoding error:nil] ?: @"Unknown crash";
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"GreenSn0w crashed last time" message:crashInfo preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSFileManager defaultManager] removeItemAtPath:crashReportPath error:nil];
        }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)fadeToBlack:(void (^)(void))completion
{
    static bool didFade = false;
    if (didFade)
        return;
    didFade = true;
    UIView *mainView = self.parentViewController.view;
    float deviceCornerRadius = [[[UIScreen mainScreen] valueForKey:@"_displayCornerRadius"] floatValue];

    mainView.layer.cornerRadius = deviceCornerRadius;
    mainView.layer.cornerCurve = kCACornerCurveContinuous;
    mainView.layer.masksToBounds = YES;

    self.hideStatusBar = YES;

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:2.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        mainView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        mainView.alpha = 0.0;
    } completion:^(BOOL success) {
        completion();
    }];
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDarkContent;
}

- (BOOL)prefersStatusBarHidden
{
    return self.hideStatusBar;
}

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return self.hideHomeIndicator;
}

- (void)setHideStatusBar:(BOOL)hideStatusBar
{
    _hideStatusBar = hideStatusBar;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setHideHomeIndicator:(BOOL)hideHomeIndicator
{
    _hideHomeIndicator = hideHomeIndicator;
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
}

@end
