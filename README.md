# ImagePickerSheetViewController

* 模仿IOS8的图片选择器 项目依赖 https://github.com/lincf0912/LFImagePickerController 项目运行

## Installation 安装

* CocoaPods：pod 'ImagePickerSheetViewController'
* 手动导入：将ImagePickerSheet\ImagePickerSheetViewController文件夹拽入项目中，导入头文件：#import "LFPhotoBrowser.h"，依赖LFImagePickerController

## 调用代码

* ImagePickerSheetViewController *imagePicker = [[ImagePickerSheetViewController alloc] init];
    [imagePicker showImagePickerInController:self animated:YES];
* [imagePicker showImagePickerInController:self animated:YES];

* 设置代理方法，按钮实现
* imagePicker.delegate;

## 图片展示

![image](https://github.com/lincf0912/ImagePickerSheetViewController/raw/master/screenshots/screenshot.png)

![image](https://github.com/lincf0912/ImagePickerSheetViewController/raw/master/screenshots/screenshot.gif)
