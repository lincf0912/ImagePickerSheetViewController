//
//  ImageTableViewCell.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/10.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ImagePickerCollectionView;

@interface ImageTableViewCell : UITableViewCell
/** 重用标识 */
+ (NSString *)identifier;
@property (nonatomic, strong) ImagePickerCollectionView *collectionView;
@end
