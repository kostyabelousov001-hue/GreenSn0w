//
//  DOTerminalLogView.m
//  GreenSn0w
//
//  Created by GreenSn0w on 13/08/2026.
//

#import "DOTerminalLogView.h"
#import <sys/utsname.h>

#define TERMINAL_FONT_SIZE 12.0f
#define TERMINAL_TICK_INTERVAL (1.0f / 30.0f)
#define TERMINAL_TYPECHARS_PER_TICK 2
#define TERMINAL_CURSOR_TOGGLE_TICKS 16
#define TERMINAL_MAX_INSTANT_LINE_LENGTH 150

static NSString *const kSpinnerFrames = @"⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";

@implementation DOTerminalLogView
{
    UITextView *_textView;
    NSMutableAttributedString *_content;
    NSTimer *_animTimer;
    NSUInteger _tickCount;

    BOOL _hasActiveLine;
    NSUInteger _activeLineStart;
    NSMutableString *_activeLineText;
    NSUInteger _typewriterPos;
    UIColor *_activeLineColor;
    UIColor *_activeLinePrefixColor;
    NSString *_activeLinePrefix;
}

#pragma mark - Colors

+ (UIColor *)terminalBackgroundColor
{
    return [UIColor colorWithWhite:1.0 alpha:0.98];
}

+ (UIColor *)terminalTextColor
{
    return [UIColor colorWithWhite:0.10 alpha:1.0];
}

+ (UIColor *)terminalDimColor
{
    return [UIColor colorWithWhite:0.55 alpha:1.0];
}

+ (UIColor *)terminalBrightColor
{
    return [UIColor colorWithWhite:0.0 alpha:1.0];
}

+ (UIColor *)terminalRedColor
{
    return [UIColor colorWithRed:0.80 green:0.10 blue:0.10 alpha:1.0];
}

+ (UIColor *)terminalYellowColor
{
    return [UIColor colorWithRed:0.70 green:0.45 blue:0.0 alpha:1.0];
}

+ (UIColor *)terminalCyanColor
{
    return [UIColor colorWithRed:0.0 green:0.45 blue:0.55 alpha:1.0];
}

#pragma mark - Init

- (id)init
{
    if (self = [super init]) {
        self.backgroundColor = [DOTerminalLogView terminalBackgroundColor];

        _content = [NSMutableAttributedString new];
        _hasActiveLine = NO;

        _textView = [[UITextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.editable = NO;
        _textView.scrollEnabled = YES;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.textContainerInset = UIEdgeInsetsMake(18, 16, 24, 16);
        [self addSubview:_textView];

        [NSLayoutConstraint activateConstraints:@[
            [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_textView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];

        [self appendBanner];

        _animTimer = [NSTimer scheduledTimerWithTimeInterval:TERMINAL_TICK_INTERVAL target:self selector:@selector(tick) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animTimer forMode:NSRunLoopCommonModes];
        [_animTimer setTolerance:0.004];
    }
    return self;
}

- (void)dealloc
{
    [_animTimer invalidate];
}

- (NSString *)deviceModelName
{
    struct utsname name;
    uname(&name);
    return [NSString stringWithUTF8String:name.machine];
}

- (void)appendBanner
{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"";
    NSString *iosVersion = [[UIDevice currentDevice] systemVersion];

    NSString *logo =
        @"  ___                  ___      __\n"
        @" / __|_ _ ___ ___ _ _ / __|_ _ /  \\__ __ __\n"
        @"| (_ | '_/ -_) -_) ' \\\\__ \\ ' \\ () \\ V  V /\n"
        @" \\___|_| \\___\\___|_||_|___/_||_\\__/ \\_/\\_/";

    [self appendRawString:logo color:[DOTerminalLogView terminalTextColor] size:10.0f];
    [self appendRawString:[NSString stringWithFormat:@"\nGreenSn0w v%@ — kernel exploit: GreenSword", appVersion]
                    color:[DOTerminalLogView terminalBrightColor] size:TERMINAL_FONT_SIZE];
    [self appendRawString:[NSString stringWithFormat:@"device: %@ | iOS %@", [self deviceModelName], iosVersion]
                    color:[DOTerminalLogView terminalDimColor] size:TERMINAL_FONT_SIZE];
    [self appendRawString:@"$ greensn0w --jailbreak"
                    color:[DOTerminalLogView terminalTextColor] size:TERMINAL_FONT_SIZE];
    [self appendRawString:@"--------------------------------------------------------------------------------"
                    color:[DOTerminalLogView terminalDimColor] size:TERMINAL_FONT_SIZE];
}

#pragma mark - DOLogViewProtocol

- (void)showLog:(NSString *)log
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showLog:log];
        });
        return;
    }
    if (!log) return;

    [self finalizeActiveLine];

    UIColor *prefixColor = [DOTerminalLogView terminalTextColor];
    UIColor *textColor = [DOTerminalLogView terminalTextColor];
    NSString *prefix = @"*";

    if ([log hasPrefix:@"[+]"]) {
        prefix = @"+";
        prefixColor = [DOTerminalLogView terminalBrightColor];
    }
    else if ([log hasPrefix:@"[-]"]) {
        prefix = @"-";
        prefixColor = [DOTerminalLogView terminalRedColor];
        textColor = [DOTerminalLogView terminalRedColor];
    }
    else if ([log hasPrefix:@"[i]"]) {
        prefix = @"i";
        prefixColor = [DOTerminalLogView terminalCyanColor];
    }
    else if ([log hasPrefix:@"[*]"]) {
        prefix = @"*";
        prefixColor = [DOTerminalLogView terminalYellowColor];
    }
    else if ([log hasPrefix:@"[!]"]) {
        prefix = @"!";
        prefixColor = [DOTerminalLogView terminalYellowColor];
    }
    else if ([log hasPrefix:@"$"] || [log hasPrefix:@"success"]) {
        prefix = @"$";
        prefixColor = [DOTerminalLogView terminalBrightColor];
    }

    if ([log length] <= 3) {
        prefix = @" ";
    }

    _activeLinePrefix = prefix;
    _activeLinePrefixColor = prefixColor;
    _activeLineColor = textColor;
    _activeLineText = [log mutableCopy];
    _typewriterPos = 0;
    _hasActiveLine = YES;
    _activeLineStart = _content.length;

    [self renderActiveLine];
}

- (void)updateLog:(NSString *)log
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLog:log];
        });
        return;
    }
    if (!_hasActiveLine || !log) return;

    _activeLineText = [log mutableCopy];
    _typewriterPos = _activeLineText.length;
    [self renderActiveLine];
}

- (void)didComplete
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self didComplete];
        });
        return;
    }

    [self finalizeActiveLine];
    [self appendRawString:[NSString stringWithFormat:@"\n[done] process completed successfully ✓"]
                    color:[DOTerminalLogView terminalBrightColor] size:TERMINAL_FONT_SIZE];
    [self appendRawString:@"$ reboot userspace"
                    color:[DOTerminalLogView terminalDimColor] size:TERMINAL_FONT_SIZE];

    [_animTimer invalidate];
    _animTimer = nil;
}

#pragma mark - Line handling

- (void)finalizeActiveLine
{
    if (!_hasActiveLine) return;

    BOOL failed = [_activeLineText hasPrefix:@"[-]"];
    NSString *mark = failed ? @"✗" : @"✓";
    UIColor *markColor = failed ? [DOTerminalLogView terminalRedColor] : [DOTerminalLogView terminalBrightColor];

    [_content deleteCharactersInRange:NSMakeRange(_activeLineStart, _content.length - _activeLineStart)];

    NSMutableAttributedString *line = [NSMutableAttributedString new];
    [line appendAttributedString:[self attributedString:@"  " color:[DOTerminalLogView terminalDimColor]]];
    [line appendAttributedString:[self attributedString:mark color:markColor]];
    [line appendAttributedString:[self attributedString:@" " color:[DOTerminalLogView terminalDimColor]]];
    [line appendAttributedString:[self attributedString:_activeLineText color:_activeLineColor]];
    [line appendAttributedString:[self attributedString:@"\n" color:[DOTerminalLogView terminalDimColor]]];

    [_content appendAttributedString:line];
    [self commitContent];

    _hasActiveLine = NO;
    _activeLineText = nil;
}

- (void)renderActiveLine
{
    if (!_hasActiveLine) return;

    [_content deleteCharactersInRange:NSMakeRange(_activeLineStart, _content.length - _activeLineStart)];

    NSUInteger frame = (_tickCount / 2) % [kSpinnerFrames length];
    NSString *spinner = [kSpinnerFrames substringWithRange:NSMakeRange(frame, 1)];
    BOOL showCursor = (_tickCount / TERMINAL_CURSOR_TOGGLE_TICKS) % 2 == 0;

    NSUInteger shownLength = MIN(_typewriterPos, _activeLineText.length);
    NSString *shownText = [_activeLineText substringToIndex:shownLength];

    NSMutableAttributedString *line = [NSMutableAttributedString new];
    [line appendAttributedString:[self attributedString:@"  " color:[DOTerminalLogView terminalDimColor]]];
    [line appendAttributedString:[self attributedString:spinner color:_activeLinePrefixColor]];
    [line appendAttributedString:[self attributedString:@" " color:[DOTerminalLogView terminalDimColor]]];
    [line appendAttributedString:[self attributedString:shownText color:_activeLineColor]];
    if (showCursor) {
        [line appendAttributedString:[self attributedString:@"█" color:_activeLinePrefixColor]];
    }
    [line appendAttributedString:[self attributedString:@"\n" color:[DOTerminalLogView terminalDimColor]]];

    [_content appendAttributedString:line];
    [self commitContent];
}

- (void)tick
{
    _tickCount++;

    if (_hasActiveLine && _typewriterPos < _activeLineText.length) {
        if (_activeLineText.length > TERMINAL_MAX_INSTANT_LINE_LENGTH) {
            _typewriterPos = _activeLineText.length;
        }
        else {
            _typewriterPos = MIN(_typewriterPos + TERMINAL_TYPECHARS_PER_TICK, _activeLineText.length);
        }
    }
    if (_hasActiveLine) {
        [self renderActiveLine];
    }
}

#pragma mark - Raw append

- (NSAttributedString *)attributedString:(NSString *)string color:(UIColor *)color
{
    return [self attributedString:string color:color size:TERMINAL_FONT_SIZE];
}

- (NSAttributedString *)attributedString:(NSString *)string color:(UIColor *)color size:(CGFloat)size
{
    return [[NSAttributedString alloc] initWithString:string attributes:@{
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: color,
    }];
}

- (void)appendRawString:(NSString *)string color:(UIColor *)color size:(CGFloat)size
{
    [_content appendAttributedString:[self attributedString:string color:color size:size]];
    [_content appendAttributedString:[self attributedString:@"\n" color:[DOTerminalLogView terminalDimColor]]];
    [self commitContent];
}

- (void)commitContent
{
    const NSUInteger maxLength = 30000;
    if (_content.length > maxLength) {
        NSUInteger removeCount = _content.length - maxLength;
        NSRange removeRange = NSMakeRange(0, removeCount);
        if (_hasActiveLine && _activeLineStart >= removeRange.length) {
            _activeLineStart -= removeRange.length;
        }
        [_content deleteCharactersInRange:removeRange];
    }
    [UIView performWithoutAnimation:^{
        _textView.attributedText = _content;
        CGFloat bottom = _textView.contentSize.height - _textView.bounds.size.height;
        BOOL isAtBottom = _textView.contentOffset.y >= bottom - 40.0 || bottom <= 0;
        if (isAtBottom) {
            [_textView scrollRangeToVisible:NSMakeRange(_textView.text.length, 0)];
        }
    }];
}

@end
