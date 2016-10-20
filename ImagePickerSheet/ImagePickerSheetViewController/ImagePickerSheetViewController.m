//
//  ImagePickerSheetViewController.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/7.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ImagePickerSheetViewController.h"
#import "ImagePickerCollectionView.h"
#import "ImageCollectionViewCell.h"
#import "ImageTableViewCell.h"
#import "PreviewSupplementaryView.h"
#import "ImagePreviewFlowLayout.h"
#import "DefineHeader.h"

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "TZImageManager.h"
#import "TZAssetModel.h"

#import "UIAlertView+Block.h"
#import "NSDate+Millisecond.h"

#define WeakSelf __weak typeof(self) weakSelf = self;

@interface ImagePickerSheetViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    /** 显示大图 */
    BOOL enlargedPreviews;
    /** tableView数据 */
    NSArray *actions;
    /** 相册组 */
    ALAssetsGroup *assetsGroup;
}
/** 原始窗口 */
@property (nonatomic, strong) UIWindow *window;
/** 透明背景，用于点击销毁界面 */
@property (nonatomic, strong) UIView *backgroundView;
/** 屏幕截图 */
//@property (nonatomic, strong) UIImageView *backgroundImageView;
/** 图片显示 */
@property (nonatomic, strong) ImagePickerCollectionView *collectionView;
/** 按钮显示 */
@property (nonatomic, strong) UITableView *tableView;

/** 显示位置，动画效果 */
@property (nonatomic) CGRect imagePickerFrame;
/** 隐藏位置，动画效果 */
@property (nonatomic) CGRect hiddenFrame;
/** 动画时间 */
@property (nonatomic) NSTimeInterval animationTime;

/** 数据 */
/** 获取相册图片数据 */
@property (nonatomic, strong) NSMutableArray *assets;
/** 已选择图片数据 */
@property (nonatomic, strong) NSMutableArray *selectedImageIndices;
/** 圈圈views */
@property (nonatomic, strong) NSMutableDictionary *supplementaryViews;

/** 其他相关数据 */
/** 防止多次启动 */
@property (readwrite) bool isVisible;
/** 选择图片启动 */
@property (readwrite) bool isClickImage;

/** 缩略图数组 */
@property (nonatomic, strong) NSMutableArray *thumbnailImageIndices;
/** 原图数组 */
@property (nonatomic, strong) NSMutableArray *originalImageIndices;
@end

@implementation ImagePickerSheetViewController

- (id)init {
    self = [super init];
    if (self) {
        _assets = [[NSMutableArray alloc] init];
        _selectedImageIndices = [@[] mutableCopy];
        _originalImageIndices = [@[] mutableCopy];
        _thumbnailImageIndices = [@[] mutableCopy];
        _supplementaryViews = [NSMutableDictionary dictionary];
        self.maximumNumberOfSelection = 10;
    }
    return self;
}

#pragma makr - 设置显示UI
- (void)setupView {
    self.view.backgroundColor = [UIColor clearColor];
    
    self.window = [[[UIApplication sharedApplication] delegate] window];
    
    CGFloat tableViewHeight = actions.count * tableViewCellHeight + tableViewPreviewRowHeight;
/** warning 临时代码 start*/
    enlargedPreviews = YES;
    tableViewHeight = actions.count * tableViewCellHeight + tableViewEnlargedPreviewRowHeight;
/** warning 临时代码 end*/
    self.imagePickerFrame = CGRectMake(0, ScreenHeight-tableViewHeight, ScreenWidth, tableViewHeight);
    self.hiddenFrame = CGRectMake(0, ScreenHeight, ScreenWidth, tableViewHeight);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.hiddenFrame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.alwaysBounceVertical = NO;
    
    [self.tableView registerClass:[ImageTableViewCell class] forCellReuseIdentifier:[ImageTableViewCell identifier]];
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        self.tableView.layoutMargins = UIEdgeInsetsZero;
    }
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
    
    self.backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3961];
    self.backgroundView.userInteractionEnabled = YES;

//    UIGraphicsBeginImageContextWithOptions(self.window.frame.size, self.window.opaque, self.window.screen.scale);
//    [self.window.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    self.backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    [self.backgroundImageView setImage:backgroundImage];
    self.animationTime = 0.2;
    
    [self.window addSubview:self.backgroundView];
    [self.window addSubview:self.tableView];
//    [self.window addSubview:self.backgroundImageView];
//    [self.window sendSubviewToBack:self.backgroundImageView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat tableViewPreviewHeight = enlargedPreviews ? tableViewEnlargedPreviewRowHeight : tableViewPreviewRowHeight;
    CGFloat tableViewHeight = actions.count * tableViewCellHeight + tableViewPreviewHeight;
    self.tableView.frame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMaxY(self.view.bounds)-tableViewHeight, CGRectGetWidth(self.view.bounds), tableViewHeight);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    actions = @[kPhotoBtnTitle, kCameraBtnTitle, kCancelBtnTitle];
    [self setupView];
    [self reloadImagesFromLibrary];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)dealloc
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 获取相册的所有图片
- (void)reloadImagesFromLibrary
{
    if (![TZImageManager authorizationStatusAuthorized]) {
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *msg = [NSString stringWithFormat:@"请在%@的\"设置-隐私-照片\"选项中，\r允许%@访问你的手机相册。",[UIDevice currentDevice].model,appName];
        WeakSelf
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"相册访问失败" message:msg cancelButtonTitle:@"确定" otherButtonTitles:nil block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [weakSelf dismiss];
            
        }];
        [alertView show];
    } else {
        WeakSelf
        long long start = [NSDate timeMillisecondSince1970];
        [TZImageManager getCameraRollAlbum:NO fetchLimit:kMaxNum ascending:NO completion:^(TZAlbumModel *model) {
            long long end1 = [NSDate timeMillisecondSince1970];
            NSLog(@"相册加载耗时：%lld毫秒", end1 - start);
            if (!weakSelf) return ;
            /** iOS8之后 获取相册的顺序已经为倒序，获取相册内的图片，要使用顺序获取，否则负负得正 */
            BOOL ascending = IOS8_OR_LATER ? YES : NO;
            /** 优化获取数据源，分批次获取 */
            [TZImageManager getAssetsFromFetchResult:model.result allowPickingVideo:NO fetchLimit:kMaxNum ascending:ascending completion:^void(NSArray<TZAssetModel *> *models) {
                
                [self.assets addObjectsFromArray:models];
                
                if (self.assets.count == 0) {
                    [self imagePickerViewPhotoLibrary];
                } else {
                    [self.collectionView reloadData];
                }
                
                long long end = [NSDate timeMillisecondSince1970];
                NSLog(@"%d张图片加载耗时：%lld毫秒", kMaxNum, end - start);
            }];
        }];
    }
}


#pragma mark - 创建collectionView
- (ImagePickerCollectionView *)collectionView
{
    if (_collectionView == nil) {
        ImagePreviewFlowLayout *aFlowLayout = [[ImagePreviewFlowLayout alloc] init];
        _collectionView = [[ImagePickerCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:aFlowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.imagePreviewLayout.sectionInset = UIEdgeInsetsMake(collectionViewInset, collectionViewInset, collectionViewInset, collectionViewInset);
        _collectionView.imagePreviewLayout.showSupplementaryViews = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        [_collectionView registerClass:[ImageCollectionViewCell class] forCellWithReuseIdentifier:[ImageCollectionViewCell identifier]];
        [_collectionView registerClass:[PreviewSupplementaryView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[PreviewSupplementaryView identifier]];
    }
    return _collectionView;
}

#pragma mark - 启动图片选择器
- (void)showImagePickerInController:(UIViewController *)controller animated:(BOOL)animated {
    
    if (self.isVisible != YES) {
        
        self.isVisible = YES;
        
        if (IOS8_OR_LATER) {
            self.modalPresentationStyle = UIModalPresentationCustom;
//            [self.backgroundImageView removeFromSuperview];
        } else {
            self.modalPresentationStyle = UIModalPresentationCurrentContext;
        }
        
        [controller presentViewController:self animated:NO completion:nil];
        
        self.backgroundView.alpha = 0;
        if (animated) {
            [UIView animateWithDuration:self.animationTime
                                  delay:0.f
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 [self.tableView setFrame:self.imagePickerFrame];
                                 self.backgroundView.alpha = 0.3961;
                             }
                             completion:^(BOOL finished) {
                                 [self.view addSubview:self.backgroundView];
                                 [self.view addSubview:self.tableView];
                                 self.window = nil;
                                 /** 完成后才添加dismiss手势，避免用户猛点屏幕，UI未能出现就已被dismiss的情况 */
                                 UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
                                 [self.backgroundView addGestureRecognizer:dismissTap];
                             }];
        } else {
            [self.tableView setFrame:self.imagePickerFrame];
            self.backgroundView.alpha = 0.3961;
        }
    }
}

- (void)dismissVC:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismiss:completion];
}

#pragma mark - 销毁图片选择器
- (void)dismiss {
    [self dismiss:nil];
}

- (void)dismiss:(void (^)(void))completion
{
    WeakSelf
    if (self.isVisible == YES) {
        [self hideView:^{
            [weakSelf.tableView removeFromSuperview];
            [weakSelf.backgroundView removeFromSuperview];
//            [self.backgroundImageView removeFromSuperview];
            if (weakSelf.dismissBlock) weakSelf.dismissBlock();
            [self dismissViewControllerAnimated:YES completion:completion];
        }];
        // Set everything to nil
    }
}

- (void)hideView:(void (^)(void))completion
{
    [UIView animateWithDuration:self.animationTime
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self.tableView setFrame:self.hiddenFrame];
                         self.backgroundView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         completion();
                     }];
}

- (CGSize)sizeForAsset:(TZAssetModel *)model {
    
    CGSize size = [TZImageManager getPhotoSize:model.asset];
    
    CGFloat imageWidth = size.width;
    CGFloat imageHeight = size.height;
    
//    CGFloat imageWidth = CGImageGetWidth([asset thumbnail]);
//    CGFloat imageHeight = CGImageGetHeight([asset thumbnail]);
    
    CGFloat proportion = imageWidth/imageHeight;
    
    CGFloat rowHeight = enlargedPreviews ? tableViewEnlargedPreviewRowHeight : tableViewPreviewRowHeight;
    CGFloat height = rowHeight - 2.0 * collectionViewInset;
    
    CGSize resultSize = CGSizeMake(proportion * height, height);
    
    /** 针对长图判断，缩放后，宽度小于最小尺寸，重新调整宽度 */
    if (resultSize.width < kImageMinMargin) {
        resultSize.width = kImageMinMargin;
    }
    
    return resultSize;
}
#pragma mark - Table view UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    
    return actions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ImageTableViewCell identifier]];
        
        cell.collectionView = self.collectionView;
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsMake(0, tableView.bounds.size.width, 0, 0);
        }
        return cell;
    }
    
    NSString *title = actions[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([UITableViewCell class])];
    }
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = tableView.tintColor;
    cell.textLabel.font = [UIFont systemFontOfSize:21.f];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        cell.textLabel.text = _selectedImageIndices.count > 0 ? [NSString stringWithFormat:@"发送%ld张图片", _selectedImageIndices.count] : title;
    } else {
        cell.textLabel.text = title;
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    
    return cell;
}

#pragma mark - Table view UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (actions.count > 0) {
            return enlargedPreviews ? tableViewEnlargedPreviewRowHeight : tableViewPreviewRowHeight;
        }
        return 0;
    }
    
    return tableViewCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *title = actions[indexPath.row];
    if ([title isEqualToString:kPhotoBtnTitle]) {
        if (self.selectedImageIndices.count) {
            [self imagePickerViewSendImage];
        } else {
            [self imagePickerViewPhotoLibrary];
        }
    } else if ([title isEqualToString:kCameraBtnTitle]) {
        [self imagePickerViewTakePhoto];
    } else if ([title isEqualToString:kCancelBtnTitle]) {
        [self imagePickerViewCancel];
    }
}

#pragma mark - Collection view UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    /** 最多显示10张 */
    return MIN(kMaxNum, self.assets.count);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ImageCollectionViewCell identifier] forIndexPath:indexPath];
    
//    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    /** 倒序显示 */
//    ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];
    /** 顺序显示 */
    TZAssetModel *model = self.assets[indexPath.section];
    [TZImageManager getPhotoWithAsset:model.asset photoWidth:cell.frame.size.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
//        UIImageView *imageVi = [[UIImageView alloc] initWithFrame:cell.contentView.frame];
//        imageVi.image = photo;
//        [cell.contentView addSubview:imageVi];
        cell.imageView.image = photo;
    }];
    
//    NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
//    NSLog(@"加载第%ldd张图片耗时:%f秒", indexPath.section, end - start);
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PreviewSupplementaryView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[PreviewSupplementaryView identifier] forIndexPath:indexPath];
        supplementaryView.userInteractionEnabled = false;
        supplementaryView.buttonInset = UIEdgeInsetsMake(0.0, kCollectionViewCheckmarkInset, kCollectionViewCheckmarkInset, 0.0);
//        ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];
        TZAssetModel *model = self.assets[indexPath.section];
        supplementaryView.selected = [_selectedImageIndices containsObject:model];
        [_supplementaryViews setObject:supplementaryView forKey:[NSString stringWithFormat:@"%ld", indexPath.section]];
        return supplementaryView;
    }
    return nil;
}

#pragma mark - Collection view UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    TZAssetModel *model = self.assets[indexPath.section];
    
    /** 保存选择数据 */
    PreviewSupplementaryView *supplementaryView = _supplementaryViews[[NSString stringWithFormat:@"%ld", indexPath.section]];
    
    /** 是否选择 */
    BOOL selected = [_selectedImageIndices containsObject:model];
    if (!selected) {
        /** 判断是否超过最大值 */
        if (_selectedImageIndices.count >= _maximumNumberOfSelection) {
            if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerDidMaximum:)]) {
                [self.delegate imagePickerSheetViewControllerDidMaximum:_maximumNumberOfSelection];
            }
            return;
        }
        [_selectedImageIndices addObject:model];
        
        if (!enlargedPreviews) {
            enlargedPreviews = YES;
            self.collectionView.imagePreviewLayout.invalidationCenteredIndexPath = indexPath;
            [self.view setNeedsLayout];
            [UIView animateWithDuration:0.3f animations:^{
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                [self reloadButtons];
                self.collectionView.imagePreviewLayout.showSupplementaryViews = YES;
            }];
        } else {
            ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            CGPoint contentOffset = CGPointMake(CGRectGetMidX(cell.frame) - collectionView.frame.size.width / 2.0, 0.0);
            contentOffset.x = MAX(contentOffset.x, -collectionView.contentInset.left);
            contentOffset.x = MIN(contentOffset.x, collectionView.contentSize.width - CGRectGetWidth(collectionView.frame) + collectionView.contentInset.right);
            [collectionView setContentOffset:contentOffset animated:YES];
            [self reloadButtons];
        }
    } else {
        [_selectedImageIndices removeObject:model];
        [self reloadButtons];
    }
    
    supplementaryView.selected = !supplementaryView.selected;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TZAssetModel *model = self.assets[indexPath.section];
    
    return [self sizeForAsset:model];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    CGFloat inset = 2.0 * kCollectionViewCheckmarkInset;
    CGSize size = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    CGFloat imageWidth = [PreviewSupplementaryView checkmarkImage].size.width;
    return CGSizeMake(imageWidth + inset, size.height);
}

#pragma mark - 刷新tableView
- (void)reloadButtons {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - 拍照图片后执行代理
#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (picker.sourceType==UIImagePickerControllerSourceTypeCamera && [mediaType isEqualToString:@"public.image"]){
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        /** 拍照发送block */
        if (self.imagePickerSheetVCPhotoSendImageBlock) {
            self.imagePickerSheetVCPhotoSendImageBlock(chosenImage);
        }
        if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerPhotoImage:)]) {
            [self.delegate imagePickerSheetViewControllerPhotoImage:chosenImage];
        }
    } else {
        NSLog(@"Media type:%@" , mediaType);
    }
    
    [super dismissViewControllerAnimated:YES completion:^{
        [self dismiss];
    }];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [super dismissViewControllerAnimated:YES completion:^{
        [self dismiss];
    }];
}

#pragma mark - ImagePickerViewDelegate
/** 相册按钮 */
- (void)imagePickerViewPhotoLibrary
{
    NSLog(@"打开相册");
    if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerOpenPhtotLabrary)]) {
        [self dismiss:^{
            [self.delegate imagePickerSheetViewControllerOpenPhtotLabrary];
        }];
    } else {
        /** 打开原生相册 */
        [self hideView:^{
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            [picker setAllowsEditing:NO];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
            picker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:picker animated:YES completion:nil];
        }];
    }
}
/** 照相按钮 */
- (void)imagePickerViewTakePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        
        [myAlertView show];
        
    } else {
        NSLog(@"打开相机");
        if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerTakePhtot)]) {
            [self dismiss:^{
                [self.delegate imagePickerSheetViewControllerTakePhtot];
            }];
        } else {
            /** 打开原生相机 */
            [self hideView:^{
                UIImagePickerControllerSourceType srcType = UIImagePickerControllerSourceTypeCamera;
                UIImagePickerController *mediaPickerController = [[UIImagePickerController alloc] init];
                mediaPickerController.sourceType = srcType;
                mediaPickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                mediaPickerController.delegate = self;
                mediaPickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                [self presentViewController:mediaPickerController animated:YES completion:^{
                    
                    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
                    {
                        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                        if (authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
                        {
                            UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:nil message:@"请在iPhone的“设置-隐私-相机”选项中，允许本应用访问你的相机" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                            [prompt show];
                        }
                    }
                }];
            }];
        }
    }
}

/** 取消按钮 */
- (void)imagePickerViewCancel
{
    NSLog(@"取消");
    [self dismiss];
}
/** 发送按钮 */
- (void)imagePickerViewSendImage
{
    NSLog(@"发送%ld张图片", _selectedImageIndices.count);
    
    NSLog(@"正在处理...");
    
    if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerAssets:)]) {
        [self.delegate imagePickerSheetViewControllerAssets:[_selectedImageIndices copy]];
    }
    
    __weak typeof(self)weakSelf = self;
    for (int i = 0; i < _selectedImageIndices.count; i ++) {
        TZAssetModel *model = _selectedImageIndices[i];
        [_thumbnailImageIndices addObject:@1];
        [_originalImageIndices addObject:@1];
        /** 这里发送的是标清图和缩略图，不需要发送原图 */
        [TZImageManager getPreviewPhotoWithAsset:model.asset completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
            if(!weakSelf) return ;
            if(thumbnail)[weakSelf.thumbnailImageIndices replaceObjectAtIndex:i withObject:thumbnail];
            if(source)[weakSelf.originalImageIndices replaceObjectAtIndex:i withObject:source];
            if ([weakSelf.thumbnailImageIndices containsObject:@1]) return;
            
            /** imagePickerSheetVCSendImageBlock回调 */
            if (weakSelf.imagePickerSheetVCSendImageBlock) {
                weakSelf.imagePickerSheetVCSendImageBlock(weakSelf.thumbnailImageIndices, weakSelf.originalImageIndices);
            }
            /** 代理 */
            if ([weakSelf.delegate respondsToSelector:@selector(imagePickerSheetViewControllerThumbnailImages:originalImages:)]) {
                [weakSelf.delegate imagePickerSheetViewControllerThumbnailImages:weakSelf.thumbnailImageIndices originalImages:weakSelf.originalImageIndices];
            }
            
            [weakSelf dismiss];
        }];
    }
}
@end
