//
//  ImageTableViewCell.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/10.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ImageTableViewCell.h"
#import "ImagePickerCollectionView.h"

@implementation ImageTableViewCell

+ (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setCollectionView:(ImagePickerCollectionView *)collectionView
{
    [_collectionView removeFromSuperview];

    _collectionView = collectionView;
    [self.contentView addSubview:_collectionView];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _collectionView = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _collectionView.frame = CGRectMake(-CGRectGetWidth(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds)*3, CGRectGetHeight(self.bounds));
    _collectionView.contentInset = UIEdgeInsetsMake(0.0, CGRectGetWidth(self.bounds), 0.0, CGRectGetWidth(self.bounds));
}

@end
