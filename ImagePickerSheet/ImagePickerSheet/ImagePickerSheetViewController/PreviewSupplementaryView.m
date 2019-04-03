//
//  CollectionSupplementaryView.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/8.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "PreviewSupplementaryView.h"

@interface PreviewSupplementaryView ()

@property (nonatomic, strong) UIButton *button;

@end

@implementation PreviewSupplementaryView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _buttonInset = UIEdgeInsetsZero;
    [self addSubview:self.button];
}

- (UIButton *)button
{
    if (_button == nil) {
        _button = [[UIButton alloc] init];
        _button.tintColor = [UIColor whiteColor];
        _button.userInteractionEnabled = NO;
        [_button setImage:[PreviewSupplementaryView checkmarkImage] forState:UIControlStateNormal];
        [_button setImage:[PreviewSupplementaryView selectedCheckmarkImage] forState:UIControlStateSelected];
    }
    return _button;
}

/** 重用标识 */
+ (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

+ (NSBundle *)imagePickerSheetBundle
{
    static NSBundle *lf_imagePickerSheetBundle = nil;
    if (lf_imagePickerSheetBundle == nil) {
        // 这里不使用mainBundle是为了适配pod 1.x和0.x
        lf_imagePickerSheetBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[NSClassFromString(@"ImagePickerSheetViewController") class]] pathForResource:@"SupplementaryView" ofType:@"bundle"]];
    }
    return lf_imagePickerSheetBundle;
}

+ (UIImage *)checkmarkImage
{
    UIImage *image = [UIImage imageWithContentsOfFile:[[self imagePickerSheetBundle] pathForResource:@"PreviewSupplementaryView-Checkmark.png" ofType:nil]];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)selectedCheckmarkImage
{
    UIImage *image = [UIImage imageWithContentsOfFile:[[self imagePickerSheetBundle] pathForResource:@"PreviewSupplementaryView-Checkmark-Selected.png" ofType:nil]];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    _button.selected = selected;
    [self reloadButtonBackgroundColor];
}

- (void)reloadButtonBackgroundColor
{
    _button.backgroundColor = _button.selected ? self.tintColor : nil;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.selected = NO;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    [self reloadButtonBackgroundColor];
}

- (void)layoutSubviews
{
    [_button sizeToFit];
    CGRect buttonF = _button.frame;
    buttonF.origin = CGPointMake(_buttonInset.left, CGRectGetHeight(self.bounds)-CGRectGetHeight(_button.frame)-_buttonInset.bottom);
    _button.frame = buttonF;
    _button.layer.cornerRadius = CGRectGetHeight(_button.frame) / 2.0;
}

@end
