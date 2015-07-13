//
//  DefineHeader.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/9.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#ifndef ImagePickerSheet_DefineHeader_h
#define ImagePickerSheet_DefineHeader_h

/** ImagePickerSheetViewController */
/** 最大显示数量 */
#define kMaxNum 10
/** 屏幕大小 */
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
/** 选择器高度 */
#define tableViewPreviewRowHeight 140.0
#define tableViewEnlargedPreviewRowHeight 243.0
#define tableViewCellHeight 50.0
/** 选择器放大扩展高度 */
#define imagePickerExpandHeight ScreenHeight*0.1
/** 打勾图标间距 */
#define kCollectionViewCheckmarkInset 3.5

/** ImagePickerView */
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define kPhotoBtnTitle @"相册"
#define kCameraBtnTitle @"拍照"
#define kCancelBtnTitle @"取消"

/** ImageCollectionViewFlowLayout */
/** 显示图片间距 */
#define collectionViewInset 5.0

#endif
