//
//  YLRouterService.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import "YLRouterService.h"
#import <JLRoutes/JLRoutes.h>

static inline NSString *routePatternFromUrl(NSString *url){
    NSString *string = [NSString stringWithFormat:@"%@://",kYLRouterMainScheme];
    string = @"YLRouterMain://";
    if ([url hasPrefix:string]) {
        return [url substringFromIndex:string.length];
    }
    return url;
}

static inline JLRoutes *YLRouter(void){
    return [JLRoutes routesForScheme:kYLRouterMainScheme];
}

@implementation YLRouterService

+ (BOOL)openURL:(NSString *)url {
    return [self routeURL:url parameters:nil];
}

+ (BOOL)openURL:(NSString *)url parameters:(NSDictionary *)parameters {
    return [self routeURL:url parameters:parameters];
}

+ (void)addRoute:(NSString *)route handler:(BOOL (^)(NSDictionary * _Nonnull parameters))handlerBlock {
    [YLRouter() addRoute:routePatternFromUrl(route) handler:handlerBlock];
}

#pragma mark - mark JLRouter

/** 如果线上App出现紧急bug了，如何不用JSPatch，就能做到简单的热修复功能？
 *  可以考虑把页面动态降级成 H5 ；或者是直接换成一个本地的错误界面
 */
+ (BOOL)routeURL:(NSString *)url parameters:(NSDictionary *)parameters{
    if ([url hasPrefix:kYLRouterMainScheme]) {
        return [YLRouter() routeURL:[NSURL URLWithString:routePatternFromUrl(url)] withParameters:parameters];
    }else if ([url hasPrefix:@"http:"] || [url hasPrefix:@"https:"]){
        return [YLRouter() routeURL:[NSURL URLWithString:routePatternFromUrl(kYLRouteURLWebview)] withParameters:@{@"url":url}];
    }
    return NO;
}

@end



#import <UIKit/UIKit.h>


@interface UIViewController (GetController)

+ (UIViewController* )yl_GetRootViewController;
+ (UIViewController* )yl_GetCurrentViewController;

@end
@implementation UIViewController (GetController)

+ (UIViewController *)yl_GetRootViewController {
    return [UIApplication sharedApplication].delegate.window.rootViewController;
}

+ (UIViewController *)yl_GetCurrentViewController {
    UIViewController* currentViewController = [self yl_GetRootViewController];

    BOOL runLoopFind = YES;
    while (runLoopFind) {
        if (currentViewController.presentedViewController) {
            currentViewController = currentViewController.presentedViewController;
        } else {
            if ([currentViewController isKindOfClass:[UINavigationController class]]) {
                currentViewController = ((UINavigationController *)currentViewController).visibleViewController;
            } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
                currentViewController = ((UITabBarController* )currentViewController).selectedViewController;
            } else {
                break;
            }
        }
    }
    return currentViewController;
}

@end



#import "MainTabBarController.h"

@implementation YLRouterService (Handler)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// 注册 Router
        [self performSelectorOnMainThread:@selector(registerRouter) withObject:nil waitUntilDone:false];
    });
}

+ (void)registerRouter {
//    [JLRoutes setAlwaysTreatsHostAsPathComponent:YES];
    //获取全局 RouterMapInfo
    NSDictionary *routerMapInfo = [YLRouterConfig configMapInfo];
    // router 对应控制器路径, 使用其来注册 Route, 当调用当前 Route 时会执行回调; 回调参数 parameters: 在执行 Route 时传入的参数;
    for (NSString* router in routerMapInfo.allKeys) {
        NSDictionary* routerMap = routerMapInfo[router];
        NSString* className = routerMap[kYLRouterViewController];
        if (className && [className isKindOfClass:NSString.class] && className.length) {
            
            /// 注册所有控制器 Router
            [YLRouter() addRoute:routePatternFromUrl(router) handler:^BOOL(NSDictionary * _Nonnull parameters) {
                /// 执行路由匹配成功之后，跳转逻辑回调;
                /** 执行 Route 回调; 处理控制器跳转 + 传参;
                 * routerMap: 当前 route 映射的  routeMap; 我们在 RouterConfig 配置的 Map;
                 * parameters: 调用 route 时, 传入的参数;
                 */
                return [self executeRouterClassName:className routerMap:routerMap parameters:parameters];
            }];
        }
    }
    
    [YLRouter() addRoute:@"mainTabBar/:name" handler:^BOOL(NSDictionary * _Nonnull parameters) {
        return [MainTabBarController setSelectedVC:parameters[@"name"] parameters:parameters];
    }];
    // 注册返回上层页面 Router, 使用 [JSDVCRouter openURL:kJSDVCRouteSegueBack] 返回上一页 或 [JSDVCRouter openURL:kJSDVCRouteSegueBack parameters:@{kJSDVCRouteBackIndex: @(2)}]  返回前两页
    [self addRoute:kYLRouterSegueBack handler:^BOOL(NSDictionary * _Nonnull parameters) {
        return [self executeBackRouterParameters:parameters];
    }];
}

#pragma mark - execute Router VC
// 当查找到指定 Router 时, 触发路由回调逻辑; 找不到已注册 Router 则直接返回 NO; 如需要的话, 也可以在这里注册一个全局未匹配到 Router 执行的回调进行异常处理;
+ (BOOL)executeRouterClassName:(NSString *)className routerMap:(NSDictionary* )routerMap parameters:(NSDictionary* )parameters {
    // 拦截 Router 映射参数,是否需要登录才可跳转;
//    BOOL needLogin = [routerMap[kJSDVCRouteClassNeedLogin] boolValue];
//    if (needLogin && !userIsLogin) {
//        [JSDVCRouter openURL:JSDVCRouteLogin];
//        return NO;
//    }
    //统一初始化控制器,传参和跳转;
    UIViewController* vc = [self viewControllerWithClassName:className routerMap:routerMap parameters:parameters];
    if (vc) {
        [self gotoViewController:vc parameters:parameters];
        return YES;
    } else {
        return NO;
    }
}
// 根据 Router 映射到的类名实例化控制器;
+ (UIViewController *)viewControllerWithClassName:(NSString *)className routerMap:(NSDictionary *)routerMap parameters:(NSDictionary* )parameters {
    
    id vc = [[NSClassFromString(className) alloc] init];
    if (![vc isKindOfClass:[UIViewController class]]) {
        vc = nil;
    }
#if DEBUG
    //vc不是UIViewController
    NSAssert(vc, @"%s: %@ is not kind of UIViewController class, routerMap: %@",__func__ ,className, routerMap);
#endif
    //参数赋值
    [self setupParameters:parameters forViewController:vc];
    
    return vc;
}
// 对 VC 参数赋值
+ (void)setupParameters:(NSDictionary *)params forViewController:(UIViewController* )vc {
    
    for (NSString *key in params.allKeys) {
        BOOL hasKey = [vc respondsToSelector:NSSelectorFromString(key)];
        BOOL notNil = params[key] != nil;
        if (hasKey && notNil) {
            [vc setValue:params[key] forKey:key];
        }
        
#if DEBUG
    //vc没有相应属性，但却传了值
        if ([key hasPrefix:@"JLRoute"]==NO &&
            [key hasPrefix:@"JSDVCRoute"]==NO && [params[@"JLRoutePattern"] rangeOfString:[NSString stringWithFormat:@":%@",key]].location==NSNotFound) {
            NSLog(@"%s: %@ is not property for the key %@",__func__ ,vc,key);
//            NSAssert(hasKey == YES, @"%s: %@ is not property for the key %@",__func__ ,vc,key);
        }
#endif
    };
}
// 跳转和参数设置;
+ (void)gotoViewController:(UIViewController *)vc parameters:(NSDictionary *)parameters {
    if (parameters[kYLRouterSegueTabNameKey]) {
        [MainTabBarController setSelectedVC:parameters[kYLRouterSegueTabNameKey] parameters:@{}];
    }
    
    UIViewController* currentVC = [UIViewController yl_GetCurrentViewController];
    
    /// 决定 present 或者 Push; 默认值 Push
    NSString *segue = parameters[kYLRouterSegueKey] ? parameters[kYLRouterSegueKey] : kYLRouterSeguePush;
    /// 转场动画
    BOOL animated = parameters[kYLRouterSegueAnimatedKey] ? [parameters[kYLRouterSegueAnimatedKey] boolValue] : YES;
    
    BOOL hidesBottomBarWhenPushed = parameters[kYLRouterSegueHidesBottomBarKey] ? [parameters[kYLRouterSegueHidesBottomBarKey] boolValue] : YES;
    

    if ([segue isEqualToString:kYLRouterSeguePush]) { //PUSH
        if (currentVC.navigationController) {
            vc.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed;

            NSString *backIndexString = [NSString stringWithFormat:@"%@",parameters[kYLRouterBackPagesKey]];
            UINavigationController* nav = currentVC.navigationController;
            if ([backIndexString isEqualToString:kYLRouterBackToRootKey]) {
                NSMutableArray *vcs = [NSMutableArray arrayWithObject:nav.viewControllers.firstObject];
                [vcs addObject:vc];
                [nav setViewControllers:vcs animated:animated];
                
            } else if ([backIndexString integerValue] && [backIndexString integerValue] < nav.viewControllers.count) {
                //移除掉指定数量的 VC, 在Push;
                NSMutableArray *vcs = [nav.viewControllers mutableCopy];
                [vcs removeObjectsInRange:NSMakeRange(vcs.count - [backIndexString integerValue], [backIndexString integerValue])];
                nav.viewControllers = vcs;
                [nav pushViewController:vc animated:YES];
            } else {
                [nav pushViewController:vc animated:animated];
            }
        }
        else { //由于无导航栏, 直接执行 Modal
            BOOL needNavigation = parameters[kYLRouterSegueModalIsNeedNavigationKey] ? NO : YES;
            if (needNavigation) {
                UINavigationController* navigationVC = [[UINavigationController alloc] initWithRootViewController:vc];
                //vc.modalPresentationStyle = UIModalPresentationFullScreen;
                [currentVC presentViewController:navigationVC animated:YES completion:nil];
            }
            else {
                //vc.modalPresentationStyle = UIModalPresentationFullScreen;
                [currentVC presentViewController:vc animated:animated completion:nil];
            }
        }
    }
    else { //Modal
        BOOL needNavigation = parameters[kYLRouterSegueModalIsNeedNavigationKey] ? parameters[kYLRouterSegueModalIsNeedNavigationKey] : NO;
        if (needNavigation) {
            UINavigationController* navigationVC = [[UINavigationController alloc] initWithRootViewController:vc];
            //vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [currentVC presentViewController:navigationVC animated:animated completion:nil];
        }
        else {
            //vc.modalPresentationStyle = UIModalPresentationFullScreen;
            [currentVC presentViewController:vc animated:animated completion:nil];
        }
    }
}


// 返回上层页面回调;
+ (BOOL)executeBackRouterParameters:(NSDictionary *)parameters {
    BOOL animated = parameters[kYLRouterSegueAnimatedKey] ? [parameters[kYLRouterSegueAnimatedKey] boolValue] : YES;
    NSString *backIndexString = parameters[kYLRouterBackPagesKey] ? [NSString stringWithFormat:@"%@",parameters[kYLRouterBackPagesKey]] : nil;  // 指定返回个数, 优先处理此参数;
    id backPage = parameters[kYLRouterBackThePageKey] ? parameters[kYLRouterBackThePageKey] : nil; // 指定返回到某个页面,
    UIViewController* visibleVC = [UIViewController yl_GetCurrentViewController];
    UINavigationController* navigationVC = visibleVC.navigationController;
    if (navigationVC) {
        // 处理 pop 按索引值处理;

        if (!(backIndexString == nil || [backIndexString isKindOfClass:NSNull.class] ||
            ([backIndexString isKindOfClass:NSString.class] && backIndexString.length == 0))) {
            if ([backIndexString isEqualToString:kYLRouterBackToRootKey]) {//返回根
                [navigationVC popToRootViewControllerAnimated:animated];
            }
            else {
                NSUInteger backIndex = backIndexString.integerValue;
                NSMutableArray* vcs = navigationVC.viewControllers.mutableCopy;
                if (vcs.count > backIndex) {
                    [vcs removeObjectsInRange:NSMakeRange(vcs.count - backIndex, backIndex)];
                    [navigationVC setViewControllers:vcs animated:animated];
                    return YES;
                }
                else {
                    return NO; //指定返回索引值超过当前导航控制器包含的子控制器;
                }
            }
        }
        else if (backPage) { //处理返回指定的控制器, 可以处理
            NSMutableArray *vcs = navigationVC.viewControllers.mutableCopy;
            NSInteger pageIndex = NSNotFound;
            //页面标识为字符串
            if ([backPage isKindOfClass:[NSString class]]) {
                for (int i=0; i<vcs.count; i++) {
                    if ([vcs[i] isKindOfClass:NSClassFromString(backPage)]) {
                        pageIndex = i;
                        break;
                    }
                }
            }
            //页面标识为vc实例
            else if ([backPage isKindOfClass:[UIViewController class]]) {
                for (int i=0; i<vcs.count; i++) {
                    if (vcs[i] == backPage) {
                        pageIndex = i;
                        break;
                    }
                }
            }
        }
        else {
            [navigationVC popViewControllerAnimated:animated];
            return YES;
        }
    }
    else {
        [visibleVC dismissViewControllerAnimated:animated completion:nil];
        return YES;
    }
    return NO;
}


@end
