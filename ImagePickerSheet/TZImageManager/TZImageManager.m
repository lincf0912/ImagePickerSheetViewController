//
//  TZImageManager.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/4.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZImageManager.h"
#import "TZAssetModel.h"
#import "UIImage+Compress.h"
#import "UIImage+Addition.h"

#import "DefineHeader.h"

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}


NSString *const kImageInfoFileName = @"ImageInfoFileName";     // 图片名称
NSString *const kImageInfoFileSize = @"ImageInfoFileSize";     // 图片大小［长、宽］
NSString *const kImageInfoFileByte = @"ImageInfoFileByte";     // 图片大小［字节］

@interface TZImageManager ()

@end

@implementation TZImageManager

+ (ALAssetsLibrary *)assetLibrary
{
    static ALAssetsLibrary *library = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

/// Return YES if Authorized 返回YES如果得到了授权
+ (BOOL)authorizationStatusAuthorized {
    if (IOS8_OR_LATER) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) return YES;
    } else {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) return YES;
    }
    return NO;
}

/// Return Cache Path
+ (NSString *)CacheVideoPath
{
    NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
    NSString *fullNamespace = [bundleId stringByAppendingPathComponent:@"videoCache"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths.firstObject stringByAppendingPathComponent:fullNamespace];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cachePath]) {
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cachePath;
}

+ (BOOL)cleanCacheVideoPath
{
    NSString *path = [self CacheVideoPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager removeItemAtPath:path error:nil];
}

#pragma mark - Get Album

/// Get Album 获得相册/相册数组
+ (void)getCameraRollAlbum:(BOOL)allowPickingVideo fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(TZAlbumModel *))completion
{
    __block TZAlbumModel *model;
    if (IOS8_OR_LATER) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
        if (IOS9_OR_LATER) {
            option.fetchLimit = fetchLimit;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                model = [self modelWithResult:fetchResult name:collection.localizedTitle];
                if (completion) completion(model);
                break;
            }
        }
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            ALAssetsGroupType type = [[group valueForProperty:ALAssetsGroupPropertyType] integerValue];
            if (type == ALAssetsGroupSavedPhotos) {
                model = [self modelWithResult:group name:name];
                if (completion) completion(model);
                *stop = YES;
            }
        } failureBlock:nil];
    }
}
+ (void)getCameraRollAlbum:(BOOL)allowPickingVideo completion:(void (^)(TZAlbumModel *))completion{
    
    [self getCameraRollAlbum:allowPickingVideo fetchLimit:0 ascending:YES completion:completion];
}

+ (void)getAllAlbums:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAlbumModel *> *))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    if (IOS8_OR_LATER) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
        // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
        if (IOS9_OR_LATER) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        
        for (PHAssetCollection *collection in smartAlbums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
        }
        if (completion && albumArr.count > 0) completion(albumArr);
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            ALAssetsGroupType type = [[group valueForProperty:ALAssetsGroupPropertyType] integerValue];
            if (type == ALAssetsGroupSavedPhotos) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
            } else if (type == ALAssetsGroupPhotoStream) {
                if (albumArr.count > 0) {
                    [albumArr insertObject:[self modelWithResult:group name:name] atIndex:1];
                } else {
                    [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
                }
            } else {
                [albumArr addObject:[self modelWithResult:group name:name]];
            }
        } failureBlock:nil];
    }
}

#pragma mark - Get Assets
+ (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(NSArray<TZAssetModel *> *))completion
{
    NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        NSUInteger count = fetchResult.count;
        
        NSInteger start = 0;
        if (fetchLimit > 0 && ascending == NO) { /** 重置起始值 */
            start = count > fetchLimit ? count - fetchLimit : 0;
        }
        
        NSInteger end = count;
        if (fetchLimit > 0 && ascending) { /** 重置结束值 */
            end = count > fetchLimit ? fetchLimit : count;
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, end)];
        NSArray *results = [fetchResult objectsAtIndexes:indexSet];
        
        for (PHAsset *asset in results) {
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            if (asset.mediaType == PHAssetMediaTypeVideo)      type = TZAssetModelMediaTypeVideo;
            else if (asset.mediaType == PHAssetMediaTypeAudio) type = TZAssetModelMediaTypeAudio;
            else if (asset.mediaType == PHAssetMediaTypeImage) {
//                if (iOS9_1Later) {
//                     if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = TZAssetModelMediaTypeLivePhoto;
//                }
            }
            NSString *timeLength = type == TZAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
            timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
            
            TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:type timeLength:timeLength];
            if (ascending) {
                [photoArr addObject:model];
            } else {
                [photoArr insertObject:model atIndex:0];
            }
        }
        if (completion) completion(photoArr);

    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if (!allowPickingVideo) [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        ALAssetsGroupEnumerationResultsBlock resultBlock = ^(id obj, NSUInteger idx, BOOL *stop)
        {
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            NSString *timeLength = @"";
            /// Allow picking video
            if (allowPickingVideo && [[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = TZAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                timeLength = [self getNewTimeFromDurationSecond:[[NSString stringWithFormat:@"%0.0f",duration] integerValue]];
            }
            
            TZAssetModel *model = [TZAssetModel modelWithAsset:result type:type timeLength:timeLength];
            if (ascending) {
                [photoArr insertObject:model atIndex:0];
            } else {
                [photoArr addObject:model];
            }
            
            if (fetchLimit > 0 && photoArr.count == fetchLimit) {
                *stop = YES;
            }
            
        };
        
        NSUInteger count = group.numberOfAssets;
        
        NSInteger start = 0;
        if (fetchLimit > 0 && ascending == NO) { /** 重置起始值 */
            start = count > fetchLimit ? count - fetchLimit : 0;
        }
        
        NSInteger end = count;
        if (fetchLimit > 0 && ascending) { /** 重置结束值 */
            end = count > fetchLimit ? fetchLimit : count;
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, end)];
        [group enumerateAssetsAtIndexes:indexSet options:NSEnumerationReverse usingBlock:resultBlock];
        
        if (completion) completion(photoArr);
    }
}

/// Get Assets 获得照片数组
+ (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAssetModel *> *))completion {
    [self getAssetsFromFetchResult:result allowPickingVideo:allowPickingVideo fetchLimit:0 ascending:YES completion:completion];
}

///  Get asset at index 获得下标为index的单个照片
+ (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(TZAssetModel *))completion {
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        PHAsset *asset = fetchResult[index];
        
        TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
        if (asset.mediaType == PHAssetMediaTypeVideo)      type = TZAssetModelMediaTypeVideo;
        else if (asset.mediaType == PHAssetMediaTypeAudio) type = TZAssetModelMediaTypeAudio;
        else if (asset.mediaType == PHAssetMediaTypeImage) {
//            if (iOS9_1Later) {
//                 if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = TZAssetModelMediaTypeLivePhoto;
//            }
        }
        NSString *timeLength = type == TZAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        TZAssetModel *model = [TZAssetModel modelWithAsset:asset type:type timeLength:timeLength];
        if (completion) completion(model);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        if (!allowPickingVideo) [gruop setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [gruop enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            TZAssetModel *model;
            TZAssetModelMediaType type = TZAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                model = [TZAssetModel modelWithAsset:result type:type];
                if (completion) completion(model);
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = TZAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                model = [TZAssetModel modelWithAsset:result type:type timeLength:timeLength];
            } else {
                model = [TZAssetModel modelWithAsset:result type:type];
            }
            if (completion) completion(model);
        }];
    }
}

+ (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/// Get photo bytes 获得一组照片的大小
+ (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    __block NSInteger count = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        TZAssetModel *model = photos[i];
        if ([model.asset isKindOfClass:[PHAsset class]]) {
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if (model.type != TZAssetModelMediaTypeVideo) dataLength += imageData.length;
                count ++;
                if (count >= photos.count - 1) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    if (completion) completion(bytes);
                }
            }];
        } else if ([model.asset isKindOfClass:[ALAsset class]]) {
            ALAssetRepresentation *representation = [model.asset defaultRepresentation];
            if (model.type != TZAssetModelMediaTypeVideo) dataLength += (NSInteger)representation.size;
            if (i >= photos.count - 1) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion) completion(bytes);
            }
        }
    }
}

+ (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

#pragma mark - Get Photo

/// Get photo 获得照片本身
+ (void)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    [self getPhotoWithAsset:asset photoWidth:[UIScreen mainScreen].bounds.size.width completion:completion];
}

+ (void)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat multiple = [UIScreen mainScreen].scale;
        CGFloat pixelWidth = photoWidth * multiple;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(pixelWidth, pixelHeight) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined) {
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;
        UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
        if (completion) completion(thumbnailImage,nil,YES);
        
        if (photoWidth == [UIScreen mainScreen].bounds.size.width) {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:1.0 orientation:UIImageOrientationUp];
                
                dispatch_main_async_safe(^{
                    if (completion) completion(fullScrennImage,nil,NO);
                });
            });
        }
    }
}

+ (void)getPreviewPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, UIImage *, NSDictionary *))completion
{
    CGSize size = CGSizeZero;
    [self getPhotoWithAsset:asset size:size completion:^(UIImage *thumbnail, UIImage *source, NSMutableDictionary *info) {
        thumbnail = [thumbnail fastestCompressImageWithSize:10];
        
        NSData *sourceData = [source fastestCompressImageDataWithSize:100];
        source = [UIImage imageWithData:sourceData];
        /** 图片宽高 */
        CGSize imageSize = source.size;
        NSValue *value = [NSValue valueWithBytes:&imageSize objCType:@encode(CGSize)];
        [info setObject:value forKey:kImageInfoFileSize];
        /** 图片大小 */
        [info setObject:@(sourceData.length) forKey:kImageInfoFileByte];
        
        if (completion) {
            completion(thumbnail, source, info);
        }
    }];
}

+ (void)getOriginPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, UIImage *, NSDictionary *))completion
{
    [self getPhotoWithAsset:asset size:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) completion:^(UIImage *thumbnail, UIImage *source, NSMutableDictionary *info) {
        thumbnail = [thumbnail fastestCompressImageWithSize:10];
        /** 图片宽高 */
        CGSize imageSize = source.size;
        NSValue *value = [NSValue valueWithBytes:&imageSize objCType:@encode(CGSize)];
        [info setObject:value forKey:kImageInfoFileSize];
        
        if (completion) {
            completion(thumbnail, source, info);
        }
    }];
}

+ (void)getPhotoWithAsset:(id)asset size:(CGSize)size completion:(void (^)(UIImage *, UIImage *, NSMutableDictionary *))completion
{
    __block UIImage *thumbnail = nil;
    __block UIImage *source = nil;
    NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
    
    BOOL isMaxSize = CGSizeEqualToSize(size, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX));
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat multiple = [UIScreen mainScreen].scale;
        CGFloat th_pixelWidth = 80 * multiple;
        CGFloat th_pixelHeight = th_pixelWidth / aspectRatio;
        
        /** 缩略图 */
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(th_pixelWidth, th_pixelHeight) contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]&& ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined) {
                
                thumbnail = [result fixOrientation];
                if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
            }
        }];
        if (isMaxSize) {
            size = PHImageManagerMaximumSize;
        } else {
            CGFloat pixelWidth = [UIScreen mainScreen].bounds.size.width * 0.5 * multiple;
            CGFloat pixelHeight = pixelWidth / aspectRatio;
            size = CGSizeMake(pixelWidth, pixelHeight);
        }
        /** 标清图／原图 */
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]&& ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined) {
                
                source = [result fixOrientation];
                
                if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
            }
        }];
        
        /** 图片文件名+图片大小 */
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            /** 图片大小 */
            [imageInfo setObject:@(imageData.length) forKey:kImageInfoFileByte];
            
            NSURL *fileUrl = [info objectForKey:@"PHImageFileURLKey"];
            if (fileUrl) {
                [imageInfo setObject:fileUrl.lastPathComponent forKey:kImageInfoFileName];
            } else {
                [imageInfo setObject:[NSNull null] forKey:kImageInfoFileName];
            }
            if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
        }];
        
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;/** 缩略图 */
        thumbnail = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
        thumbnail = [thumbnail fixOrientation];
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            
            if (isMaxSize) {
                CGImageRef fullResolutionImageRef = [assetRep fullResolutionImage]; /** 原图 */
                // 通过 fullResolutionImage 获取到的的高清图实际上并不带上在照片应用中使用“编辑”处理的效果，需要额外在 AlAssetRepresentation 中获取这些信息
                NSString *adjustment = [[assetRep metadata] objectForKey:@"AdjustmentXMP"];
                if (adjustment) {
                    // 如果有在照片应用中使用“编辑”效果，则需要获取这些编辑后的滤镜，手工叠加到原图中
                    NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
                    CIImage *tempImage = [CIImage imageWithCGImage:fullResolutionImageRef];
                    
                    NSError *error;
                    NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                                 inputImageExtent:tempImage.extent
                                                                            error:&error];
                    CIContext *context = [CIContext contextWithOptions:nil];
                    if (filterArray && !error) {
                        for (CIFilter *filter in filterArray) {
                            [filter setValue:tempImage forKey:kCIInputImageKey];
                            tempImage = [filter outputImage];
                        }
                        fullResolutionImageRef = [context createCGImage:tempImage fromRect:[tempImage extent]];
                    }
                }
                // 生成最终返回的 UIImage，同时把图片的 orientation 也补充上去
                source = [UIImage imageWithCGImage:fullResolutionImageRef scale:[assetRep scale] orientation:(UIImageOrientation)[assetRep orientation]];
            } else {
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage]; /** 标清图 */
                source = [UIImage imageWithCGImage:fullScrennImageRef scale:1.0 orientation:UIImageOrientationUp];
            }
            source = [source fixOrientation];
            
            NSString *fileName = assetRep.filename;
            if (fileName.length) {
                [imageInfo setObject:fileName forKey:kImageInfoFileName];
            }
            
            /** 相册没有生成缩略图 */
            if (thumbnail == nil) {
                thumbnail = source;
            }
            
            dispatch_main_async_safe(^{
                if (completion) completion(thumbnail, source, imageInfo);
            });
        });
    }
}


+ (void)getPostImageWithAlbumModel:(TZAlbumModel *)model completion:(void (^)(UIImage *))completion {
    if (IOS8_OR_LATER) {
        [TZImageManager getPhotoWithAsset:[model.result lastObject] photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completion) completion(photo);
        }];
    } else {
        ALAssetsGroup *gruop = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:gruop.posterImage];
        if (completion) completion(postImage);
    }
}

#pragma mark - Get Video
+ (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion) completion(playerItem,info);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem) completion(playerItem,nil);
    }
}

//+ (void)compressAndCacheVideoWithAsset:(id)asset completion:(void (^)(NSString *path))completion
//{
//    if (completion == nil) return;
//    NSString *cache = [self CacheVideoPath];
//    if ([asset isKindOfClass:[PHAsset class]]) {
//        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
//            if ([asset isKindOfClass:[AVURLAsset class]]) {
//                NSURL *url = ((AVURLAsset *)asset).URL;
//                if (url) {
//                    NSString *videoName = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingString:@".mp4"];
//                    NSString *path = [cache stringByAppendingPathComponent:videoName];
//                    [SCRecorder compressVideoWithAsset:(AVURLAsset *)asset outPath:path delegate:nil completion:^(NSString *outputUrl, NSError *error) {
//                        if (error) {
//                            completion(nil);
//                        }else{
//                            completion(outputUrl);
//                        }
//                    }];
//                } else {
//                    completion(nil);
//                }
//            } else {
//                completion(nil);
//            }
//        }];
//    } else if ([asset isKindOfClass:[ALAsset class]]) {
//        ALAssetRepresentation *rep = [asset defaultRepresentation];
//        NSString *videoName = [rep filename];
//        NSURL *videoURL = [rep url];
//        if (videoName.length && videoURL) {
//            NSString *path = [cache stringByAppendingPathComponent:videoName];
//            [SCRecorder compressVideoWithFileURL:videoURL outPath:path delegate:nil completion:^(NSString *outputUrl, NSError *error) {
//                if (error) {
//                    completion(nil);
//                }else{
//                    completion(outputUrl);
//                }
//            }];
//        } else {
//            completion(nil);
//        }
//    }else{
//        completion(nil);
//    }
//}

#pragma mark - Get Size
+ (CGSize)getPhotoSize:(id)asset
{
    CGSize size = CGSizeZero;
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat width = 80;
        size = CGSizeMake(width, width/aspectRatio);
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        size = [[asset defaultRepresentation] dimensions];
    }
    return size;
}

+ (NSURL *)getURLInPlayer:(AVPlayer *)player
{
    // get current asset
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}

#pragma mark - Private Method

+ (TZAlbumModel *)modelWithResult:(id)result name:(NSString *)name{
    TZAlbumModel *model = [[TZAlbumModel alloc] init];
    model.result = result;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        model.count = fetchResult.count;
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *gruop = (ALAssetsGroup *)result;
        model.count = [gruop numberOfAssets];
    }
    return model;
}

+ (NSString *)getNewAlbumName:(NSString *)name {
    if (IOS8_OR_LATER) {
        NSString *newName;
        if ([name containsString:@"Roll"])         newName = @"相机胶卷";
        else if ([name containsString:@"Stream"])  newName = @"我的照片流";
        else if ([name containsString:@"Added"])   newName = @"最近添加";
        else if ([name containsString:@"Selfies"]) newName = @"自拍";
        else if ([name containsString:@"shots"])   newName = @"截屏";
        else if ([name containsString:@"Videos"])  newName = @"视频";
        else newName = name;
        return newName;
    } else {
        return name;
    }
}

+ (void)createCustomAlbumWithTitle:(NSString *)title complete:(void (^)(PHAssetCollection *result))complete faile:(void (^)(NSError *error))faile{
    if (title.length == 0) {
        if (complete) complete(nil);
    }else{
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            // 是否存在相册 如果已经有了 就不再创建
            PHFetchResult <PHAssetCollection *> *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            BOOL haveHDRGroup = NO;
            NSError *error = nil;
            PHAssetCollection *createCollection = nil;
            for (PHAssetCollection *collection in results) {
                if ([collection.localizedTitle isEqualToString:title]) {
                    /** 已经存在了，不需要创建了 */
                    haveHDRGroup = YES;
                    createCollection = collection;
                    break;
                }
            }
            if (haveHDRGroup) {
                NSLog(@"已经存在了，不需要创建了");
                dispatch_main_async_safe(^{
                    if (complete) complete(createCollection);
                });
            }else{
                __block NSString *createdCustomAssetCollectionIdentifier = nil;
                /**
                 * 注意：这个方法只是告诉 photos 我要创建一个相册，并没有真的创建
                 *      必须等到 performChangesAndWait block 执行完毕后才会
                 *      真的创建相册。
                 */
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
                    /**
                     * collectionChangeRequest 即使我们告诉 photos 要创建相册，但是此时还没有
                     * 创建相册，因此现在我们并不能拿到所创建的相册，我们的需求是：将图片保存到
                     * 自定义的相册中，因此我们需要拿到自己创建的相册，从头文件可以看出，collectionChangeRequest
                     * 中有一个占位相册，placeholderForCreatedAssetCollection ，这个占位相册
                     * 虽然不是我们所创建的，但是其 identifier 和我们所创建的自定义相册的 identifier
                     * 是相同的。所以想要拿到我们自定义的相册，必须保存这个 identifier，等 photos app
                     * 创建完成后通过 identifier 来拿到我们自定义的相册
                     */
                    createdCustomAssetCollectionIdentifier = collectionChangeRequest.placeholderForCreatedAssetCollection.localIdentifier;
                } error:&error];
                if (error) {
                    NSLog(@"创建了%@相册失败",title);
                    dispatch_main_async_safe(^{
                        if (faile) faile(error);
                    });
                }else{
                    /** 获取创建成功的相册 */
                    createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCustomAssetCollectionIdentifier] options:nil].firstObject;
                    NSLog(@"创建了%@相册成功",title);
                    dispatch_main_async_safe(^{
                        if (complete) complete(createCollection);
                    });
                }
            }
        });
    }
}

#pragma mark - 保存图片到自定义相册
+ (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title image:(UIImage *)saveImage complete:(void (^)(id ,NSError *))complete{
    if (IOS8_OR_LATER) {
        [TZImageManager createCustomAlbumWithTitle:title complete:^(PHAssetCollection *result) {
            [TZImageManager saveToAlbumIOS7LaterWithImage:saveImage customAlbum:result completionBlock:^(PHAsset *asset) {
                if (complete) complete(asset, nil);
            } failureBlock:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
        } faile:^(NSError *error) {
            if (complete) complete(nil, error);
        }];
    }else{
        /** iOS7之前保存图片到自定义相册方法 */
        [TZImageManager saveToAlbumImageData:saveImage customAlbumName:title completionBlock:^(ALAsset *asset) {
            if (complete) complete(asset, nil);
        } failureBlock:^(NSError *error) {
            if (complete) complete(nil, error);
        }];
    }
}


#pragma mark - iOS7之后保存相片到自定义相册
+ (void)saveToAlbumIOS7LaterWithImage:(UIImage *)image 
                 customAlbum:(PHAssetCollection *)customAlbum 
             completionBlock:(void(^)(PHAsset *asset))completionBlock 
                failureBlock:(void (^)(NSError *error))failureBlock
{
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        __block NSError *error = nil;
        PHAssetCollection *assetCollection = (PHAssetCollection *)customAlbum;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            PHObjectPlaceholder *placeholder = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
//            [request addAssets:@[placeholder]]; 
            //将最新保存的图片设置为封面
            [request insertAssets:@[placeholder] atIndexes:[NSIndexSet indexSetWithIndex:0]];
        } error:&error];
        
        if (error) {
            NSLog(@"保存失败");
            dispatch_main_async_safe(^{
                if (failureBlock) failureBlock(error);
            });
        } else {
            NSLog(@"保存成功");
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            if (IOS9_OR_LATER) {
                options.fetchLimit = 1;
            }
            /** 获取相册 */
            PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            dispatch_main_async_safe(^{
                if (completionBlock) completionBlock([assets firstObject]);
            });
            /** 返回保存对象 */
        } 
    });
}

#pragma mark - iOS7之前保存相片到自定义相册
+ (void)saveToAlbumImageData:(UIImage *)image
             customAlbumName:(NSString *)customAlbumName
             completionBlock:(void (^)(ALAsset *asset))completionBlock
                failureBlock:(void (^)(NSError *error))failureBlock
{
    
    ALAssetsLibrary *assetsLibrary = [TZImageManager assetLibrary];
    /** 循环引用处理 */
    __weak ALAssetsLibrary *weakAssetsLibrary = assetsLibrary;
    void (^AddAsset)(ALAsset *) = ^(ALAsset *asset) {
        [weakAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupLibrary usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:customAlbumName]) {
                NSLog(@"保存相片成功");
                [group addAsset:asset];
                if (completionBlock) {
                    completionBlock(asset);
                }
                *stop = YES;
            }
            /** done */
            else if (group == nil) {
                if (completionBlock) {
                    completionBlock(asset);
                }
            }
        } failureBlock:^(NSError *error) {
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    };
    
    /** 保存图片到系统相册，因为系统的 album 相当于一个 music library, 而自己的相册相当于一个 playlist, 你的 album 所有的内容必须是链接到系统相册里的内容的. */
    [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            failureBlock(error);
        } else {
            /** 获取当前保存图片的asset */
            [weakAssetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                if (customAlbumName.length) {
                    /** 添加自定义相册 */
                    [weakAssetsLibrary addAssetsGroupAlbumWithName:customAlbumName resultBlock:^(ALAssetsGroup *group) {
                        if (group) {
                            [group addAsset:asset];
                            NSLog(@"保存相片成功");
                            if (completionBlock) {
                                completionBlock(asset);
                            }
                        } else { /** 相册已存在 */
                            /** 找到已创建相册，保存图片 */
                            AddAsset(asset);
                        }
                    } failureBlock:^(NSError *error) {
                        NSLog(@"%@",error.localizedDescription);
                        /** 创建失败，直接回调图片 */
                        if (completionBlock) {
                            completionBlock(asset);
                        }
                    }];
                } else {
                    if (completionBlock) {
                        completionBlock(asset);
                    }
                }
            } failureBlock:^(NSError *error) {
                NSLog(@"%@",error.localizedDescription);
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        }
    }];
}

@end
