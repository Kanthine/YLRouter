# 源码解读 JLRoutes


###### 思考如下的问题，开发中我们是如何优雅的解决的：

* 1、3D-Touch 功能或者点击推送消息，如何从外部跳转到App内部一个很深层次的一个界面？
  比如微信的3D-Touch可以直接跳转到“我的二维码”；“我的二维码”界面在我的里面的第三级界面；或者再极端一点，产品需求给了更加变态的需求，要求跳转到App内部第十层的界面，怎么处理？
* 2、如果自己App有几个，相互之间还想相互跳转，怎么处理？
* 3、随着项目越来越复杂，各个 App 组件，各个 App 页面之间的跳转逻辑关联性越来越多，如何能优雅的解除各个组件和页面之间的耦合性？
* 4、如何能一统 iOS端、Android端、Web端的页面跳转逻辑？甚至一统三端的请求资源方式？
   项目里面某些模块会混合ReactNative，Weex，H5界面，这些界面还会调用原生界面，以及原生组件。那么，如何能统一Web端和原生端请求资源的方式？
* 5、如果使用了动态下发配置文件来配置 App 的跳转逻辑，那么如果做到 iOS端、Android端、Web端 三方共享一套配置文件？
* 6、如果 App 出现bug，如何不用 `JSPatch`，就能做到简单的热修复功能？
  比如App上线突然遇到了紧急bug，能否把页面 _动态_ 降级成 H5，ReactNative，Weex？或者是直接换成一个本地的错误界面？
* 7、如何在每个组件间调用和页面跳转时都进行埋点统计？每个跳转的地方都手写代码埋点？利用 Runtime AOP ？
* 8、如何在每个组件间调用的过程中，加入调用的逻辑检查，令牌机制，配合灰度进行风控逻辑？
* 9、如何在App任何界面都可以调用同一个界面或者同一个组件？只能在 `AppDelegate` 里面注册单例来实现？
  比如App出现问题了，用户可能在任何界面，如何随时随地的让用户强制退出？或者强制都跳转到同一个本地的`error`界面？或者跳转到相应的H5，ReactNative，Weex界面？如何让用户在任何界面，随时随地的弹出一个 `View` ？
  
 上述问题其实都可以通过在App端设计一个路由来解决。

#### 1、组件化与路由



#### 2、App 之间跳转方式


![NSURLComponents 处理 URL](https://upload-images.jianshu.io/upload_images/7112462-6b431cfbec56124d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```
NSString *urlString = @"YLRouterMain://userPage:8008/userSet/nickNameSet?user=123456&nickName=Hello";
NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
NSLog(@"components ==== %@",components);
///<NSURLComponents 0x60000170cb50> {scheme = YLRouterMain, user = (null), password = (null), host = userPage, port = 8008, path = /userSet/nickNameSet, query = user=123456&nickName=Hello, fragment = (null)}
```



#### 3、源码解读 `JLRoutes`

`Github` 上 `Star` 最多的路由方案是  [JLRoutes](https://github.com/joeldev/JLRoutes) ， 我们来分析下它的具体设计思路！


JLRoutes 是基于 URL Scheme 方式跳转的！


![JLRoutes 设计思路](https://upload-images.jianshu.io/upload_images/7112462-29449b61a8b00138.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##### 3.1、路由模型 `JLRRouteDefinition` 的注册

![路由模型 JLRRouteDefinition](https://upload-images.jianshu.io/upload_images/7112462-0ce2337226ab5f34.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


```
@implementation JLRoutes

/** 注册路由：
 * @param routePattern 在注册阶段已经进行赋值，不需要别的操作
 * @param priority 优先级，默认为 0；用途在存入数组中排队顺序，数值越大，在数组中排的位置越靠前。
 * @param handler 处理路由时间，返回值表示是否处理
 *                返回一个BOOL值，表示 handlerBlock 是否真的处理了该路由。如果返回NO, JLRoutes将继续寻找匹配的路由
 * @param routeDefinition 定制路由逻辑：将每一条注册数据（pattern、priority、handler）封装在JLRouteDefinition对象中
 */
- (void)addRoute:(JLRRouteDefinition *)routeDefinition;
- (void)addRoute:(NSString *)routePattern handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock;
- (void)addRoutes:(NSArray<NSString *> *)routePatterns handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock;
- (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock{

    //1、将 routePattern 展开为可选路由模式，如：@"/path/:thing/(/a)(/b)(/c)"
    NSArray <NSString *> *optionalRoutePatterns = [JLRParsingUtilities expandOptionalRoutePatternsForPattern:routePattern];
    
    // 2、根据 routePattern、priority、handlerBlock 封装一个路由模型 JLRRouteDefinition
    JLRRouteDefinition *route = [[JLRGlobal_routeDefinitionClass alloc] initWithPattern:routePattern priority:priority handlerBlock:handlerBlock];
    
    // 3、如果有可选路由模式，则注册可选路由；并结束不再向下执行
    if (optionalRoutePatterns.count > 0) {
    /// 有可选参数，需要解析和添加它们
        for (NSString *pattern in optionalRoutePatterns) {
            JLRRouteDefinition *optionalRoute = [[JLRGlobal_routeDefinitionClass alloc] initWithPattern:pattern priority:priority handlerBlock:handlerBlock];
            [self _registerRoute:optionalRoute];/// 注册可选路由
            [self _verboseLog:@"Automatically created optional route: %@", optionalRoute];
        }
        // 如果有可选路由模式，则不需注册 routePattern
        return;
    }

    // 4、如果没有可选路由，则注册 routePattern 对应的路由模型 JLRRouteDefinition
    [self _registerRoute:route];
}

@end
```

注册路由的方法，大致可以归纳为四件事：
* 1、将 `routePattern` 展开为可选路由模式，如：`@"/path/:thing/(/a)(/b)(/c)"`
* 2、根据 `routePattern、priority、handlerBlock` 封装一个路由模型 `JLRRouteDefinition`
* 3、如果有可选路由模式，则注册可选路由；并结束不再向下执行
* 4、如果没有可选路由，则注册 `routePattern` 对应的路由模型 `JLRRouteDefinition`



可选的路由模式，这里不多赘述！详细探究下封装的路由模型 `JLRRouteDefinition` ：


```
@implementation JLRRouteDefinition

- (instancetype)initWithPattern:(NSString *)pattern priority:(NSUInteger)priority handlerBlock:(BOOL (^)(NSDictionary *parameters))handlerBlock{
    NSParameterAssert(pattern != nil);
    
    if ((self = [super init])) {
        self.pattern = pattern;
        self.priority = priority;
        self.handlerBlock = handlerBlock;
        
        /// 剔除开头的 / ，保证路径组件的第一个路径不是空
        if ([pattern characterAtIndex:0] == '/') {
            pattern = [pattern substringFromIndex:1];
        }
        
        /// 路径组件
        self.patternPathComponents = [pattern componentsSeparatedByString:@"/"];
    }
    return self;
}

@end
```


##### 3.2、通过 URL 调起已注册的 `JLRRouteDefinition` 



```
@implementation JLRoutes

/// 如果提供的 ULR 可以成功为当前scheme匹配任一个已注册的路由，则返回YES。否则返回NO。
- (BOOL)canRouteURL:(nullable NSURL *)URL{
    return [self _routeURL:URL withParameters:nil executeRouteBlock:NO];
}

/** 在特定scheme内路由一个URL，为与此URL相匹配的模式调用 handlerBlock，直到找到了相匹配的模式，返回YES。
 *  如果没有找到匹配的路由，将调用提前设置的 unmatchedURLHandler
 *  @param parameters  一些参数信息，传送至匹配的 route block
 */
- (BOOL)routeURL:(nullable NSURL *)URL;
- (BOOL)routeURL:(nullable NSURL *)URL withParameters:(nullable NSDictionary<NSString *, id> *)parameters{
    return [self _routeURL:URL withParameters:parameters executeRouteBlock:YES];
}

/** 调起路由，执行 handlerBlock */
- (BOOL)_routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters executeRouteBlock:(BOOL)executeRouteBlock{
    if (!URL) {
        return NO;
    }    
    BOOL didRoute = NO;/// 标记是否已经路由
    JLRRouteRequestOptions options = [self _routeRequestOptions];
    
    /// 1、根据 URL 创建一个请求 JLRRouteRequest
    JLRRouteRequest *request = [[JLRRouteRequest alloc] initWithURL:URL options:options additionalParameters:parameters];
    
    /// 2、遍历已注册路由，查找能匹配的路由，执行 handlerBlock
    for (JLRRouteDefinition *route in [self.mutableRoutes copy]) {
        // 检查每个路由是否有匹配的响应
        JLRRouteResponse *response = [route routeResponseForRequest:request];
        if (!response.isMatch) {
            continue;
        }
                
        // 没有执行block立即返回
        if (!executeRouteBlock) {
            return YES;
        }
                
        // 调用路由模型对象 handlerBlock
        didRoute = [route callHandlerBlockWithParameters:response.parameters];
        if (didRoute) {
            break;/// 如果成功路由，中断循环
        }
    }
    
    /// 3、如果找不到匹配的路由，尝试去全局路由来匹配
    if (!didRoute && self.shouldFallbackToGlobalRoutes && ![self _isGlobalRoutesController]) {
        [self _verboseLog:@"Falling back to global routes..."];
        didRoute = [[JLRoutes globalRoutes] _routeURL:URL withParameters:parameters executeRouteBlock:executeRouteBlock];
    }
    
    /// 4、如果还是找不到匹配的路由，回调 unmatchedURLHandler()
    if (!didRoute && executeRouteBlock && self.unmatchedURLHandler) {
        self.unmatchedURLHandler(self, URL, parameters);
    }
    
    // 5、返回是否已路由
    return didRoute;
}


@end
```

调用路由的方法，大致可以归纳为几件事：

* 1、根据 URL 创建一个请求  `JLRRouteRequest`
* 2、在路由器的数组 `mutableRoutes` 中匹配已注册的对应路由，
  如果不匹配，中断当前循环，进入下一轮查询
  如果匹配，但没有执行 `executeRouteBlock` 则立即返回结果
 如果匹配，执行 `handlerBlock`；中断循环！
* 3、如果找不到匹配的路由，尝试去全局路由来匹配
* 4、如果还是找不到匹配的路由，回调 `unmatchedURLHandler()`
* 5、返回路由结果





###### Ⅰ、封装请求  `JLRRouteRequest`


![JLRRouteRequest的初始化](https://upload-images.jianshu.io/upload_images/7112462-88715486c4c47324.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


```
@implementation JLRRouteRequest

/** JLRRouteRequest 的初始化方法
 *  1、使用 NSURLComponents 将一个 URL 拆分为 scheme、host、port、path、query、fragment 等；
 *  2、 将 components.host 拼接到 path 中 ？
 *          条件一：components.host.length > 0；
 *          条件二：（components.host 不是 localhost 并且 components.host 不包含 .） || 配置项
 *     如果将 components.host 拼接到 path 中，则 JLRRouteRequest.pathComponents 包含 host 并且 包含 path
 *  3、 将 URL 的附带参数 components.queryItems 转为字典格式 JLRRouteRequest.queryParams
 */
- (instancetype)initWithURL:(NSURL *)URL options:(JLRRouteRequestOptions)options additionalParameters:(nullable NSDictionary *)additionalParameters{
    if ((self = [super init])) {
        self.URL = URL;
        self.options = options;
        self.additionalParameters = additionalParameters;
        
        BOOL treatsHostAsPathComponent = ((options & JLRRouteRequestOptionTreatHostAsPathComponent) == JLRRouteRequestOptionTreatHostAsPathComponent);
        
        NSURLComponents *components = [NSURLComponents componentsWithString:[self.URL absoluteString]];
        
        /// 将 host 拼接到 path 中
        // host 不是 localhost 且 host 不包含 .
        if (components.host.length > 0 &&
            (treatsHostAsPathComponent ||
             (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound))) {
            // 将 host 转为一个路径组件
            NSString *host = [components.percentEncodedHost copy];
            components.host = @"/";
            components.percentEncodedPath = [host stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
        }
        NSString *path = [components percentEncodedPath];
        
        // handle fragment if needed
        if (components.fragment != nil) {
            BOOL fragmentContainsQueryParams = NO;
            NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
            
            if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
                fragmentComponents.query = fragmentComponents.path;
            }
            
            if (fragmentComponents.queryItems.count > 0) {
                // determine if this fragment is only valid query params and nothing else
                fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
            }

            
            if (fragmentContainsQueryParams) {
                // include fragment query params in with the standard set
                components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
            }
            
            if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
                // handle fragment by include fragment path as part of the main path
                path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
            }
        }
        
        // 去掉开头的斜杠，这样第一个路径组件不会为空
        if (path.length > 0 && [path characterAtIndex:0] == '/') {
            path = [path substringFromIndex:1];
        }
        
        // 去掉结尾的斜杠，这样最后一个路径组件不会为空
        if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
            path = [path substringToIndex:path.length - 1];
        }
        // 分割 path
        self.pathComponents = [path componentsSeparatedByString:@"/"];
        
        // 将 URL 的附带参数转为字典格式
        NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in queryItems) {
            if (item.value == nil) {
                continue;
            }
            if (queryParams[item.name] == nil) {
                // 第一次设置键值
                queryParams[item.name] = item.value;
            } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
                // already an array of these items, append it
                NSArray *values = (NSArray *)(queryParams[item.name]);
                queryParams[item.name] = [values arrayByAddingObject:item.value];
            } else {
                // 再次遇见该键，将多组值组成一个数组
                id existingValue = queryParams[item.name];
                queryParams[item.name] = @[existingValue, item.value];
            }
        }
        self.queryParams = [queryParams copy];
    }
    return self;
}

@end
```

`JLRRouteRequest` 的初始化方法，大致做了以下几件事:

*  1、使用 `NSURLComponents` 将一个 URL 拆分为` scheme、host、port、path、query、fragment` 等；
*  2、 将 `components.host` 拼接到 `path` 中 ？
   条件一：`components.host.length > 0`；
  条件二：`(components.host 不是 localhost 并且 components.host 不包含 .) || 配置项`
 如果将 `components.host` 拼接到 `path` 中，则 `JLRRouteRequest.pathComponents` 包含 `host` 并且 包含 `path`
*  3、 将 `URL` 的附带参数 `components.queryItems` 转为字典格式 `JLRRouteRequest.queryParams`


###### Ⅱ、如何匹配路由？

路由的匹配，交给了 `JLRRouteDefinition` 去判断：

```
@implementation JLRRouteDefinition

/// 匹配阶段通过对注册内容进行查找，找到匹配项。并对匹配内容进行拼接，完成匹配pattern的匹配和变量赋值的操作
- (JLRRouteResponse *)routeResponseForRequest:(JLRRouteRequest *)request{
    /// 是否包含通配符 '*'
    BOOL patternContainsWildcard = [self.patternPathComponents containsObject:@"*"];
    
    /// 1、不包含通配符，路径组件的数量又不一样，返回一个无效的响应
    if (request.pathComponents.count != self.patternPathComponents.count && !patternContainsWildcard) {
        return [JLRRouteResponse invalidMatchResponse];
    }
    
    /// 2、判断 request.pathComponents 与 RouteDefinition.patternPathComponents 相对位置的路径是否一致
    ///   如果一致，截取 URL 中的变量，
    ///   如果不一致，则返回 routeVariables = nil ；表示不匹配
    NSDictionary *routeVariables = [self routeVariablesForRequest:request];
    
    if (routeVariables != nil) {
        // 如果匹配，将 request.url 的请求附加参数、变量参数、request.additionalParameters 合并为一个字典
        NSDictionary *matchParams = [self matchParametersForRequest:request routeVariables:routeVariables];
        return [JLRRouteResponse validMatchResponseWithParameters:matchParams];
    } else { /// 没有匹配的变量，返回一个无效响应
        return [JLRRouteResponse invalidMatchResponse];
    }
}

@end
```

匹配有效的响应，基于以下几个判断：

* 1、不包含通配符，路径组件的数量又不一样，返回一个无效的响应；
* 2、判断 `request.pathComponents` 与 `RouteDefinition.patternPathComponents` 相对位置的路径是否一致：
*    如果一致，截取 `URL` 中的变量，
*    如果不一致，则返回 `routeVariables = nil` ；表示不匹配
* 3、将 `request.url` 的请求附加参数、变量参数、`request.additionalParameters` 合并为一个字典，封装一个有效的响应



###### Ⅲ、如何匹配路由？URL 请求中还有变量？


```
@implementation JLRRouteDefinition

/** 解析并返回指定请求的路由变量
 * 注册路由时的路径，如果使用 : 开头，如 mainTabBar/:name
 *               则一个请求走到这里，会尝试取出该请求的对应参数 mainTabBar/user
 *               @{@"name":@"user"}
 * @note 注册路由模型时，路径组件仅仅使用 \ 分割；
 *       而请求 request 的路径组件使用 NSURLComponents 处理的附加的参数！
 *       所以，注册路由时的 URL 一定不能包含参数，否则永远不可能匹配到有效响应
 */
- (NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(JLRRouteRequest *)request{
    NSMutableDictionary *routeVariables = [NSMutableDictionary dictionary];
    BOOL isMatch = YES;
    NSUInteger index = 0;
    
    for (NSString *patternComponent in self.patternPathComponents) {
        NSString *URLComponent = nil;
        BOOL isPatternComponentWildcard = [patternComponent isEqualToString:@"*"];
        if (index < [request.pathComponents count]) {
            URLComponent = request.pathComponents[index];
        } else if (!isPatternComponentWildcard) {
            // URLComponent 不是通配符 并且 index 又对 request.pathComponents 越界
            NSLog(@"URLComponent 不是通配符 并且 index 又对 request.pathComponents 越界");
            isMatch = NO;
            break;
        }
        if ([patternComponent hasPrefix:@":"]) {
            // : 开头的路径是一个变量, 将该变量设置到参数 params 中
            NSAssert(URLComponent != nil, @"URLComponent cannot be nil");
            
            ///当字符串长度大于 1 时，去掉字符串开头的 ':' 与 字符串结尾的 '#'
            NSString *variableName = [self routeVariableNameForValue:patternComponent];
            ///对 URLComponent 解码，去掉字符串结尾的 '#'
            NSString *variableValue = [self routeVariableValueForValue:URLComponent];
            BOOL decodePlusSymbols = ((request.options & JLRRouteRequestOptionDecodePlusSymbols) == JLRRouteRequestOptionDecodePlusSymbols);
            variableValue = [JLRParsingUtilities variableValueFrom:variableValue decodePlusSymbols:decodePlusSymbols];
            
            routeVariables[variableName] = variableValue;/// 将该变量设置到参数 params 中
        } else if (isPatternComponentWildcard) {
            // 匹配通配符
            NSUInteger minRequiredParams = index;
            if (request.pathComponents.count >= minRequiredParams) {
                // match: /a/b/c/* has to be matched by at least /a/b/c
                routeVariables[JLRouteWildcardComponentsKey] = [request.pathComponents subarrayWithRange:NSMakeRange(index, request.pathComponents.count - index)];
                isMatch = YES;
            } else {
                // not a match: /a/b/c/* cannot be matched by URL /a/b/
                isMatch = NO;
            }
            break;
        } else if (![patternComponent isEqualToString:URLComponent]) {
            //路径组件 request.pathComponents 与 JLRRouteDefinition.patternPathComponents 相对位置的路径不一致，则终断循环
            isMatch = NO;
            break;
        }
        index++;
    }
    
    if (!isMatch) {
        // 如果没有匹配项，返回 nil
        routeVariables = nil;
    }
    return [routeVariables copy];
}

@end
```

###### Ⅳ、匹配到有效响应

如果匹配到有效的响应，可以去执行回调 `JLRRouteDefinition.handlerBlock()` 处理一些跳转逻辑

```
@implementation JLRRouteDefinition

- (BOOL)callHandlerBlockWithParameters:(NSDictionary *)parameters{
    if (self.handlerBlock == nil) {
        return YES;
    }
    return self.handlerBlock(parameters);
}

@end
```






---

参考文章

[iOS 组件化 —— 路由设计思路分析](https://juejin.cn/post/6844903582739726350#heading-11)
[解读 iOS 组件化与路由的本质](https://www.jianshu.com/p/40060fa2a564)

