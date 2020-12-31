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

NS_ASSUME_NONNULL_BEGIN


/// Options bitmask generated from JLRoutes global options methods.
typedef NS_OPTIONS(NSUInteger, JLRRouteRequestOptions) {
    /// No options specified.
    JLRRouteRequestOptionsNone = 0,
    
    /// If present, decoding plus symbols is enabled.
    JLRRouteRequestOptionDecodePlusSymbols = 1 << 0,
    
    /// If present, treating URL hosts as path components is enabled.
    JLRRouteRequestOptionTreatHostAsPathComponent = 1 << 1
};

@interface JLRRouteRequest : NSObject

/// 路由的URL
@property (nonatomic, copy, readonly) NSURL *URL;

/// URL的路径组件
@property (nonatomic, strong, readonly) NSArray *pathComponents;

/// URL 中的拼接参数
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/// 路由请求选项，一般从框架全局选项配置。
@property (nonatomic, assign, readonly) JLRRouteRequestOptions options;

/// 作为匹配参数的一部分传递的其他参数
@property (nonatomic, copy, nullable, readonly) NSDictionary *additionalParameters;

/** JLRRouteRequest 的初始化方法
 *  1、使用 NSURLComponents 将一个 URL 拆分为 scheme、host、port、path、query、fragment 等；
 *  2、 将 components.host 拼接到 path 中 ？
 *          条件一：components.host.length > 0；
 *          条件二：（components.host 不是 localhost 并且 components.host 不包含 .） || 配置项
 *     如果将 components.host 拼接到 path 中，则 JLRRouteRequest.pathComponents 包含 host 并且 包含 path
 *  3、 将 URL 的附带参数 components.queryItems 转为字典格式 JLRRouteRequest.queryParams
 */
- (instancetype)initWithURL:(NSURL *)URL options:(JLRRouteRequestOptions)options additionalParameters:(nullable NSDictionary *)additionalParameters NS_DESIGNATED_INITIALIZER;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
