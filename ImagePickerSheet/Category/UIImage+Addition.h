//
//  UIImage+Addition.h
//  MiracleMessenger
//
//  Created by Anson on 14-5-27.
//  Copyright (c) 2014年 gzmiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UIImage (Addition)

/** 将ALAssetOrientation转换为UIImageOrientation */
+ (UIImageOrientation)imgOrientationFromAssetOrientation:(ALAssetOrientation)assetOrientation;

//将横向等方向设定为图片竖直
- (UIImage *)fixOrientation;

@end
