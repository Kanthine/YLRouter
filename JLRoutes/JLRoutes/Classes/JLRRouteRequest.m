/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRRouteRequest.h"


@interface JLRRouteRequest ()

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, strong) NSArray *pathComponents;
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, assign) JLRRouteRequestOptions options;
@property (nonatomic, copy) NSDictionary *additionalParameters;

@end


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

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> - URL: %@\n pathComponents : %@\n queryParams : %@\n additionalParameters : %@", NSStringFromClass([self class]), self, [self.URL absoluteString],self.pathComponents,self.queryParams,self.additionalParameters];
}

@end
