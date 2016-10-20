//
//  UIImage+Compress.m
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/1/23.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import "UIImage+Compress.h"
#import <ImageIO/CGImageSource.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation UIImage (Compress)

/** 微调压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)microCompressImageDataWithSize:(CGFloat)size
{
    return [self microCompressImageSize:size];
}

- (NSData *)microCompressImageSize:(CGFloat)size
{
    /** 临时图片 */
    UIImage *compressedImage = self;
    CGFloat targetSize = size * 1024; // 压缩目标大小
    CGFloat percent = 0.9f; // 压缩系数
    /** 微调参数 */
    NSInteger microAdjustment = 5*1024;
    
    /** 记录上一次的压缩大小 */
    NSInteger imageDatalength = 0;
    
    NSData *imageData = nil;
    
    /** 压缩核心方法 */
    do {
        if (percent < 0.01) {
            /** 压缩系数不能少于0 */
            percent = 0.1f;
        }
        imageData = UIImageJPEGRepresentation(compressedImage, percent);
        
        //        NSLog(@"压缩后大小:%ldk, 压缩频率:%ldk", imageData.length/1024, (imageDatalength - imageData.length)/1024);
        // 压缩精确度调整
        if (imageData.length - targetSize < microAdjustment) {
            percent -= .02f; // 微调
        } else {
            percent -= .1f;
        }
        
        // 大小没有改变
        if (imageData.length == imageDatalength) {
            NSLog(@"压缩大小没有改变，需要调整图片尺寸");
            break;
        }
        imageDatalength = imageData.length;
    } while (imageData.length > targetSize+1024);/** 增加1k偏移量 */
    
    return imageData;
}

#pragma mark - /**************** 分割线 *******************/

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)fastestCompressImageWithSize:(CGFloat)size
{
    UIImage *compressedImage = [UIImage imageWithData:[self fastestCompressImageSize:size]];
    if (!compressedImage) {
        return self;
    }
    return compressedImage;
}

/** 快速压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)fastestCompressImageDataWithSize:(CGFloat)size
{
    return [self fastestCompressImageSize:size];
}

#pragma mark - 压缩图片接口
- (NSData *)fastestCompressImageSize:(CGFloat)size
{
    /** 临时图片 */
    UIImage *compressedImage = self;
    CGFloat targetSize = size * 1024; // 压缩目标大小
    CGFloat percent = 0.5f; // 压缩系数
    if (size <= 10) {
        percent = 0.01;
    }
    /** 微调参数 */
    NSInteger microAdjustment = 5*1024;
    /** 设备分辨率 */
    CGSize pixel = [UIImage appPixel];
    /** 缩放图片尺寸 */
    int MIN_UPLOAD_RESOLUTION = pixel.width * pixel.height;
    if (size < 100) {
        MIN_UPLOAD_RESOLUTION /= 2;
    }
    /** 缩放比例 */
    float factor;
    /** 当前图片尺寸 */
    float currentResolution = self.size.height * self.size.width;
    
    NSData *imageData = UIImageJPEGRepresentation(self, 1);
    
    /** 没有需要压缩的必要，直接返回 */
    if (imageData.length <= targetSize) return imageData;
    
    /** 缩放图片 */
    if (currentResolution > MIN_UPLOAD_RESOLUTION) {
        factor = sqrt(currentResolution / MIN_UPLOAD_RESOLUTION) * 2;
        compressedImage = [self scaleWithSize:CGSizeMake(self.size.width / factor, self.size.height / factor)];
    }
    
    /** 记录上一次的压缩大小 */
    NSInteger imageDatalength = 0;
    
    /** 压缩核心方法 */
    do {
        if (percent < 0.01) {
            /** 压缩系数不能少于0 */
            percent = 0.1f;
        }
        imageData = UIImageJPEGRepresentation(compressedImage, percent);
        
//        NSLog(@"压缩后大小:%ldk, 压缩频率:%ldk", imageData.length/1024, (imageDatalength - imageData.length)/1024);
        // 压缩精确度调整
        if (imageData.length - targetSize < microAdjustment) {
            percent -= .02f; // 微调
        } else {
            percent -= .1f;
        }
        
        // 大小没有改变
        if (imageData.length == imageDatalength) {
            //            NSLog(@"压缩大小没有改变，需要调整图片尺寸");
            //            break;
            float scale = targetSize/(imageData.length-targetSize);
            /** 精准缩放计算误差值 */
            float gap = targetSize/(imageData.length/2-targetSize);
            gap = gap >= 1.0f || gap <= 0 ? 0.85f : gap;
            scale *= gap;
            if (scale >= 1.0f || scale <= 0) scale = 0.85f;
            compressedImage = [self scaleWithSize:CGSizeMake(compressedImage.size.width * scale, compressedImage.size.height * scale)];
        }
        imageDatalength = imageData.length;
    } while (imageData.length > targetSize+1024);/** 增加1k偏移量 */
    
    return imageData;
}

#pragma mark - 缩放图片尺寸
- (UIImage*)scaleWithSize:(CGSize)newSize
{
    
    //We prepare a bitmap with the new size
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
    
    //Draws a rect for the image
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    //We set the scaled image from the context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

#pragma mark - /**************** 分割线 *******************/

- (NSData *)compressImageDataWithSize:(CGFloat)size
{
    NSData *data = [self compressImageSize:size];
    if (!data || data.length == 0) {
        return UIImageJPEGRepresentation(self, .9);
    }
    return data;
}

- (UIImage *)compressImageWithSize:(CGFloat)size
{
    /** 临时图片 */
    UIImage *compressedImage = [UIImage imageWithData:[self compressImageSize:size]];
    if (!compressedImage) {
        return self;
    }
    return compressedImage;
}

#pragma mark -图片压缩
- (NSData *)compressImageSize:(CGFloat)size
{
    CGFloat imageSize = UIImageJPEGRepresentation(self, 1).length;
    /** 临时图片 */
    UIImage *compressedImage = self;
    CGFloat targetSize = size * 1024; // 压缩目标大小
    NSData *data = [[NSData alloc]init];
    CGFloat compressImageWidth ; // 图片将要压缩的宽度
    CGFloat percent; // 压缩系数
    
    if (imageSize > targetSize) {
        if (compressedImage.size.width > 1136)
            compressImageWidth = 1136;
        else
            compressImageWidth = compressedImage.size.width;
        
         CGFloat scale = 0.95;
        
        // 尺寸压缩
        // compressedImage = [compressedImage imageCompressForTargetWidth:compressedImage.size.width * scale];
        
        // 质量压缩
        // data = [compressedImage compressImageWithPercent:percent targetSize:size];
        do {
            // 改变尺寸 ，再进行压缩（相同像素下图片质量相同）
            compressedImage = [compressedImage imageCompressForTargetWidth:compressImageWidth];
            
            // 返回图片质量都一样，只有高度不同 ，重设压缩系数
            if (compressedImage.size.width == 1136) {
                percent = .5;
            } else {
                percent = .3;
            }
            
            data = [compressedImage compressImageWithPercent:percent targetSize:size];
            compressImageWidth *= scale; // 改变宽高
            
        } while (data.length > targetSize);
    }
    return data;
}

#pragma mark 图片质量压缩
- (NSData *)compressImageWithPercent:(CGFloat)percent targetSize:(CGFloat)size
{
    // 压缩
    NSInteger targetLength = size * 1024;
    NSData *compressImageData = [[NSData alloc]init];
    NSData *comperData = [[NSData alloc]init]; // 用于比较data
    
    do {
        comperData = compressImageData;
        if (percent < 0) {
            percent = 0.001;
        }
        compressImageData = UIImageJPEGRepresentation(self, percent);
        
        // 压缩精确度调整
        if (compressImageData.length - targetLength < 50*1000) {
            percent -= .02; // 微调
        } else {
            percent -= .1;
        }
        
        // 大小没有改变
        if (comperData.length == compressImageData.length) {
            break;
        }
        
    } while (compressImageData.length >= targetLength);
    
    return compressImageData;
}

#pragma mark 图片尺寸压缩
- (UIImage *) imageCompressForTargetWidth:(CGFloat)defineWidth
{
    UIImage *newImage = nil;
    CGSize imageSize = self.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if(CGSizeEqualToSize(imageSize, size) == NO){
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth + 1; /** 加1 是为了去掉float类型精度差导致图片压缩后白边问题*/
    thumbnailRect.size.height = scaledHeight + 1;
    
    [self drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    
    return newImage;
}


+ (NSData *)imageDataFromAsset:(ALAssetRepresentation *)assetRepresentation
{
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc(sizeof(uint8_t)*[assetRepresentation size]);
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        free(buffer);
    }
    
    return data;
}

+ (UIImage *)imageThumbnailFromAsset:(ALAssetRepresentation *)assetRepresentation maxPixelSize:(NSUInteger)size
{
    NSData *data = [self imageDataFromAsset:assetRepresentation];
    
    UIImage *result = [self imageThumbnailFromData:data imageSize:size];
    
    return result;
}

+ (UIImage *)imageThumbnailFromData:(NSData *)data imageSize:(NSUInteger)imageSize
{
    UIImage *result = nil;
    if ([data length])
    {
        CGImageRef myThumbnailImage = MyCreateThumbnailImageFromData(data, (int)imageSize);
        if (myThumbnailImage) {
            result = [UIImage imageWithCGImage:myThumbnailImage];
            CGImageRelease(myThumbnailImage);
        }
    }
    
    return result;
}

CGImageRef MyCreateThumbnailImageFromData (NSData * data, int imageSize)
{
    CGImageRef        myThumbnailImage = NULL;
    CGImageSourceRef  myImageSource;
    CFDictionaryRef   myOptions = NULL;
    CFStringRef       myKeys[5];
    CFTypeRef         myValues[5];
    CFNumberRef       thumbnailSize;
    
    // Create an image source from NSData; no options.
    myImageSource = CGImageSourceCreateWithData((CFDataRef)data,
                                                NULL);
    // Make sure the image source exists before continuing.
    if (myImageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    
    // Package the integer as a  CFNumber object. Using CFTypes allows you
    // to more easily create the options dictionary later.
    thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
    
    // Set up the thumbnail options.
    myKeys[0] = kCGImageSourceCreateThumbnailWithTransform;
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    myKeys[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    myKeys[2] = kCGImageSourceThumbnailMaxPixelSize;
    myValues[2] = (CFTypeRef)thumbnailSize;
    myKeys[3] = kCGImageSourceShouldCache;
    myValues[3] = (CFTypeRef)kCFBooleanFalse;
    myKeys[4] = kCGImageSourceShouldCacheImmediately;
    myValues[4] = (CFTypeRef)kCFBooleanFalse;
    
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
                                   (const void **) myValues, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    
    // Create the thumbnail image using the specified options.
    myThumbnailImage = CGImageSourceCreateThumbnailAtIndex(myImageSource,
                                                           0,
                                                           myOptions);
    // Release the options dictionary and the image source
    // when you no longer need them.
    CFRelease(thumbnailSize);
    CFRelease(myOptions);
    CFRelease(myImageSource);
    
    // Make sure the thumbnail image exists before continuing.
    if (myThumbnailImage == NULL){
        fprintf(stderr, "Thumbnail image not created from image source.");
        return NULL;
    }
    
    return myThumbnailImage;
}


/** 设备分辨率 */
+ (CGSize)appPixel
{
    CGRect rect_screen = [[UIScreen mainScreen]bounds];
    CGSize size_screen = rect_screen.size;
    
    CGFloat scale_screen = [UIScreen mainScreen].scale;
    
    CGFloat width = size_screen.width*scale_screen;
    CGFloat height = size_screen.height*scale_screen;
    
    return CGSizeMake(width, height);
}
@end
