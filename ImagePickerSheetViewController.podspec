Pod::Spec.new do |s|
s.name         = 'ImagePickerSheetViewController'
s.version      = '1.1.3.1'
s.summary      = 'image picker'
s.homepage     = 'https://github.com/lincf0912/ImagePickerSheetViewController'
s.license      = 'MIT'
s.author       = { 'lincf0912' => 'dayflyking@163.com' }
s.platform     = :ios
s.ios.deployment_target = '7.0'
s.source       = { :git => 'https://github.com/lincf0912/ImagePickerSheetViewController.git', :tag => s.version, :submodules => true }
s.requires_arc = true
s.resources    = 'ImagePickerSheet/ImagePickerSheet/ImagePickerSheetViewController/*.bundle'
s.source_files = 'ImagePickerSheet/ImagePickerSheet/ImagePickerSheetViewController/*.{h,m}'
s.public_header_files = 'ImagePickerSheet/ImagePickerSheet/ImagePickerSheetViewController/ImagePickerSheetViewController.h'
s.dependency 'LFImagePickerController'

end
