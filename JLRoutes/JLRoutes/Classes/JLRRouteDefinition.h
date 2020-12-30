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
#import "JLRRouteRequest.h"
#import "JLRRouteResponse.h"

NS_ASSUME_NONNULL_BEGIN


/**
 * JLRRouteDefinition 是一个表示注册路由的模型对象，包括 URL scheme、route pattern 和 priority
 * 这个类可以通过重写 -routeResponseForRequest: 子类来自定义路由解析行为
 * -callhandlerblockwithparameters也可以被重写，以自定义传递给handlerBlock的参数
 */

@interface JLRRouteDefinition : NSObject <NSCopying>

/// 该路由应用的 URL scheme， 如果是全局的则是 JLRoutesGlobalRoutesScheme
@property (nonatomic, copy, readonly) NSString *scheme;

/// The route pattern.
@property (nonatomic, copy, readonly) NSString *pattern;

/// 优先级
@property (nonatomic, assign, readonly) NSUInteger priority;

/// pattern 的路径组件
@property (nonatomic, copy, readonly) NSArray <NSString *> *patternPathComponents;

/// 当路由匹配时调用的 handlerBlock
@property (nonatomic, copy, readonly) BOOL (^handlerBlock)(NSDictionary *parameters);

/// 检查路由模型是否相等
- (BOOL)isEqualToRouteDefinition:(JLRRouteDefinition *)routeDefinition;


///----------------------------------
/// @name 创建路由模型
///----------------------------------

/** 创建一个新的路由模型
 * 已经创建的路由模型可以添加到JLRoutes实例的 mutableRoutes 数组中
 * @param pattern 完整的路由模式 ('/foo/:bar')
 * @param priority 优先级，默认为 0
 * @param handlerBlock 当匹配成功时处理事件的回调
 */
- (instancetype)initWithPattern:(NSString *)pattern priority:(NSUInteger)priority handlerBlock:(BOOL (^)(NSDictionary *parameters))handlerBlock NS_DESIGNATED_INITIALIZER;

/// Unavailable, use initWithScheme:pattern:priority:handlerBlock: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, use initWithScheme:pattern:priority:handlerBlock: instead.
+ (instancetype)new NS_UNAVAILABLE;


///----------------------------------
/// @name Responding To Registration
///----------------------------------

/// 路由注册时，需要配置对应的 scheme
- (void)didBecomeRegisteredForScheme:(NSString *)scheme;


///-------------------------------
/// @name 匹配 Route 请求
///-------------------------------

/** 为所提供的JLRRouteRequest创建并返回JLRRouteResponse；
 * @param request 用于创建响应的请求 JLRRouteRequest
 * @returns 创建的响应，指示是否匹配请求
 */
- (JLRRouteResponse *)routeResponseForRequest:(JLRRouteRequest *)request;


/** 匹配成功后，使用指定的参数调用路由模型对象的 handlerBlock
 * @param parameters 传递给handlerBlock的参数
 * @note 可能会被子类覆盖
 * @returns 调用handlerBlock的返回值(如果被视为已经处理了则返回YES，否则返回NO)
 */
- (BOOL)callHandlerBlockWithParameters:(NSDictionary *)parameters;


///---------------------------------
/// @name 创建匹配参数
///---------------------------------

/** 创建并返回完整的匹配参数集合，作为有效匹配的一部分传递
 * @note 子类可以重写这个方法来改变匹配参数，或者直接调用它来生成期望的值。
 * @param request 路由请求
 * @param routeVariables 解析的路由变量 (aka a route of '/route/:param' being routed with '/foo/bar' would create [ 'param' : 'bar' ])
 * @returns 完整的匹配参数集合，作为有效匹配的一部分传递
 */
- (NSDictionary *)matchParametersForRequest:(JLRRouteRequest *)request routeVariables:(NSDictionary <NSString *, NSString *> *)routeVariables;


/** 创建并返回给定请求的默认基本匹配参数。不包括任何已解析的字段。
 * @param request 路由请求
 * @returns 给定请求的默认匹配参数。仅包含JLRoutePatternKey、JLRouteURLKey和JLRouteSchemeKey的键/值对。
 */
- (NSDictionary *)defaultMatchParametersForRequest:(JLRRouteRequest *)request;


///-------------------------------
/// @name 解析 Route 变量
///-------------------------------

/** 解析并返回指定请求的路由变量
 * @param request 用于解析变量值的请求
 * 如果匹配，则解析routeVariables ;如果不匹配，则解析路由变量为nil
 *
 * 例如注册路由为 YLRouterMain://mainTabBar/:name
 * 则发起        YLRouterMain://mainTabBar/user
 * 解析变量 @{"name":"user"}
 */
- (nullable NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(JLRRouteRequest *)request;

/**
 * 当字符串长度大于 1 时，去掉字符串开头的 ':'
 * 当字符串长度大于 1 时，去掉字符串结尾的 '#'
 */
- (NSString *)routeVariableNameForValue:(NSString *)value;

/**
 * 如果字符串UTF-8 编码，则解码
 * 当字符串长度大于 1 时，去掉字符串结尾的 '#'
 */
- (NSString *)routeVariableValueForValue:(NSString *)value;

@end


NS_ASSUME_NONNULL_END
