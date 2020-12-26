//
//  YLRouterConfig.h
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//控制器跳转相关参数配置;
extern NSString* const kJSDVCRouteSegue;//区分 Push 或 Modal
extern NSString* const kJSDVCRouteAnimated;//跳转时是否需要动画切换
extern NSString* const kJSDVCRouteBackIndex;//处理同级导航栏返回层级 Index
extern NSString* const kJSDVCRouteBackPage;//指定同级导航栏到此页面
extern NSString* const kJSDVCRouteBackPageOffset;//指定
extern NSString* const kJSDVCRouteFromOutside;//处理外部跳转到App
extern NSString* const kJSDVCRouteNeedLogin;//指定需要登录才能跳转的页面
extern NSString* const kJSDVCRouteSegueNeedNavigation;  //Modal 时需要导航控制器;

extern NSString* const kJSDVCRouteIndexRoot;  //导航栏根控制器
extern NSString* const kJSDVCRouteSeguePush;  //Push
extern NSString* const kJSDVCRouteSegueModal; //
extern NSString* const kJSDVCRouteSegueBack;  //返回上一页;
extern NSString* const kJSDVCRouteClassName;
extern NSString* const kJSDVCRouteClassTitle;
extern NSString* const kJSDVCRouteClassFlags;
extern NSString* const kJSDVCRouteClassNeedLogin;

//TabBar 下控制器;
extern NSString* const JSDVCRouteHomeTab;
extern NSString* const JSDVCRouteCafeTab;
extern NSString* const JSDVCRouteCoffeeTab;
extern NSString* const JSDVCRouteMyCenterTab;

extern NSString* const JSDVCRouteInvestTabGB;
extern NSString* const JSDVCRouteInvestTabYX;

///组件化： SDK 内的控制器
FOUNDATION_EXPORT NSString* const YLRouteURLReader;
FOUNDATION_EXPORT NSString* const YLRouteURLReader_1;


//App 内所有控制器
FOUNDATION_EXPORT NSString* const YLRouteURLWebview;



@interface YLRouterConfig : NSObject

+ (NSDictionary *)configMapInfo;

@end

NS_ASSUME_NONNULL_END
