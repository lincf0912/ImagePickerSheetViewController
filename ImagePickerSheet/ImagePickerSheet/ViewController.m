//
//  ViewController.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/7.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ViewController.h"
#import "ImagePickerSheetViewController.h"
#import "LFAssetManager.h"
#import "LFImagePickerController.h"

@interface ViewController () <ImagePickerSheetViewControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /** 单击的 Recognizer */
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed:)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    /** 给view添加一个手势监测 */
    singleTapRecognizer.enabled = YES;
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    /** 触发允许使用照片 */
    [[LFAssetManager manager].assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                                 usingBlock:nil
                                               failureBlock:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    singleTapRecognizer.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    singleTapRecognizer.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)singlePressed:(UITapGestureRecognizer *)sender
{
    NSLog(@"启动图片选择器");
    ImagePickerSheetViewController *imagePicker = [[ImagePickerSheetViewController alloc] init];
    imagePicker.delegate = self;
    imagePicker.zoomAnimited = YES;
    imagePicker.photoLabrary = ^(LFImagePickerController *lf_imagePicker) {
//        lf_imagePicker.allowTakePicture = NO;
//        lf_imagePicker.allowPickingVideo = NO;
        lf_imagePicker.doneBtnTitleStr = @"发送";
    };
    [imagePicker showImagePickerInController:self animated:YES];
}

//- (void)imagePickerSheetViewControllerOpenPhotoLabrary
//{
//    NSLog(@"打开第三方框架");
//}

- (void)imagePickerSheetViewControllerResultImages:(NSArray <LFResultObject *>*)resultImages
{
    
}
/** 取消 */
- (void)imagePickerSheetViewControllerDidCancel:(ImagePickerSheetViewController *)imagePickerSheet
{
    
}

@end
