//
//  ImagePickerCollectionView.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/10.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ImagePickerCollectionView.h"
#import "ImagePreviewFlowLayout.h"

@implementation ImagePickerCollectionView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero collectionViewLayout:[[ImagePreviewFlowLayout alloc] init]];
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
    
}

- (ImagePreviewFlowLayout *)imagePreviewLayout
{
    return (ImagePreviewFlowLayout *)self.collectionViewLayout;
}

@end
