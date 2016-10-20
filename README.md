# ImagePickerSheetViewController
模仿IOS8的图片选择器

# 调用代码
ImagePickerSheetViewController *imagePicker = [[ImagePickerSheetViewController alloc] init];
    [imagePicker showImagePickerInController:self animated:YES];

设置代理方法，按钮实现

imagePicker.delegate;

强烈推荐实现 imagePickerSheetViewControllerOpenPhtotLabrary 代理 使用TZImagePickerController代替原生相册 效果更佳



![image](https://github.com/lincf0912/ImagePickerSheetViewController/raw/master/screenshots/screenshot.png)

![image](https://github.com/lincf0912/ImagePickerSheetViewController/raw/master/screenshots/screenshot.gif)
