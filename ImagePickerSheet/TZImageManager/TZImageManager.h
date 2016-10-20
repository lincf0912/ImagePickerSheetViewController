//
//  TZImageManager.h
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/4.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 *  NSString;
 */
extern NSString *const kImageInfoFileName;     // 图片名称
/**
 *  NSValue; CGSize size;[value getValue:&size];
 */
extern NSString *const kImageInfoFileSize;     // 图片大小［长、宽］
/**
 *  NSNumber;
 */
extern NSString *const kImageInfoFileByte;     // 图片大小［字节］

@class ALAssetsLibrary,TZAlbumModel,TZAssetModel;
@interface TZImageManager : NSObject

/**
 *  返回相册library
 *
 *  @return ALAssetsLibrary
 */
+ (ALAssetsLibrary *)assetLibrary;

/// Return YES if Authorized 返回YES如果得到了授权
+ (BOOL)authorizationStatusAuthorized;
/// Return Cache Path 返回压缩缓存视频路径
+ (NSString *)CacheVideoPath;

/** 清空视频缓存 */
+ (BOOL)cleanCacheVideoPath;

/**
 *  @author lincf, 16-07-28 17:07:38
 *
 *  Get Album 获得相册/相册数组
 *
 *  @param allowPickingVideo 是否包含视频
 *  @param fetchLimit        相片最大数量（IOS8之后有效）
 *  @param ascending         顺序获取（IOS8之后有效）
 *  @param completion        回调结果
 */
+ (void)getCameraRollAlbum:(BOOL)allowPickingVideo fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(TZAlbumModel *model))completion;
/// Get Album 获得相册/相册数组
+ (void)getCameraRollAlbum:(BOOL)allowPickingVideo completion:(void (^)(TZAlbumModel *model))completion;
+ (void)getAllAlbums:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAlbumModel *> *models))completion;

/**
 *  @author lincf, 16-07-28 13:07:27
 *
 *  Get Assets 获得Asset数组
 *
 *  @param result            TZAlbumModel.result
 *  @param allowPickingVideo 是否包含视频
 *  @param fetchLimit        相片最大数量
 *  @param ascending         顺序获取
 *  @param completion        回调结果
 */
+ (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(NSArray<TZAssetModel *> *models))completion;
/// Get Assets 获得Asset数组
+ (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(NSArray<TZAssetModel *> *models))completion;
+ (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo completion:(void (^)(TZAssetModel *model))completion;

/// Get photo 获得照片
+ (void)getPostImageWithAlbumModel:(TZAlbumModel *)model completion:(void (^)(UIImage *postImage))completion;
+ (void)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
+ (void)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;

/**
 *  通过asset解析缩略图、标清图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
+ (void)getPreviewPhotoWithAsset:(id)asset completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion;
/**
 *  通过asset解析缩略图、原图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
+ (void)getOriginPhotoWithAsset:(id)asset completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion;

/// Get video 获得视频
+ (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * playerItem, NSDictionary * info))completion;

/**
 *  @author lincf, 16-06-15 13:06:26
 *
 *  视频压缩并缓存压缩后视频 (将视频格式变为mp4) 需要SCRecorder框架
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 回调压缩后视频路径，可以复制或剪切
 */
//+ (void)compressAndCacheVideoWithAsset:(id)asset completion:(void (^)(NSString *path))completion;

/// Get photo bytes 获得一组照片的大小
+ (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion;

/** Get photo size 获取一张图片的大小 长&宽 */
+ (CGSize)getPhotoSize:(id)asset;

/** Get AVPlayer URL */
+ (NSURL *)getURLInPlayer:(AVPlayer *)player;

/**
 *  @author djr
 *  
 *  保存图片到自定义相册
 *  @param title 自定义相册名称（不能为空）
 *  @param saveImage 图片
 *  @param complete 成功
 *  @param failer 失败
 */
+ (void) saveImageToCustomPhotosAlbumWithTitle:(NSString *)title image:(UIImage *)saveImage complete:(void(^)(id asset, NSError *error))complete;
@end
