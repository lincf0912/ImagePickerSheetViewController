//
//  ImagePickerSheetViewController.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/7.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LFImagePickerController/LFImagePickerPublicHeader.h>

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
/** 显示相册数量，默认20，设置0为全部 */
@property (nonatomic, assign) NSUInteger fetchLimit;

/** 使用内置相册回调->设置属性 */
@property (nonatomic, copy) void (^photoLabrary)(LFImagePickerController *lf_imagePicker);
/** 销毁回调 */
@property (nonatomic, copy) void (^dismissBlock)();

- (void)showImagePickerInController:(UIViewController *)controller animated:(BOOL)animated;

@end
