//
//  ImageCollectionViewCell.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/8.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ImageCollectionViewCell.h"

@interface ImageCollectionViewCell ()

@end

@implementation ImageCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

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
    [self.contentView addSubview:self.imageView];
}

- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
//    self.imageView = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

@end
