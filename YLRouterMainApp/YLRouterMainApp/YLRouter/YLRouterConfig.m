//
//  YLRouterConfig.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import "YLRouterConfig.h"


NSString* const kJSDVCRouteSegue = @"JSDVCRouteSegue";
NSString* const kJSDVCRouteAnimated = @"JSDVCRouteAnimated";
NSString* const kJSDVCRouteBackIndex = @"JSDVCRouteBackIndex";
NSString* const kJSDVCRouteBackPage = @"JSDVCRouteBackPage";
NSString* const kJSDVCRouteBackPageOffset = @"JSDVCRouteBackPageOffset";
NSString* const kJSDVCRouteFromOutside = @"JSDVCRouteFromOutside";
NSString* const kJSDVCRouteNeedLogin = @"JSDVCRouteNeedLogin";
NSString* const kJSDVCRouteSegueNeedNavigation = @"JSDVCRouteNeedNavigation";

NSString* const kJSDVCRouteIndexRoot = @"root";
NSString* const kJSDVCRouteSeguePush = @"push";
NSString* const kJSDVCRouteSegueModal = @"modal";
NSString* const kJSDVCRouteSegueBack = @"/back";

NSString* const kJSDVCRouteClassName = @"class";
NSString* const kJSDVCRouteClassTitle = @"title";
NSString* const kJSDVCRouteClassFlags = @"flags";
NSString* const kJSDVCRouteClassNeedLogin = @"needLogin";

NSString* const JSDVCRouteHomeTab = @"/rootTab/0";
NSString* const JSDVCRouteCafeTab = @"/rootTab/1";
NSString* const JSDVCRouteCoffeeTab = @"/rootTab/2";
NSString* const JSDVCRouteMyCenterTab = @"/rootTab/3";


///组件化： SDK 内的控制器
NSString* const YLRouteURLReader = @"/reader";
NSString* const YLRouteURLReader_1 = @"/reader_1";

//App 内相关控制器
NSString* const YLRouteURLWebview = @"/webView";




//NSString* const YLRouteURLWebview = @"YLRouterMain://webView";
NSString* const JSDVCRouteLogin = @"/login";
NSString* const JSDVCRouteRegister = @"/register";
NSString* const JSDVCRouteAppear = @"/home/Appear";
NSString* const JSDVCRouteAppearNotNeedLogin = @"/home/AppearNotNeedLogin";

@implementation YLRouterConfig

+ (NSDictionary *)configMapInfo {
    
    return @{
        YLRouteURLWebview: @{kJSDVCRouteClassName: @"YLWebViewController",
                             kJSDVCRouteClassTitle: @"WebView",
                             kJSDVCRouteClassFlags: @"",
                             kJSDVCRouteClassNeedLogin: @"",
        },
        YLRouteURLReader: @{kJSDVCRouteClassName: @"YLReaderViewController",
                             kJSDVCRouteClassTitle: @"阅读器",
                             kJSDVCRouteClassFlags: @"",
                             kJSDVCRouteClassNeedLogin: @"",
        },
        YLRouteURLReader_1: @{kJSDVCRouteClassName: @"YLReaderPageController",
                             kJSDVCRouteClassTitle: @"阅读器",
                             kJSDVCRouteClassFlags: @"",
                             kJSDVCRouteClassNeedLogin: @"",
        },
        JSDVCRouteRegister: @{kJSDVCRouteClassName: @"JSDRegisterVC",
                              kJSDVCRouteClassTitle: @"注册",
                              kJSDVCRouteClassFlags: @"",
                              kJSDVCRouteClassNeedLogin: @"",
        },
        JSDVCRouteAppear: @{kJSDVCRouteClassName: @"JSDAppearVC",
                              kJSDVCRouteClassTitle: @"测试OpenRouter:",
                              kJSDVCRouteClassFlags: @"",
                              kJSDVCRouteClassNeedLogin: @"1",
            
        },
        JSDVCRouteAppearNotNeedLogin: @{kJSDVCRouteClassName: @"JSDAppearNotNeedLogInVC",
                              kJSDVCRouteClassTitle: @"测试OpenRouterNotNeedLogin:",
                              kJSDVCRouteClassFlags: @"",
                              kJSDVCRouteClassNeedLogin: @"",
        },
    };
}

@end
