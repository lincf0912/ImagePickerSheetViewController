//
//  ImagePickerSheetViewController.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/7.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  NSString;
 */
extern NSString *const kImageInfoFileName;     // 图片名称
/**
 *  NSValue; CGSize size;[value getValue:&size];
 */
extern NSString *const kImageInfoFileSize;     // 图片大小［长、宽］
/**
 *  NSNumber(CGFloat);
 */
extern NSString *const kImageInfoFileByte;     // 图片大小［字节］
/**
 *  NSData;
 */
extern NSString *const kImageInfoFileOriginalData;     // 图片数据 原图
extern NSString *const kImageInfoFileThumnailData;     // 图片数据 缩略图
/**
 *  NSNumber(BOOL);
 */
extern NSString *const kImageInfoIsGIF;     // 是否GIF


@class ImagePickerSheetViewController, LFImagePickerController;

@protocol ImagePickerSheetViewControllerDelegate <NSObject>
@optional
/** 发送(直接回调PHAsset或ALAsset对象) */
- (void)imagePickerSheetViewControllerAssets:(NSArray *)assets;

/** 发送2（compressImgs缩略图组，originalImgs原图组或者标清）注：也可以实现imagePickerSheetVCSendImageBlock回调 */
- (void)imagePickerSheetViewControllerThumbnailImages:(NSArray <UIImage *>*)compressImgs originalImages:(NSArray <UIImage *>*)originalImgs;
- (void)imagePickerSheetViewControllerThumbnailImages:(NSArray <UIImage *>*)compressImgs originalImages:(NSArray <UIImage *>*)originalImgs infos:(NSArray<NSDictionary *> *)infos;

/** 拍照发送 注：也可以实现imagePickerSheetVCPhotoSendImageBlock回调*/
- (void)imagePickerSheetViewControllerPhotoImage:(UIImage *)image;
/** 相册 */
- (void)imagePickerSheetViewControllerOpenPhotoLabrary;
/** 拍照 */
- (void)imagePickerSheetViewControllerTakePhoto;
/** 超过最大选择 */
- (void)imagePickerSheetViewControllerDidMaximum:(NSInteger)maximum;
@end

@interface ImagePickerSheetViewController : UIViewController

/** 首次显示缩放动画 默认NO */
@property (nonatomic, assign) BOOL zoomAnimited;

@property (nonatomic, assign) id <ImagePickerSheetViewControllerDelegate> delegate;

@property (nonatomic, copy) void(^imagePickerSheetVCSendAssetBlock)(NSArray *assets);
/** 发送图片block，回调回两组数组，一组压缩图片数组，一组原图数组 */
@property (nonatomic, copy) void(^imagePickerSheetVCSendImageBlock)(NSArray <UIImage *>*thumbnailImages, NSArray <UIImage *>*originalImages);
@property (nonatomic, copy) void(^imagePickerSheetVCSendImageWithInfoBlock)(NSArray <UIImage *>*thumbnailImages, NSArray <UIImage *>*originalImages, NSArray<NSDictionary *> *infos);
/** 拍照发送，回调回图片 */
@property (nonatomic, copy) void (^imagePickerSheetVCPhotoSendImageBlock)(UIImage *image);
/** 最大选择数量 */
@property (nonatomic, assign) NSInteger maximumNumberOfSelection;

/** 使用内置相册回调->设置属性 */
@property (nonatomic, copy) void (^photoLabrary)(LFImagePickerController *lf_imagePicker);
/** 销毁回调 */
@property (nonatomic, copy) void (^dismissBlock)();

- (void)showImagePickerInController:(UIViewController *)controller animated:(BOOL)animated;

@end
