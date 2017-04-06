//
//  ImageCollectionViewFlowLayout.m
//  ImagePickerSheet
//
//  Created by LamTsanFeng on 15/7/8.
//  Copyright (c) 2015年 GZMiracle. All rights reserved.
//

#import "ImagePreviewFlowLayout.h"
#import "PreviewSupplementaryView.h"
#import "DefineHeader.h"

@interface ImagePreviewFlowLayout ()
{
    NSMutableArray *layoutAttributes;
    CGSize contentSize;
}
@end

@implementation ImagePreviewFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
         [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    [self setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    layoutAttributes = [[NSMutableArray alloc] init];
    contentSize = CGSizeZero;
}

- (void)prepareLayout
{
    [super prepareLayout];
    [layoutAttributes removeAllObjects];
    contentSize = CGSizeZero;
    
    id<UICollectionViewDataSource> dataSource = self.collectionView.dataSource;
    id<UICollectionViewDelegateFlowLayout> delegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    CGPoint origin = CGPointMake(self.sectionInset.left, self.sectionInset.top);
    NSInteger numberOfSections = [dataSource numberOfSectionsInCollectionView:self.collectionView];
    
    for (NSInteger s = 0; s < numberOfSections; s ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:s];
        CGSize size = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
        
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = (CGRect){origin, size};
        attributes.zIndex = 0;
        
        [layoutAttributes addObject:attributes];
        
        origin.x = CGRectGetMaxX(attributes.frame) + self.sectionInset.right;
    }
    
    contentSize = CGSizeMake(origin.x, CGRectGetHeight(self.collectionView.frame));
}

- (CGSize)collectionViewContentSize
{
    return contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *arrays = [NSMutableArray array];
    /** 过滤 */
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [arrays addObject:attributes];
        }
    }
    
    NSMutableArray *answer = [NSMutableArray array];
    
    for (UICollectionViewLayoutAttributes *attributes in arrays) {
        [answer addObject:attributes];
        UICollectionViewLayoutAttributes *supplementaryAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:attributes.indexPath];
        [answer addObject:supplementaryAttributes];
    }
    
    return answer;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    CGPoint contentOffset = proposedContentOffset;
    
    NSIndexPath *indexPath = self.invalidationCenteredIndexPath;
    UICollectionViewLayoutAttributes *attributes = layoutAttributes[indexPath.section];
    CGRect frame = attributes.frame;
    contentOffset.x = CGRectGetMidX(frame) - CGRectGetWidth(self.collectionView.frame) / 2.0;
    contentOffset.x = MAX(contentOffset.x, - self.collectionView.contentInset.left);
    contentOffset.x = MIN(contentOffset.x, [self collectionViewContentSize].width - CGRectGetWidth(self.collectionView.frame) + self.collectionView.contentInset.right);
    
    self.invalidationCenteredIndexPath = nil;
    
    return [super targetContentOffsetForProposedContentOffset:contentOffset];
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return layoutAttributes[indexPath.section];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    id<UICollectionViewDelegateFlowLayout> delegate = (id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate;
    
    UICollectionViewLayoutAttributes *itemAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
    
    UIEdgeInsets inset = self.collectionView.contentInset;
    CGRect bounds = self.collectionView.bounds;
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.x += inset.left;
    contentOffset.y += inset.top;
    
    CGSize visibleSize = bounds.size;
    visibleSize.width -= (inset.left + inset.right);
    
    CGRect visibleFrame = (CGRect){contentOffset, visibleSize};
    
    CGSize size = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:indexPath.section];
    CGFloat originX = MAX(CGRectGetMinX(itemAttributes.frame), MIN(CGRectGetMaxX(itemAttributes.frame) - size.width, CGRectGetMaxX(visibleFrame) - size.width));
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    
    attributes.zIndex = 1;
//#warning 临时代码 start
//    attributes.hidden = !self.showSupplementaryViews;
//#warning 临时代码 end
    attributes.frame = (CGRect){{originX, CGRectGetMinY(itemAttributes.frame)}, size};
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)setShowSupplementaryViews:(BOOL)showSupplementaryViews
{
    if (_showSupplementaryViews != showSupplementaryViews) {
        _showSupplementaryViews = showSupplementaryViews;
    }
    [self invalidateLayout];
}

@end
