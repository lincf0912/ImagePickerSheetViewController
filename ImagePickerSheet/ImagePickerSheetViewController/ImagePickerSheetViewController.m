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
#import <AssetsLibrary/AssetsLibrary.h>
#import "DefineHeader.h"

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>


@interface ImagePickerSheetViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    /** 显示大图 */
    BOOL enlargedPreviews;
    /** tableView数据 */
    NSArray *actions;
}
/** 原始窗口 */
@property (nonatomic, strong) UIWindow *window;
/** 透明背景，用于点击销毁界面 */
@property (nonatomic, strong) UIView *backgroundView;
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

@end

@implementation ImagePickerSheetViewController

- (id)init {
    self = [super init];
    if (self) {
        self.assets = [[NSMutableArray alloc] init];
        [self setupView];
    }
    return self;
}

#pragma makr - 设置显示UI
- (void)setupView {
    self.view.backgroundColor = [UIColor clearColor];
    self.window = [UIApplication sharedApplication].keyWindow;
    
    CGFloat tableViewHeight = actions.count * tableViewCellHeight + tableViewPreviewRowHeight;
    self.imagePickerFrame = CGRectMake(0, ScreenHeight-tableViewHeight, ScreenWidth, tableViewHeight);
    self.hiddenFrame = CGRectMake(0, ScreenHeight, ScreenWidth, tableViewHeight);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.hiddenFrame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.alwaysBounceVertical = NO;
    self.tableView.layoutMargins = UIEdgeInsetsZero;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.tableView registerClass:[ImageTableViewCell class] forCellReuseIdentifier:[ImageTableViewCell identifier]];
    
    self.backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3961];
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    self.backgroundView.userInteractionEnabled = YES;
    [self.backgroundView addGestureRecognizer:dismissTap];
    
    
    self.animationTime = 0.2;
    
    [self.window addSubview:self.backgroundView];
    [self.window addSubview:self.tableView];
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
//    [self createCollectionView];
    
    [self getCameraRollImages];
    
    
    actions = @[kPhotoBtnTitle, kCameraBtnTitle, kCancelBtnTitle];
}

- (void)dealloc
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - 获取相册数据
- (void)getCameraRollImages {
    _assets = [@[] mutableCopy];
    _selectedImageIndices = [@[] mutableCopy];
    _supplementaryViews = [NSMutableDictionary dictionary];
//    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    ALAssetsLibrary *assetsLibrary = [[self class] defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
//            if(result)
//            {
//                [tmpAssets addObject:result];
//            }
//        }];
        
        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                if (index > kMaxNum) {
                    *stop = YES;
                }
                [self.assets addObject:result];
            }
        };
        
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [group setAssetsFilter:onlyPhotosFilter];
        [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
        
        [self.collectionView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"读取相册图片错误：%@", error);
    }];
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - 启动图片选择器
- (void)showImagePickerInController:(UIViewController *)controller animated:(BOOL)animated {
    if (self.isVisible != YES) {
        
        self.isVisible = YES;
        
        self.modalPresentationStyle = UIModalPresentationCustom;
        [controller presentViewController:self animated:NO completion:nil];
        self.backgroundView.alpha = 0;
        if (animated) {
            [UIView animateWithDuration:self.animationTime
                                  delay:0
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 [self.tableView setFrame:self.imagePickerFrame];
                                 self.backgroundView.alpha = 0.3961;
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        } else {
            [self.tableView setFrame:self.imagePickerFrame];
        }
    }
}

#pragma mark - 销毁图片选择器
- (void)dismiss {
    [self dismiss:nil];
}

- (void)dismiss:(void (^)(void))completion
{
    if (self.isVisible == YES) {
        [self hideView:^{
            [self.tableView removeFromSuperview];
            [self.backgroundView removeFromSuperview];
            [self dismissViewControllerAnimated:NO completion:completion];
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

- (CGSize)sizeForAsset:(ALAsset *)asset {
    
    CGSize size = [[asset defaultRepresentation] dimensions];
    CGFloat imageWidth = size.width;
    CGFloat imageHeight = size.height;
    
//    CGFloat imageWidth = CGImageGetWidth([asset thumbnail]);
//    CGFloat imageHeight = CGImageGetHeight([asset thumbnail]);
    
    CGFloat proportion = imageWidth/imageHeight;
    
    CGFloat rowHeight = enlargedPreviews ? tableViewEnlargedPreviewRowHeight : tableViewPreviewRowHeight;
    CGFloat height = rowHeight - 2.0 * collectionViewInset;
    
    return CGSizeMake(proportion * height, height);
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
        cell.separatorInset = UIEdgeInsetsMake(0, tableView.bounds.size.width, 0, 0);
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
    cell.layoutMargins = UIEdgeInsetsZero;
    
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
    
    /** 倒序显示 */
    ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];

    cell.imageView.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PreviewSupplementaryView *supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[PreviewSupplementaryView identifier] forIndexPath:indexPath];
        supplementaryView.userInteractionEnabled = false;
        supplementaryView.buttonInset = UIEdgeInsetsMake(0.0, kCollectionViewCheckmarkInset, kCollectionViewCheckmarkInset, 0.0);
        ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];
        supplementaryView.selected = [_selectedImageIndices containsObject:asset];
        [_supplementaryViews setObject:supplementaryView forKey:[NSString stringWithFormat:@"%ld", indexPath.section]];
        return supplementaryView;
    }
    return nil;
}

#pragma mark - Collection view UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];
    
    /** 保存选择数据 */
    PreviewSupplementaryView *supplementaryView = _supplementaryViews[[NSString stringWithFormat:@"%ld", indexPath.section]];
    
    /** 是否选择 */
    BOOL selected = [_selectedImageIndices containsObject:asset];
    if (!selected) {
        [_selectedImageIndices addObject:asset];
        
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
        [_selectedImageIndices removeObject:asset];
        [self reloadButtons];
    }
    
    supplementaryView.selected = !supplementaryView.selected;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *asset = self.assets[self.assets.count-1 - indexPath.section];
    
    return [self sizeForAsset:asset];
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
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerSendImage:)]) {
            [self.delegate imagePickerSheetViewControllerSendImage:chosenImage];
        }
        [self dismiss];
    }];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
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
                        if (authStatus != AVAuthorizationStatusAuthorized)
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
    [self dismiss:^{
        NSLog(@"发送%ld张图片", _selectedImageIndices.count);
        if ([self.delegate respondsToSelector:@selector(imagePickerSheetViewControllerSendImage:)]) {
            [_selectedImageIndices enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
                UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
                [self.delegate imagePickerSheetViewControllerSendImage:image];
            }];
        }
    }];
}

@end
