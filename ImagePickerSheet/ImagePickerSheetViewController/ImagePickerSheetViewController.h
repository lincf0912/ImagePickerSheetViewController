//
//  ImagePickerSheetViewController.h
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/7.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImagePickerSheetViewController;

@protocol ImagePickerSheetViewControllerDelegate <NSObject>
/** 发送 */
- (void)imagePickerSheetViewController:(ImagePickerSheetViewController *)imagePickerSheetVC image:(UIImage *)image;
@end

@interface ImagePickerSheetViewController : UIViewController

@property (nonatomic, assign) id <ImagePickerSheetViewControllerDelegate> delegate;

- (void)showImagePickerInController:(UIViewController *)controller animated:(BOOL)animated;

@end
