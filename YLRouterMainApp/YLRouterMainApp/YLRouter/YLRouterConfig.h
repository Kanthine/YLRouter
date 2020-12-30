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



extern NSString* const kJSDVCRouteBackIndex;//处理同级导航栏返回层级 Index
extern NSString* const kJSDVCRouteBackPage;//指定同级导航栏到此页面
extern NSString* const kJSDVCRouteBackPageOffset;//指定
extern NSString* const kJSDVCRouteFromOutside;//处理外部跳转到App
extern NSString* const kJSDVCRouteNeedLogin;//指定需要登录才能跳转的页面
extern NSString* const kJSDVCRouteSegueNeedNavigation;  //Modal 时需要导航控制器;
extern NSString* const kJSDVCRouteIndexRoot;  //导航栏根控制器
extern NSString* const kJSDVCRouteSegueBack;  //返回上一页;


extern NSString* const kJSDVCRouteClassFlags;

//TabBar 下控制器
FOUNDATION_EXPORT NSString* const kYLRouteURL_Tab_User;
FOUNDATION_EXPORT NSString* const kYLRouteURL_Tab_News;

///组件化： SDK 内的控制器
FOUNDATION_EXPORT NSString* const kYLRouteURLReader;
FOUNDATION_EXPORT NSString* const kYLRouteURLReader_1;

//App 内所有控制器
FOUNDATION_EXPORT NSString* const kYLRouteURLWebview;
FOUNDATION_EXPORT NSString* const kYLRouteURL_User_Set;
FOUNDATION_EXPORT NSString* const kYLRouteURL_User_Set_NickName;



@interface YLRouterConfig : NSObject

+ (NSDictionary *)configMapInfo;

@end

NS_ASSUME_NONNULL_END
