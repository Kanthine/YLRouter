/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "JLRRouteDefinition.h"
#import "JLRRouteHandler.h"
#import "JLRRouteRequest.h"
#import "JLRRouteResponse.h"

NS_ASSUME_NONNULL_BEGIN

/// The matching route pattern, passed in the handler parameters.
extern NSString *const JLRoutePatternKey;

/// The original URL that was routed, passed in the handler parameters.
extern NSString *const JLRouteURLKey;

/// The matching route scheme, passed in the handler parameters.
extern NSString *const JLRouteSchemeKey;

/// The wildcard components (if present) of the matching route, passed in the handler parameters.
extern NSString *const JLRouteWildcardComponentsKey;

/// The global routes namespace.
/// @see JLRoutes +globalRoutes
extern NSString *const JLRoutesGlobalRoutesScheme;



/** JLRoutes 类是 JLRoutes 框架的主要入口点: 用于访问 Schemes、管理 routes 、routing URLs
 *
 * JLRoutes 是通过解析URL不同的参数，并用block回调的方式处理页面间的传值以及跳转。
 * 其本质就是在程序中注册一个全局的字典，key是URL scheme，value是一个参数为字典的block回调。
 */

@interface JLRoutes : NSObject

/// 控制这个路由器如果在当前命名空间中不能匹配，是否尝试将URL与全局路由匹配。默认为NO。
@property (nonatomic, assign) BOOL shouldFallbackToGlobalRoutes;


//  任何时候调用routeURL返回NO的回调。与 shouldFallbackToGlobalRoutes 属性相关
@property (nonatomic, copy, nullable) void (^unmatchedURLHandler)(JLRoutes *routes, NSURL *__nullable URL, NSDictionary<NSString *, id> *__nullable parameters);


///-------------------------------
/// @name Routing Schemes
///-------------------------------


/// 获取全局的 routing scheme
+ (instancetype)globalRoutes;

/** 获取指定 Scheme 的路由
 * @param scheme 指定的Scheme；如果不设置，则默认 scheme为  JLRoutesGlobalRoutesScheme
 * 通过设置 scheme ，对route细分化，可以方便查找！
 * 如果不设置，所有的route都放在同一个 scheme 下，在内容量大的情况下会导致读取的缓慢。
 */
+ (instancetype)routesForScheme:(NSString *)scheme;

/// 注销并删除给定 Scheme 的路由
+ (void)unregisterRouteScheme:(NSString *)scheme;

/// 注销所有路由
+ (void)unregisterAllRouteSchemes;


///-------------------------------
/// @name 管理 Routes
///-------------------------------

/** 注册路由：
 * @param routePattern 在注册阶段已经进行赋值，不需要别的操作
 * @param priority 优先级，默认为 0；用途在存入数组中排队顺序，数值越大，在数组中排的位置越靠前。
 * @param handler 处理路由时间，返回值表示是否处理
 *                返回一个BOOL值，表示 handlerBlock 是否真的处理了该路由。如果返回NO, JLRoutes将继续寻找匹配的路由
 * @param routeDefinition 定制路由逻辑：将每一条注册数据（pattern、priority、handler）封装在JLRouteDefinition对象中
 */
- (void)addRoute:(JLRRouteDefinition *)routeDefinition;
- (void)addRoute:(NSString *)routePattern handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock;
- (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock;
- (void)addRoutes:(NSArray<NSString *> *)routePatterns handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock;

// 从接收scheme中移除路由
- (void)removeRoute:(JLRRouteDefinition *)routeDefinition;

/// Removes the first route matching routePattern from the receiving scheme.
// 从接收scheme中移除第一个匹配此路由模式的路由
- (void)removeRouteWithPattern:(NSString *)routePattern;

/// 从接收scheme中移除所有路由
/// Removes all routes from the receiving scheme.
- (void)removeAllRoutes;

/// 使用字典风格的下标注册一个具有默认优先级(0)的路由模式
/// Registers a routePattern with default priority (0) using dictionary-style subscripting.
- (void)setObject:(nullable id)handlerBlock forKeyedSubscript:(NSString *)routePatten;

/// 返回在接收scheme中的所有已注册路由
- (NSArray <JLRRouteDefinition *> *)routes;

/// 返回所有已注册路由: keyed 是scheme ,value 为对应的已注册路由
+ (NSDictionary <NSString *, NSArray <JLRRouteDefinition *> *> *)allRoutes;


///-------------------------------
/// @name Routing URLs
///-------------------------------


/// 如果提供的 URL 可以成功匹配任一个已注册的路由，则返回YES。否则返回NO。
+ (BOOL)canRouteURL:(nullable NSURL *)URL;

/// 如果提供的 ULR 可以成功为当前scheme匹配任一个已注册的路由，则返回YES。否则返回NO。
- (BOOL)canRouteURL:(nullable NSURL *)URL;

/** 路由一个URL，为与此 URL 相匹配的模式调用 handlerBlock，直到找到了相匹配的模式，返回YES
 *  如果没有找到匹配的路由，将调用提前设置的 unmatchedURLHandler
 *  @param parameters  一些参数信息，传送至匹配的 route block
 */
+ (BOOL)routeURL:(nullable NSURL *)URL;
+ (BOOL)routeURL:(nullable NSURL *)URL withParameters:(nullable NSDictionary<NSString *, id> *)parameters;


/** 在特定scheme内路由一个URL，为与此URL相匹配的模式调用 handlerBlock，直到找到了相匹配的模式，返回YES。
 *  如果没有找到匹配的路由，将调用提前设置的 unmatchedURLHandler
 *  @param parameters  一些参数信息，传送至匹配的 route block
 */
- (BOOL)routeURL:(nullable NSURL *)URL;
- (BOOL)routeURL:(nullable NSURL *)URL withParameters:(nullable NSDictionary<NSString *, id> *)parameters;

@end


// Global settings to use for parsing and routing.
@interface JLRoutes (GlobalOptions)

///----------------------------------
/// @name 一些全局配置
///----------------------------------

/// 配置日志记录，默认为 NO
+ (void)setVerboseLoggingEnabled:(BOOL)loggingEnabled;

/// 当前日志记录启用状态；默认为 NO
+ (BOOL)isVerboseLoggingEnabled;

/// 配置: 解析值中的'+'是否应该被替换为空格。默认为 YES，替换
+ (void)setShouldDecodePlusSymbols:(BOOL)shouldDecode;

/// 是否将解析值中的'+'是否应该被替换为空格。默认为 YES，替换
+ (BOOL)shouldDecodePlusSymbols;

/// 配置: URL host 是否始终被视为路径组件。默认为NO。
+ (void)setAlwaysTreatsHostAsPathComponent:(BOOL)treatsHostAsPathComponent;

///  判断 URL host 是否始终被视为路径组件。默认为NO。
+ (BOOL)alwaysTreatsHostAsPathComponent;

/// 配置: 创建 Route 时使用的默认类; 默认为 JLRRouteDefinition
+ (void)setDefaultRouteDefinitionClass:(Class)routeDefinitionClass;

/// 获取创建 Route 时使用的类; 默认为JLRRouteDefinition
+ (Class)defaultRouteDefinitionClass;

@end



#pragma mark - Deprecated

extern NSString *const kJLRoutePatternKey               DEPRECATED_MSG_ATTRIBUTE("Use JLRoutePatternKey instead.");
extern NSString *const kJLRouteURLKey                   DEPRECATED_MSG_ATTRIBUTE("Use JLRouteURLKey instead.");
extern NSString *const kJLRouteSchemeKey                DEPRECATED_MSG_ATTRIBUTE("Use JLRouteSchemeKey instead.");
extern NSString *const kJLRouteWildcardComponentsKey    DEPRECATED_MSG_ATTRIBUTE("Use JLRouteWildcardComponentsKey instead.");
extern NSString *const kJLRoutesGlobalRoutesScheme      DEPRECATED_MSG_ATTRIBUTE("Use JLRoutesGlobalRoutesScheme instead.");
extern NSString *const kJLRouteNamespaceKey             DEPRECATED_MSG_ATTRIBUTE("Use JLRouteSchemeKey instead.");
extern NSString *const kJLRoutesGlobalNamespaceKey      DEPRECATED_MSG_ATTRIBUTE("Use JLRoutesGlobalRoutesScheme instead.");


@interface JLRoutes (Deprecated)

///----------------------------------
/// @name Deprecated Methods
///----------------------------------

/// Use the matching instance method on +globalRoutes instead.
+ (void)addRoute:(NSString *)routePattern handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock DEPRECATED_MSG_ATTRIBUTE("Use the matching instance method on +globalRoutes instead.");

/// Use the matching instance method on +globalRoutes instead.
+ (void)addRoute:(NSString *)routePattern priority:(NSUInteger)priority handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock DEPRECATED_MSG_ATTRIBUTE("Use the matching instance method on +globalRoutes instead.");

/// Use the matching instance method on +globalRoutes instead.
+ (void)addRoutes:(NSArray<NSString *> *)routePatterns handler:(BOOL (^__nullable)(NSDictionary<NSString *, id> *parameters))handlerBlock DEPRECATED_MSG_ATTRIBUTE("Use the matching instance method on +globalRoutes instead.");

/// Use the matching instance method on +globalRoutes instead.
+ (void)removeRoute:(NSString *)routePattern DEPRECATED_MSG_ATTRIBUTE("Use the matching instance method on +globalRoutes instead.");

/// Use the matching instance method on +globalRoutes instead.
+ (void)removeAllRoutes DEPRECATED_MSG_ATTRIBUTE("Use the matching instance method on +globalRoutes instead.");

/// Use +canRouteURL: instead.
+ (BOOL)canRouteURL:(nullable NSURL *)URL withParameters:(nullable NSDictionary<NSString *, id> *)parameters DEPRECATED_MSG_ATTRIBUTE("Use +canRouteURL: instead.");

/// Use +canRouteURL: instead.
- (BOOL)canRouteURL:(nullable NSURL *)URL withParameters:(nullable NSDictionary<NSString *, id> *)parameters DEPRECATED_MSG_ATTRIBUTE("Use -canRouteURL: instead.");

@end


NS_ASSUME_NONNULL_END
