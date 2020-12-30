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

/** JLRParsingUtilities 主要提供根据传入的匹配链接生成对应的合规的URI（仅仅将可选类型，拆解，例子如下）
 */
@interface JLRParsingUtilities : NSObject

/** 处理字符串中的 '+'
 * @param decodePlusSymbols 是否将字符串中的 '+' 替换为 @" "
 */
+ (NSString *)variableValueFrom:(NSString *)value decodePlusSymbols:(BOOL)decodePlusSymbols;

/** 处理字典中所有值中字符串包含的 '+'
 * @param decodePlusSymbols 是否将字符串中的 '+' 替换为 @" "
 */
+ (NSDictionary *)queryParams:(NSDictionary *)queryParams decodePlusSymbols:(BOOL)decodePlusSymbols;

/** 为 Pattern 展开可选的路由模式
 * eg： routePattern = @"/path/:thing/(/a)(/b)(/c)"
 * 创建以下路径:
 *      /path/:thing/a/b/c
 *      /path/:thing/a/b
 *      /path/:thing/a/c
 *      /path/:thing/b/a
 *      /path/:thing/a
 *      /path/:thing/b
 *      /path/:thing/c
 *
 *
 * 1、将 routePattern 解析为子路径对象
 * 2、提取出所需的子路径
 * 3、将子路径排列组合为可能的路由模式
 * 4、过滤掉实际上不满足规则的的路由模式
 * 5、将它们转换回我们可以注册的字符串路由
 * 6、按长度对它们进行排序
 */
+ (NSArray <NSString *> *)expandOptionalRoutePatternsForPattern:(NSString *)routePattern;

@end


NS_ASSUME_NONNULL_END
