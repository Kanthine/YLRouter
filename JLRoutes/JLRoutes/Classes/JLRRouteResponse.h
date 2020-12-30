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


/** JLRRouteResponse 是对 JLRRouteRequest 响应结果的封装：
 * 包括匹配的参数（就是block返回的字典值）、是否匹配（输入的URL会循环匹配之前注册好的URL，如果匹配上返回YES，就会执行block）等内容
 */

@interface JLRRouteResponse : NSObject <NSCopying>

/// 指示响应是否匹配
@property (nonatomic, assign, readonly, getter=isMatch) BOOL match;

/// 匹配参数；响应无效时为 nil
@property (nonatomic, copy, readonly, nullable) NSDictionary *parameters;

/// 检查 RouteResponse 是否相等
- (BOOL)isEqualToRouteResponse:(JLRRouteResponse *)response;


///-------------------------------
/// @name 创建响应
///-------------------------------


/// 不匹配时， 返回一个无效的响应
+ (instancetype)invalidMatchResponse;

/** 根据指定的参数获取匹配的有效响应
 * @param parameters 指定的参数
 * @note 该响应有效
 */
+ (instancetype)validMatchResponseWithParameters:(NSDictionary *)parameters;

/// Unavailable, please use +invalidMatchResponse or +validMatchResponseWithParameters: instead.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable, please use +invalidMatchResponse or +validMatchResponseWithParameters: instead.
+ (instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
