# LFImagePickerController

* 项目UI与资源方面部分使用TZImagePickerController项目，感谢分享。
* 兼容非系统相册的调用方式
* 支持Gif（压缩）、视频（压缩）、图片（压缩）
* 图片编辑、视频编辑（依赖LFMediaEditingController库，默认没有编辑功能）
* 视频编辑 需要访问音乐库 需要在info.plist 添加 NSAppleMusicUsageDescription
* 支持iPhone、iPad 横屏
* 支持国际化配置（复制LFImagePickerController.bundle\LFImagePickerController.strings到项目中，修改对应的值即可；详情见DEMO；注意：不跟随系统语言切换显示）
* 详细使用见LFImagePickerController.h 的初始化方法

## iOS13的modalPresentationStyle使用

* 设置imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;即可使用全屏。
* 如果想使用默认的模式imagePicker.modalPresentationStyle = UIModalPresentationAutomatic;界面被下拉收起时不会触发框架的代码方法。需要调用者在presentViewController:animated:completion:方法之前，增加一行imagePicker.presentationController.delegate = self;实现UIAdaptivePresentationControllerDelegate协议的presentationControllerDidDismiss:方法即可。
* 为什么框架不内部实现？presentationController属性会根据modalPresentationStyle的类型来创建不同的类。所以初始化时不能调用，否则modalPresentationStyle的设置将会被忽略。ViewDidiLoad时调用presentationController会产生双向强持有关系。导致无法释放。而presentationController属性是readOnly，手动打破僵局也不行。

## Installation 安装

* CocoaPods：pod 'LFImagePickerController' 或 pod 'LFImagePickerController/LFMediaEdit' (带图片编辑功能)
* 手动导入：将LFImagePickerController\class文件夹拽入项目中，导入头文件：#import "LFImagePickerController.h"

## Demo配置编辑功能（不用编辑功能可以忽略）

* 使用pod install安装LFMediaEditingController库
* 在LFImagePickerController的project --> Build Settings --> 搜索Preprocessor Macros --> 在Debug与Release添加LF_MEDIAEDIT=1

## 调用代码

* LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
* //根据需求设置
* imagePicker.allowTakePicture = NO;  //不显示拍照按钮
* imagePicker.doneBtnTitleStr = @"发送"; //最终确定按钮名称
* [self presentViewController:imagePicker animated:YES completion:nil];

## 图片展示

![image](https://github.com/lincf0912/LFImagePickerController/blob/master/ScreenShots/screenshot.gif)
