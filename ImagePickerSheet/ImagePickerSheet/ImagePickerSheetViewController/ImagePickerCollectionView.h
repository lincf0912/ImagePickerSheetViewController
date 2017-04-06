//
//  ImagePickerCollectionView.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/10.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ImagePreviewFlowLayout;

@interface ImagePickerCollectionView : UICollectionView

@property (nonatomic, strong) ImagePreviewFlowLayout *imagePreviewLayout;

@end
