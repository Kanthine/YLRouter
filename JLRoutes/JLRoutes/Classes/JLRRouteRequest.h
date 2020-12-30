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


/** JLRRouteRequest 是一个表示路由 URL 请求的模型，提供输入 URL 的分解；
 * 分解为scheme、path、param和fragment等；
 * 然后由 JLRRouteDefinition 使用该请求来尝试匹配，生成一个匹配的响应 JLRRouteRequest
 */
@interface JLRRouteRequest : NSObject

/// 路由的URL
@property (nonatomic, copy, readonly) NSURL *URL;

/// URL的路径组件
@property (nonatomic, strong, readonly) NSArray *pathComponents;

/// URL的查询参数
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/// 路由请求选项，一般从框架全局选项配置。
@property (nonatomic, assign, readonly) JLRRouteRequestOptions options;

/// 作为匹配参数的一部分传递的其他参数
@property (nonatomic, copy, nullable, readonly) NSDictionary *additionalParameters;


///-------------------------------
/// @name 创建一个路由请求
///-------------------------------


/** 创建一个路由请求
 * @param URL 路由的URL
 * @param options 一些配置
 * @param additionalParameters 在针对此请求创建的任何匹配字典中包含的其他参数。
 */
- (instancetype)initWithURL:(NSURL *)URL options:(JLRRouteRequestOptions)options additionalParameters:(nullable NSDictionary *)additionalParameters NS_DESIGNATED_INITIALIZER;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, use initWithURL:options:additionalParameters: instead.
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
