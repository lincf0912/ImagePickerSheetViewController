//
//  ImageCollectionViewCell.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/8.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCollectionViewCell : UICollectionViewCell

/** 重用标识 */
+ (NSString *)identifier;

@property (nonatomic, strong) UIImageView *imageView;
@end
