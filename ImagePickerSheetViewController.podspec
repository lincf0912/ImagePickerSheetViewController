Pod::Spec.new do |s|
s.name         = 'ImagePickerSheetViewController'
s.version      = '1.0'
s.summary      = 'image picker'
s.homepage     = 'https://github.com/lincf0912/ImagePickerSheetViewController'
s.license      = 'MIT'
s.author       = { 'lincf0912' => 'dayflyking@163.com' }
s.platform     = :ios
s.ios.deployment_target = '7.0'
s.source       = { :git => 'git@github.com:lincf0912/ImagePickerSheetViewController.git', :tag => s.version, :submodules => true }
s.requires_arc = true
s.resources    = 'ImagePickerSheet/ImagePickerSheetViewController/*.bundle'
s.source_files = 'ImagePickerSheet/ImagePickerSheetViewController/*.{h,m}'
s.public_header_files = 'ImagePickerSheet/ImagePickerSheetViewController/ImagePickerSheetViewController.h'
s.dependency 'LFImagePickerController'

end
