//
//  UIImage+Compress.h
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/1/23.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ALAssetRepresentation;

@interface UIImage (Compress)
/** 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)compressImageWithSize:(CGFloat)size;
/** 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)compressImageDataWithSize:(CGFloat)size;

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)fastestCompressImageWithSize:(CGFloat)size;
/** 快速压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)fastestCompressImageDataWithSize:(CGFloat)size;

/** 微调压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)microCompressImageDataWithSize:(CGFloat)size;

/** 官方提供 */
/** 内存消耗少 压缩图片ALAssetRepresentation的原图大小  */
+ (UIImage *)imageThumbnailFromAsset:(ALAssetRepresentation *)assetRepresentation maxPixelSize:(NSUInteger)size;
/** 根据ALAssetRepresentation获取原图data */
+ (NSData *)imageDataFromAsset:(ALAssetRepresentation *)assetRepresentation;
/** 内存消耗少 压缩图片data为指定大小 */
+ (UIImage *)imageThumbnailFromData:(NSData *)data imageSize:(NSUInteger)imageSize;
@end
