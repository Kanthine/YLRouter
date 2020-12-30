//
//  YLRouterConfig.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import "YLRouterConfig.h"


NSString *const kYLRouterMainScheme = @"YLRouterMain";

/********* 控制器跳转时的一些参数 ******/
NSString* const kYLRouterViewController = @"viewController";
NSString* const kYLRouterControllerTitle = @"navigationItemTitle";
NSString* const kYLRouterUserPermissionLevel = @"User_Permission_Level";
NSString* const kJSDVCRouteClassFlags = @"flags";


//控制器跳转相关参数配置
NSString* const kYLRouterSegueKey = @"kYLRouterSegueKey";
NSString* const kYLRouterSeguePush = @"kYLRouterSeguePush";
NSString* const kYLRouterSegueModal = @"kYLRouterSegueModal";

NSString* const kYLRouterSegueAnimatedKey = @"kYLRouterSegueAnimatedKey";
NSString* const kYLRouterSegueHidesBottomBarKey = @"kYLRouterSegueHidesBottomBarKey";
NSString* const kYLRouterSegueTabNameKey = @"kYLRouterSegueTabNameKey";


NSString* const kJSDVCRouteBackIndex = @"JSDVCRouteBackIndex";
NSString* const kJSDVCRouteBackPage = @"JSDVCRouteBackPage";
NSString* const kJSDVCRouteBackPageOffset = @"JSDVCRouteBackPageOffset";
NSString* const kJSDVCRouteFromOutside = @"JSDVCRouteFromOutside";
NSString* const kJSDVCRouteNeedLogin = @"JSDVCRouteNeedLogin";
NSString* const kJSDVCRouteSegueNeedNavigation = @"JSDVCRouteNeedNavigation";

NSString* const kJSDVCRouteIndexRoot = @"root";
NSString* const kJSDVCRouteSegueBack = @"/back";


//TabBar 下控制器
NSString* const kYLRouteURL_Tab_User = @"YLRouterMain://mainTabBar/User";
NSString* const kYLRouteURL_Tab_News = @"YLRouterMain://mainTabBar/News";


///组件化： SDK 内的控制器
NSString* const kYLRouteURLReader = @"YLRouterMain://reader";
NSString* const kYLRouteURLReader_1 = @"YLRouterMain://reader_1";

//App 内相关控制器
NSString* const kYLRouteURLWebview = @"YLRouterMain://webView";
NSString* const kYLRouteURL_User_Set = @"YLRouterMain://User/set";
NSString* const kYLRouteURL_User_Set_NickName = @"YLRouterMain://User/set/nickName";

@implementation YLRouterConfig

+ (NSDictionary *)configMapInfo {
    
    return @{
        kYLRouteURLWebview: @{kYLRouterViewController: @"YLWebViewController",
                             kYLRouterControllerTitle: @"WebView",
                             kJSDVCRouteClassFlags: @"",
                             kYLRouterUserPermissionLevel: @(0),
        },
        kYLRouteURLReader: @{kYLRouterViewController: @"YLReaderViewController",
                            kYLRouterControllerTitle: @"阅读器",
                             kJSDVCRouteClassFlags: @"",
                            kYLRouterUserPermissionLevel: @(0),
        },
        kYLRouteURL_User_Set: @{kYLRouterViewController: @"UserSetViewController",
                               kYLRouterControllerTitle: @"用户设置",
                              kJSDVCRouteClassFlags: @"",
                               kYLRouterUserPermissionLevel: @(0),
        },
        kYLRouteURL_User_Set_NickName: @{kYLRouterViewController: @"UserSetNickNameViewController",
                               kYLRouterControllerTitle: @"用户昵称设置",
                              kJSDVCRouteClassFlags: @"",
                               kYLRouterUserPermissionLevel: @(0),
        },
    };
}

@end
