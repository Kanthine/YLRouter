//
//  YLCollectionTransitionAnimationLayout.h
//  CollectionLayout
//
//  Created by 苏沫离 on 2020/8/28.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface YLCollectionTransitionAnimationAttributes : UICollectionViewLayoutAttributes

///缓存 cell.contentView
@property (nonatomic ,strong) UIView *contentView;

///记录 UICollectionView 滚动方向
@property (nonatomic ,assign) UICollectionViewScrollDirection scrollDirection;

@property (nonatomic ,assign) CGFloat startOffset;

@property (nonatomic ,assign) CGFloat middleOffset;

@property (nonatomic ,assign) CGFloat endOffset;

@end




///转场动画类型
typedef NS_ENUM(NSUInteger,YLCollectionTransitionType) {
    YLCollectionTransitionNone = 0,//小数阅读器：无效果
    YLCollectionTransitionOpen,//小数阅读器：覆盖
    YLCollectionTransitionPan, //小数阅读器：平移
    YLCollectionTransitionScroll,//小说阅读器：滚动
};
// PageCurl

///转场动画 FlowLayout
@interface YLCollectionTransitionAnimationLayout : UICollectionViewFlowLayout

///转场动画类型
@property (nonatomic ,assign) YLCollectionTransitionType transitionType;

@end

NS_ASSUME_NONNULL_END
