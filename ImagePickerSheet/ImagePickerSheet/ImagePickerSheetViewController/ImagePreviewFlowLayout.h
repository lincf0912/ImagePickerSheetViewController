//
//  ImageCollectionViewFlowLayout.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/8.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePreviewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) BOOL showSupplementaryViews;

@property (nonatomic, strong) NSIndexPath *invalidationCenteredIndexPath;
@end
