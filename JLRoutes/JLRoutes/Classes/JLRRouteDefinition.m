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

- (instancetype)initWithPattern:(NSString *)pattern priority:(NSUInteger)priority handlerBlock:(BOOL (^)(NSDictionary *parameters))handlerBlock
{
    NSParameterAssert(pattern != nil);
    
    if ((self = [super init])) {
        self.pattern = pattern;
        self.priority = priority;
        self.handlerBlock = handlerBlock;
        
        if ([pattern characterAtIndex:0] == '/') {
            pattern = [pattern substringFromIndex:1];
        }
        
        self.patternPathComponents = [pattern componentsSeparatedByString:@"/"];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> - %@ (priority: %@)", NSStringFromClass([self class]), self, self.pattern, @(self.priority)];
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

/// 匹配阶段通过对注册内容进行查找，找到匹配项。并对匹配内容进行拼接，完成匹配pattern的匹配和变量赋值的操作
- (JLRRouteResponse *)routeResponseForRequest:(JLRRouteRequest *)request{
    /// 是否包含通配符 '*'
    BOOL patternContainsWildcard = [self.patternPathComponents containsObject:@"*"];
    
    /// 不包含通配符，路径组件的数量又不一样，返回一个无效的响应
    if (request.pathComponents.count != self.patternPathComponents.count && !patternContainsWildcard) {
        return [JLRRouteResponse invalidMatchResponse];
    }
    
    /// 3. 通过注册的patternComponent “:”来作为一个key，拿到对应的repuest中的patternComponent，组成一个键值对;
    /// 4. 如果非包含“:”的patternComponent与repuest中的patternComponent不符合，返回不匹配。
    NSDictionary *routeVariables = [self routeVariablesForRequest:request];
    
    if (routeVariables != nil) {
        // It's a match, set up the param dictionary and create a valid match response
        NSDictionary *matchParams = [self matchParametersForRequest:request routeVariables:routeVariables];
        return [JLRRouteResponse validMatchResponseWithParameters:matchParams];
    } else {
        /// 没有匹配的变量，返回一个无效响应
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
 * @param request 用于解析变量值的请求
 * 如果匹配，则解析routeVariables ;如果不匹配，则解析路由变量为nil
 */
- (NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(JLRRouteRequest *)request
{
    NSMutableDictionary *routeVariables = [NSMutableDictionary dictionary];
    
    BOOL isMatch = YES;
    NSUInteger index = 0;
    
    for (NSString *patternComponent in self.patternPathComponents) {
        NSString *URLComponent = nil;
        BOOL isPatternComponentWildcard = [patternComponent isEqualToString:@"*"];
        if (index < [request.pathComponents count]) {
            URLComponent = request.pathComponents[index];
        } else if (!isPatternComponentWildcard) {
            // URLComponent is not a wildcard and index is >= request.pathComponents.count, so bail
            isMatch = NO;
            break;
        }
        if ([patternComponent hasPrefix:@":"]) {
            // this is a variable, set it in the params
            NSAssert(URLComponent != nil, @"URLComponent cannot be nil");
            
            ///当字符串长度大于 1 时，去掉字符串开头的 ':' 与 字符串结尾的 '#'
            NSString *variableName = [self routeVariableNameForValue:patternComponent];
            
            ///对 URLComponent 解码，去掉字符串结尾的 '#'
            NSString *variableValue = [self routeVariableValueForValue:URLComponent];
            
            // Consult the parsing utilities as well to do any other standard variable transformations
            BOOL decodePlusSymbols = ((request.options & JLRRouteRequestOptionDecodePlusSymbols) == JLRRouteRequestOptionDecodePlusSymbols);
            variableValue = [JLRParsingUtilities variableValueFrom:variableValue decodePlusSymbols:decodePlusSymbols];
            
            routeVariables[variableName] = variableValue;
        } else if (isPatternComponentWildcard) {
            // match wildcards
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
            // break if this is a static component and it isn't a match
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
