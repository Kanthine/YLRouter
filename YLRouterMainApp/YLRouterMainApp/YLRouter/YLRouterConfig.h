//
//  YLRouterConfig.h
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///该 App 的Scheme
FOUNDATION_EXPORT NSString *const kYLRouterMainScheme;

/********* 控制器跳转时的一些参数 ******/
FOUNDATION_EXPORT NSString* const kYLRouterViewController;
FOUNDATION_EXPORT NSString* const kYLRouterControllerTitle;
FOUNDATION_EXPORT NSString* const kYLRouterUserPermissionLevel;

//控制器跳转相关参数配置
FOUNDATION_EXPORT NSString *const kYLRouterSegueKey;//区分 Push 或 Modal
FOUNDATION_EXPORT NSString *const kYLRouterSeguePush;  //Push
FOUNDATION_EXPORT NSString *const kYLRouterSegueModal; //Modal
/// 跳转时是否需要动画切换
FOUNDATION_EXPORT NSString *const kYLRouterSegueAnimatedKey;
/// 跳转时是否需要 hidesBottomBarWhenPushed，默认为 YES
FOUNDATION_EXPORT NSString *const kYLRouterSegueHidesBottomBarKey;
/// 跳转时，tabbar 是否需要切换至指定位置
FOUNDATION_EXPORT NSString* const kYLRouterSegueTabNameKey;
/// Modal 时是否需要导航控制器: 默认不需要
FOUNDATION_EXPORT NSString* const kYLRouterSegueModalIsNeedNavigationKey;


/********* 返回到指定页面（同级导航栏） ******/

/// 控制器的返回
FOUNDATION_EXPORT NSString* const kYLRouterSegueBack;
/// 回退多少页
FOUNDATION_EXPORT NSString* const kYLRouterBackPagesKey;
/// 回退到指定页面
FOUNDATION_EXPORT NSString* const kYLRouterBackThePageKey;
/// 回退到根控制器
FOUNDATION_EXPORT NSString* const kYLRouterBackToRootKey;



//TabBar 下控制器
FOUNDATION_EXPORT NSString* const kYLRouteURL_Tab_User;
FOUNDATION_EXPORT NSString* const kYLRouteURL_Tab_News;

///组件化： SDK 内的控制器
FOUNDATION_EXPORT NSString* const kYLRouteURLReader;

//App 内所有控制器
FOUNDATION_EXPORT NSString* const kYLRouteURLWebview;
FOUNDATION_EXPORT NSString* const kYLRouteURL_User_Set;
FOUNDATION_EXPORT NSString* const kYLRouteURL_User_Set_NickName;



@interface YLRouterConfig : NSObject

+ (NSDictionary *)configMapInfo;

@end

NS_ASSUME_NONNULL_END
