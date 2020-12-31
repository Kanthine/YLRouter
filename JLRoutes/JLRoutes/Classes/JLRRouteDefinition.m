/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRRouteDefinition.h"
#import "JLRoutes.h"
#import "JLRParsingUtilities.h"


@interface JLRRouteDefinition ()

@property (nonatomic, copy) NSString *pattern;
@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, assign) NSUInteger priority;
@property (nonatomic, copy) NSArray *patternPathComponents;
@property (nonatomic, copy) BOOL (^handlerBlock)(NSDictionary *parameters);

@end


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
        
        self.patternPathComponents = [pattern componentsSeparatedByString:@"/"];
    }
    return self;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"<%@ %p %@> - %@ (priority: %@) \n patternPathComponents : %@", NSStringFromClass([self class]), self ,self.scheme, self.pattern, @(self.priority),self.patternPathComponents];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    
    if ([object isKindOfClass:[JLRRouteDefinition class]]) {
        return [self isEqualToRouteDefinition:(JLRRouteDefinition *)object];
    } else {
        return [super isEqual:object];
    }
}

- (BOOL)isEqualToRouteDefinition:(JLRRouteDefinition *)routeDefinition
{
    if (!((self.pattern == nil && routeDefinition.pattern == nil) || [self.pattern isEqualToString:routeDefinition.pattern])) {
        return NO;
    }
    
    if (!((self.scheme == nil && routeDefinition.scheme == nil) || [self.scheme isEqualToString:routeDefinition.scheme])) {
        return NO;
    }
    
    if (!((self.patternPathComponents == nil && routeDefinition.patternPathComponents == nil) || [self.patternPathComponents isEqualToArray:routeDefinition.patternPathComponents])) {
        return NO;
    }
    
    if (self.priority != routeDefinition.priority) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash{
    return self.pattern.hash ^ @(self.priority).hash ^ self.scheme.hash ^ self.patternPathComponents.hash;
}

#pragma mark - Main API

/** 匹配有效的响应，基于以下几个判断：
 * 1、不包含通配符，路径组件的数量又不一样，返回一个无效的响应；
 * 2、判断 request.pathComponents 与 RouteDefinition.patternPathComponents 相对位置的路径是否一致：
 *    如果一致，截取 URL 中的变量，
 *    如果不一致，则返回 routeVariables = nil ；表示不匹配
 * 3、将 request.url 的请求附加参数、变量参数、request.additionalParameters 合并为一个字典，封装一个有效的响应
 */
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

- (BOOL)callHandlerBlockWithParameters:(NSDictionary *)parameters{
    if (self.handlerBlock == nil) {
        return YES;
    }
    return self.handlerBlock(parameters);
}

- (void)didBecomeRegisteredForScheme:(NSString *)scheme
{
    NSAssert(self.scheme == nil, @"Route definitions should not be added to multiple schemes.");
    self.scheme = scheme;
}

#pragma mark - 解析 Route 变量

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

/**
 * 当字符串长度大于 1 时，去掉字符串开头的 ':'
 * 当字符串长度大于 1 时，去掉字符串结尾的 '#'
 */
- (NSString *)routeVariableNameForValue:(NSString *)value{
    NSString *name = value;
    /// 去掉字符串开头的 ':'
    if (name.length > 1 && [name characterAtIndex:0] == ':') {
        name = [name substringFromIndex:1];
    }
    
    /// 去掉字符串结尾的 '#'
    if (name.length > 1 && [name characterAtIndex:name.length - 1] == '#') {
        name = [name substringToIndex:name.length - 1];
    }
    
    return name;
}

/**
 * 如果字符串UTF-8 编码，则解码
 * 当字符串长度大于 1 时，去掉字符串结尾的 '#'
 */
- (NSString *)routeVariableValueForValue:(NSString *)value{
    /// 将所有 encoded UTF-8 编码的字符，还原为字符串
    NSString *var = [value stringByRemovingPercentEncoding];
    /// 去掉字符串结尾的 '#'
    if (var.length > 1 && [var characterAtIndex:var.length - 1] == '#') {
        var = [var substringToIndex:var.length - 1];
    }
    return var;
}

#pragma mark - Creating Match Parameters

- (NSDictionary *)matchParametersForRequest:(JLRRouteRequest *)request routeVariables:(NSDictionary <NSString *, NSString *> *)routeVariables
{
    NSMutableDictionary *matchParams = [NSMutableDictionary dictionary];
    
    // Add the parsed query parameters ('?a=b&c=d'). Also includes fragment.
    BOOL decodePlusSymbols = ((request.options & JLRRouteRequestOptionDecodePlusSymbols) == JLRRouteRequestOptionDecodePlusSymbols);
    [matchParams addEntriesFromDictionary:[JLRParsingUtilities queryParams:request.queryParams decodePlusSymbols:decodePlusSymbols]];
    
    // Add the actual parsed route variables (the items in the route prefixed with ':').
    [matchParams addEntriesFromDictionary:routeVariables];
    
    // Add the additional parameters, if any were specified in the request.
    if (request.additionalParameters != nil) {
        [matchParams addEntriesFromDictionary:request.additionalParameters];
    }
    
    // Finally, add the base parameters. This is done last so that these cannot be overriden by using the same key in your route or query.
    [matchParams addEntriesFromDictionary:[self defaultMatchParametersForRequest:request]];
    
    return [matchParams copy];
}

- (NSDictionary *)defaultMatchParametersForRequest:(JLRRouteRequest *)request
{
    return @{JLRoutePatternKey: self.pattern ?: [NSNull null], JLRouteURLKey: request.URL ?: [NSNull null], JLRouteSchemeKey: self.scheme ?: [NSNull null]};
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    JLRRouteDefinition *copy = [[[self class] alloc] initWithPattern:self.pattern priority:self.priority handlerBlock:self.handlerBlock];
    copy.scheme = self.scheme;
    return copy;
}

@end
