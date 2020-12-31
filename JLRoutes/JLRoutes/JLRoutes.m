/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRoutes.h"
#import "JLRRouteDefinition.h"
#import "JLRParsingUtilities.h"


NSString *const JLRoutePatternKey = @"JLRoutePattern";
NSString *const JLRouteURLKey = @"JLRouteURL";
NSString *const JLRouteSchemeKey = @"JLRouteScheme";
NSString *const JLRouteWildcardComponentsKey = @"JLRouteWildcardComponents";
NSString *const JLRoutesGlobalRoutesScheme = @"JLRoutesGlobalRoutesScheme";


/** JLRoutes 全局会保存一个Map，这个 Map 会以 scheme 为Key，JLRoutes 为 Value
 * 所以在 routeControllerMap 里面每个 scheme 都是唯一的
 */
static NSMutableDictionary *JLRGlobal_routeControllersMap = nil;


// 全局配置 (configured in +initialize)
static BOOL JLRGlobal_verboseLoggingEnabled;///是否开启日志
static BOOL JLRGlobal_shouldDecodePlusSymbols;///是否替换符号 +
static BOOL JLRGlobal_alwaysTreatsHostAsPathComponent;
static Class JLRGlobal_routeDefinitionClass;/// 默认类


@interface JLRoutes ()

@property (nonatomic, strong) NSMutableArray<JLRRouteDefinition *> *mutableRoutes;
@property (nonatomic, strong) NSString *scheme;

- (JLRRouteRequestOptions)_routeRequestOptions;

@end


#pragma mark -

@implementation JLRoutes

+ (void)initialize
{
    if (self == [JLRoutes class]) {
        // Set default global options
        JLRGlobal_verboseLoggingEnabled = NO;
        JLRGlobal_shouldDecodePlusSymbols = YES;
        JLRGlobal_alwaysTreatsHostAsPathComponent = NO;
        JLRGlobal_routeDefinitionClass = [JLRRouteDefinition class];
    }
}

- (instancetype)init
{
    if ((self = [super init])) {
        self.mutableRoutes = [NSMutableArray array];
    }
    return self;
}

- (NSString *)description
{
    return [self.mutableRoutes description];
}

+ (NSDictionary <NSString *, NSArray <JLRRouteDefinition *> *> *)allRoutes;
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    for (NSString *namespace in [JLRGlobal_routeControllersMap copy]) {
        JLRoutes *routesController = JLRGlobal_routeControllersMap[namespace];
        dictionary[namespace] = [routesController.mutableRoutes copy];
    }
    
    return [dictionary copy];
}


#pragma mark - Routing Schemes
///  获取全局路由
+ (instancetype)globalRoutes
{
    return [self routesForScheme:JLRoutesGlobalRoutesScheme];
}

/** 根据 scheme 获取指定路由
 */
+ (instancetype)routesForScheme:(NSString *)scheme
{
    JLRoutes *routesController = nil;
    
    //全局之创建一个MAP
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JLRGlobal_routeControllersMap = [[NSMutableDictionary alloc] init];
    });
    
    //用scheme作为key，然后JLRoutes作为value值，JLRoutes中有可变数组来存储不同的URL生成的模型对象，JLRRouteDefinition；
    if (!JLRGlobal_routeControllersMap[scheme]) {
        routesController = [[self alloc] init];
        routesController.scheme = scheme;
        JLRGlobal_routeControllersMap[scheme] = routesController;
    }
    routesController = JLRGlobal_routeControllersMap[scheme];
    return routesController;
}

///注销 scheme 指定的路由
+ (void)unregisterRouteScheme:(NSString *)scheme
{
    [JLRGlobal_routeControllersMap removeObjectForKey:scheme];
}

///注销所有路由
+ (void)unregisterAllRouteSchemes
{
    [JLRGlobal_routeControllersMap removeAllObjects];
}


#pragma mark - 注册 Routes

- (void)addRoute:(JLRRouteDefinition *)routeDefinition{
    [self _registerRoute:routeDefinition];
}

- (void)addRoute:(NSString *)routePattern handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock{
    [self addRoute:routePattern priority:0 handler:handlerBlock];
}

- (void)addRoutes:(NSArray<NSString *> *)routePatterns handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock{
    for (NSString *routePattern in routePatterns) {
        [self addRoute:routePattern handler:handlerBlock];
    }
}

/** 注册路由
 * 1、将 routePattern 展开为可选路由模式，如：@"/path/:thing/(/a)(/b)(/c)"
 * 2、根据 routePattern、priority、handlerBlock 封装一个路由模型 JLRRouteDefinition
 * 3、如果有可选路由模式，则注册可选路由；并结束不再向下执行
 * 4、如果没有可选路由，则注册 routePattern 对应的路由模型 JLRRouteDefinition
 */
- (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock{
    
    // 为 routePattern 展开可选路由模式
    NSArray <NSString *> *optionalRoutePatterns = [JLRParsingUtilities expandOptionalRoutePatternsForPattern:routePattern];

    // 根据入参创建 JLRRouteDefinition 路由模型对象
    JLRRouteDefinition *route = [[JLRGlobal_routeDefinitionClass alloc] initWithPattern:routePattern priority:priority handlerBlock:handlerBlock];
    
    // 如果optionalRoutePatterns大于0, 即有可选路由模式，注册可选路由
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
    
    // 如果没有可选路由模式，注册 routePattern
    [self _registerRoute:route];
}

- (void)removeRoute:(JLRRouteDefinition *)routeDefinition
{
    [self.mutableRoutes removeObject:routeDefinition];
}

- (void)removeRouteWithPattern:(NSString *)routePattern
{   
    NSInteger routeIndex = NSNotFound;
    NSInteger index = 0;
    
    for (JLRRouteDefinition *route in [self.mutableRoutes copy]) {
        if ([route.pattern isEqualToString:routePattern]) {
            routeIndex = index;
            break;
        }
        index++;
    }
    
    if (routeIndex != NSNotFound) {
        [self.mutableRoutes removeObjectAtIndex:(NSUInteger)routeIndex];
    }
}

- (void)removeAllRoutes
{
    [self.mutableRoutes removeAllObjects];
}

- (void)setObject:(id)handlerBlock forKeyedSubscript:(NSString *)routePatten
{
    [self addRoute:routePatten handler:handlerBlock];
}

- (NSArray <JLRRouteDefinition *> *)routes;
{
    return [self.mutableRoutes copy];
}

#pragma mark - Routing URLs

/// 如果提供的 URL 可以成功匹配任一个已注册的路由，则返回YES。否则返回NO。
+ (BOOL)canRouteURL:(NSURL *)URL
{
    return [[self _routesControllerForURL:URL] canRouteURL:URL];
}

/// 如果提供的 ULR 可以成功为当前scheme匹配任一个已注册的路由，则返回YES。否则返回NO。
- (BOOL)canRouteURL:(NSURL *)URL
{
    return [self _routeURL:URL withParameters:nil executeRouteBlock:NO];
}

+ (BOOL)routeURL:(NSURL *)URL
{
    return [[self _routesControllerForURL:URL] routeURL:URL];
}

- (BOOL)routeURL:(NSURL *)URL
{
    return [self _routeURL:URL withParameters:nil executeRouteBlock:YES];
}

+ (BOOL)routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters
{
    return [[self _routesControllerForURL:URL] routeURL:URL withParameters:parameters];
}

- (BOOL)routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters
{
    return [self _routeURL:URL withParameters:parameters executeRouteBlock:YES];
}


#pragma mark - Private

/// 根据 URL 查找到对应的路由器（ scheme ）
+ (instancetype)_routesControllerForURL:(NSURL *)URL{
    if (URL == nil) {
        return nil;
    }
    return JLRGlobal_routeControllersMap[URL.scheme] ?: [JLRoutes globalRoutes];
}

/** 注册一个路由
 * 1、搜索现有路由，按优先级插入JLRoutes的数组中，优先级高的排列在前面
 * 2、为路由模型对象设置 scheme
 */
- (void)_registerRoute:(JLRRouteDefinition *)route{
    if (route.priority == 0 || self.mutableRoutes.count == 0) {
        [self.mutableRoutes addObject:route];
    } else {
        NSUInteger index = 0;
        BOOL addedRoute = NO;
        for (JLRRouteDefinition *existingRoute in [self.mutableRoutes copy]) {
            if (existingRoute.priority < route.priority) {
                [self.mutableRoutes insertObject:route atIndex:index];
                addedRoute = YES;
                break;
            }
            index++;
        }
        if (!addedRoute) {
            [self.mutableRoutes addObject:route];
        }
    }
    
    // 将JLRoutes的scheme赋值给传递进来的路由模型对象的scheme
    [route didBecomeRegisteredForScheme:self.scheme];
}

/** 调起路由，执行 handlerBlock
 * 1、根据 URL 创建一个请求 JLRRouteRequest
 * 2、在路由器的数组 mutableRoutes 中匹配已注册的对应路由，
 *     如果不匹配，中断当前循环，进入下一轮查询
 *     如果匹配，但没有执行 executeRouteBlock 则立即返回
 *     如果匹配，执行 handlerBlock；中断循环！
 * 3、如果找不到匹配的路由，尝试去全局路由来匹配
 * 4、如果还是找不到匹配的路由，回调 unmatchedURLHandler()
 * 5、返回路由结果
 */
/// 根据 URL 创建一个 JLRRouteRequest，然后在JLRoutes的数组中依次查找，直到找到一个匹配的然后获取parameters，执行Handler
- (BOOL)_routeURL:(NSURL *)URL withParameters:(NSDictionary *)parameters executeRouteBlock:(BOOL)executeRouteBlock{
    if (!URL) {
        return NO;
    }
    
    [self _verboseLog:@"Trying to route URL %@", URL];
    
    BOOL didRoute = NO;/// 标记是否已经路由
    
    JLRRouteRequestOptions options = [self _routeRequestOptions];
    
    /// 创建路由请求
    JLRRouteRequest *request = [[JLRRouteRequest alloc] initWithURL:URL options:options additionalParameters:parameters];
    
    /// 遍历已注册路由，查找能匹配的路由，执行 handlerBlock
    for (JLRRouteDefinition *route in [self.mutableRoutes copy]) {
        // 检查每个路由是否有匹配的响应
        JLRRouteResponse *response = [route routeResponseForRequest:request];
        if (!response.isMatch) {
            continue;
        }
        
        [self _verboseLog:@"匹配成功 %@", route];
        
        // 没有执行block立即返回
        if (!executeRouteBlock) {
            return YES;
        }
        
        [self _verboseLog:@"Match parameters are %@", response.parameters];
        
        // 调用路由模型对象 handlerBlock
        didRoute = [route callHandlerBlockWithParameters:response.parameters];
        
        if (didRoute) {
            /// 如果成功路由，中断循环
            break;
        }
    }
    
    if (!didRoute) {
        [self _verboseLog:@"找不到匹配的路由"];
    }
    
    /// 如果找不到匹配的路由，尝试去全局路由来匹配
    if (!didRoute && self.shouldFallbackToGlobalRoutes && ![self _isGlobalRoutesController]) {
        [self _verboseLog:@"Falling back to global routes..."];
        didRoute = [[JLRoutes globalRoutes] _routeURL:URL withParameters:parameters executeRouteBlock:executeRouteBlock];
    }
    
    /// 如果还是找不到匹配的路由，回调 unmatchedURLHandler()
    if (!didRoute && executeRouteBlock && self.unmatchedURLHandler) {
        [self _verboseLog:@"Falling back to the unmatched URL handler"];
        self.unmatchedURLHandler(self, URL, parameters);
    }
    
    // 返回是否已路由
    return didRoute;
}

/// 判断当前对象是否是全局路由器
- (BOOL)_isGlobalRoutesController{
    return [self.scheme isEqualToString:JLRoutesGlobalRoutesScheme];
}

- (void)_verboseLog:(NSString *)format, ...
{
    if (!JLRGlobal_verboseLoggingEnabled || format.length == 0) {
        return;
    }
    
    va_list argsList;
    va_start(argsList, format);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
    NSString *formattedLogMessage = [[NSString alloc] initWithFormat:format arguments:argsList];
#pragma clang diagnostic pop
    
    va_end(argsList);
    NSLog(@"[JLRoutes]: %@", formattedLogMessage);
}

- (JLRRouteRequestOptions)_routeRequestOptions
{
    JLRRouteRequestOptions options = JLRRouteRequestOptionsNone;
    
    if (JLRGlobal_shouldDecodePlusSymbols) {
        options |= JLRRouteRequestOptionDecodePlusSymbols;
    }
    if (JLRGlobal_alwaysTreatsHostAsPathComponent) {
        options |= JLRRouteRequestOptionTreatHostAsPathComponent;
    }
    return options;
}

@end


#pragma mark - 全局配置

@implementation JLRoutes (GlobalOptions)

+ (void)setVerboseLoggingEnabled:(BOOL)loggingEnabled{
    JLRGlobal_verboseLoggingEnabled = loggingEnabled;
}

+ (BOOL)isVerboseLoggingEnabled{
    return JLRGlobal_verboseLoggingEnabled;
}

+ (void)setShouldDecodePlusSymbols:(BOOL)shouldDecode{
    JLRGlobal_shouldDecodePlusSymbols = shouldDecode;
}

+ (BOOL)shouldDecodePlusSymbols{
    return JLRGlobal_shouldDecodePlusSymbols;
}

+ (void)setAlwaysTreatsHostAsPathComponent:(BOOL)treatsHostAsPathComponent{
    JLRGlobal_alwaysTreatsHostAsPathComponent = treatsHostAsPathComponent;
}

+ (BOOL)alwaysTreatsHostAsPathComponent{
    return JLRGlobal_alwaysTreatsHostAsPathComponent;
}

+ (void)setDefaultRouteDefinitionClass:(Class)routeDefinitionClass{
    NSParameterAssert([routeDefinitionClass isSubclassOfClass:[JLRRouteDefinition class]]);
    JLRGlobal_routeDefinitionClass = routeDefinitionClass;
}

+ (Class)defaultRouteDefinitionClass{
    return JLRGlobal_routeDefinitionClass;
}

@end


#pragma mark - Deprecated

NSString *const kJLRoutePatternKey = @"JLRoutePattern";
NSString *const kJLRouteURLKey = @"JLRouteURL";
NSString *const kJLRouteSchemeKey = @"JLRouteScheme";
NSString *const kJLRouteWildcardComponentsKey = @"JLRouteWildcardComponents";
NSString *const kJLRoutesGlobalRoutesScheme = @"JLRoutesGlobalRoutesScheme";
NSString *const kJLRouteNamespaceKey = @"JLRouteScheme";
NSString *const kJLRoutesGlobalNamespaceKey = @"JLRoutesGlobalRoutesScheme";


@implementation JLRoutes (Deprecated)

+ (void)addRoute:(NSString *)routePattern handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock
{
    [[self globalRoutes] addRoute:routePattern handler:handlerBlock];
}

+ (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock
{
    [[self globalRoutes] addRoute:routePattern priority:priority handler:handlerBlock];
}

+ (void)addRoutes:(NSArray<NSString *> *)routePatterns handler:(BOOL (^)(NSDictionary<NSString *, id> *parameters))handlerBlock
{
    [[self globalRoutes] addRoutes:routePatterns handler:handlerBlock];
}

+ (void)removeRoute:(NSString *)routePattern
{
    [[self globalRoutes] removeRouteWithPattern:routePattern];
}

+ (void)removeAllRoutes
{
    [[self globalRoutes] removeAllRoutes];
}

+ (BOOL)canRouteURL:(NSURL *)URL withParameters:(NSDictionary *)parameters
{
    return [[self globalRoutes] canRouteURL:URL];
}

- (BOOL)canRouteURL:(NSURL *)URL withParameters:(NSDictionary *)parameters
{
    return [self canRouteURL:URL];
}

@end
