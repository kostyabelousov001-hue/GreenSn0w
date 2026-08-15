//
//  DORampageOverlayView.m
//  GreenSn0w
//
//  Created by GreenSn0w on 15/08/2026.
//

#import "DORampageOverlayView.h"

@implementation DORampageOverlayView
{
    UILabel *_counterLabel;
    NSUInteger _counter;
}

- (id)init
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 1.0;

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = @"MODE RAMPAGE";
        titleLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightBold];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:titleLabel];

        _counterLabel = [[UILabel alloc] init];
        _counterLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _counterLabel.text = @"-";
        _counterLabel.font = [UIFont monospacedSystemFontOfSize:48 weight:UIFontWeightHeavy];
        _counterLabel.textColor = [UIColor blackColor];
        _counterLabel.textAlignment = NSTextAlignmentCenter;
        _counterLabel.numberOfLines = 2;
        _counterLabel.minimumScaleFactor = 0.2;
        _counterLabel.adjustsFontSizeToFitWidth = YES;
        _counterLabel.lineBreakMode = NSLineBreakByClipping;
        [self addSubview:_counterLabel];

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],

            [_counterLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:4],
            [_counterLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [_counterLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [_counterLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
        ]];
    }
    return self;
}

- (void)incrementCounter
{
    _counter++;
    NSString *dashes = [@"" stringByPaddingToLength:_counter withString:@"-" startingAtIndex:0];
    _counterLabel.text = dashes;
    if ([NSThread isMainThread]) {
        _counterLabel.alpha = 1.0;
    }
}

@end