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

        _counterLabel = [[UILabel alloc] init];
        _counterLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _counterLabel.text = @"-";
        _counterLabel.font = [UIFont monospacedSystemFontOfSize:72 weight:UIFontWeightHeavy];
        _counterLabel.textColor = [UIColor blackColor];
        _counterLabel.textAlignment = NSTextAlignmentCenter;
        _counterLabel.numberOfLines = 1;
        _counterLabel.minimumScaleFactor = 0.2;
        _counterLabel.adjustsFontSizeToFitWidth = YES;
        _counterLabel.lineBreakMode = NSLineBreakByClipping;
        [self addSubview:_counterLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_counterLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
            [_counterLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
            [_counterLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

- (void)incrementCounter
{
    _counter++;
    _counterLabel.text = [NSString stringWithFormat:@"-%lu", (unsigned long)_counter];
    if ([NSThread isMainThread]) {
        _counterLabel.alpha = 1.0;
    }
}

@end