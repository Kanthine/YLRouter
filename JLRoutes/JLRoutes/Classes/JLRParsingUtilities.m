/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JLRParsingUtilities.h"


@interface NSArray (JLRoutes_Utilities)

- (NSArray<NSArray *> *)JLRoutes_allOrderedCombinations;
- (NSArray *)JLRoutes_filter:(BOOL (^)(id object))filterBlock;
- (NSArray *)JLRoutes_map:(id (^)(id object))mapBlock;

@end


@interface NSString (JLRoutes_Utilities)

/** 过滤掉字符串首尾的 ‘/’
 *  以‘/’ 分割字符串，获取一个数组
 */
- (NSArray <NSString *> *)JLRoutes_trimmedPathComponents;

@end


#pragma mark - Parsing Utility Methods

/// 子路径
@interface JLRParsingUtilities_RouteSubpath : NSObject

@property (nonatomic, strong) NSArray <NSString *> *subpathComponents;
@property (nonatomic, assign) BOOL isOptionalSubpath;/// 是否可选

@end
@implementation JLRParsingUtilities_RouteSubpath

- (NSString *)description
{
    NSString *type = self.isOptionalSubpath ? @"OPTIONAL" : @"REQUIRED";
    return [NSString stringWithFormat:@"%@ - %@: %@", [super description], type, [self.subpathComponents componentsJoinedByString:@"/"]];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    JLRParsingUtilities_RouteSubpath *otherSubpath = (JLRParsingUtilities_RouteSubpath *)object;
    if (![self.subpathComponents isEqual:otherSubpath.subpathComponents]) {
        return NO;
    }
    
    if (self.isOptionalSubpath != otherSubpath.isOptionalSubpath) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return self.subpathComponents.hash ^ self.isOptionalSubpath;
}

@end


@implementation JLRParsingUtilities


/** 处理字符串中的 '+'
 * @param decodePlusSymbols 是否将字符串中的 '+' 替换为 @" "
 */
+ (NSString *)variableValueFrom:(NSString *)value decodePlusSymbols:(BOOL)decodePlusSymbols{
    if (!decodePlusSymbols) {
        return value;
    }
    return [value stringByReplacingOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, value.length)];
}

/** 处理字典中所有值中字符串包含的 '+'
 * @param decodePlusSymbols 是否将字符串中的 '+' 替换为 @" "
 */
+ (NSDictionary *)queryParams:(NSDictionary *)queryParams decodePlusSymbols:(BOOL)decodePlusSymbols{
    if (!decodePlusSymbols) {
        return queryParams;
    }
    
    NSMutableDictionary *updatedQueryParams = [NSMutableDictionary dictionary];
    
    for (NSString *key in queryParams) {
        id value = queryParams[key];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *variables = [NSMutableArray array];
            for (NSString *arrayValue in (NSArray *)value) {
                [variables addObject:[self variableValueFrom:arrayValue decodePlusSymbols:YES]];
            }
            updatedQueryParams[key] = [variables copy];
        } else if ([value isKindOfClass:[NSString class]]) {
            NSString *variable = [self variableValueFrom:value decodePlusSymbols:YES];
            updatedQueryParams[key] = variable;
        } else {
            NSAssert(NO, @"Unexpected query parameter type: %@", NSStringFromClass([value class]));
        }
    }
    return [updatedQueryParams copy];
}

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
+ (NSArray <NSString *> *)expandOptionalRoutePatternsForPattern:(NSString *)routePattern{
    if ([routePattern rangeOfString:@"("].location == NSNotFound) {
        return @[];
    }
    
    /// 首先，将 routePattern 解析为子路径对象
    NSArray <JLRParsingUtilities_RouteSubpath *> *subpaths = [self _routeSubpathsForPattern:routePattern];
    if (subpaths.count == 0) {
        return @[];
    }
    
    /// 接下来，提取出所需的子路径
    NSSet <JLRParsingUtilities_RouteSubpath *> *requiredSubpaths = [NSSet setWithArray:[subpaths JLRoutes_filter:^BOOL(JLRParsingUtilities_RouteSubpath *subpath) {
        return !subpath.isOptionalSubpath;
    }]];
    
    /// 然后，将子路径排列组合为可能的路由模式
    NSArray <NSArray <JLRParsingUtilities_RouteSubpath *> *> *allSubpathCombinations = [subpaths JLRoutes_allOrderedCombinations];
    
    /// 最后，过滤掉实际上不满足规则的的路由模式
    /// allSubpathCombinations 中的元素数组： subpath 没有必选的，该组元素过滤掉
    NSArray <NSArray <JLRParsingUtilities_RouteSubpath *> *> *validSubpathCombinations = [allSubpathCombinations JLRoutes_filter:^BOOL(NSArray <JLRParsingUtilities_RouteSubpath *> *possibleRouteSubpaths) {
        return [requiredSubpaths isSubsetOfSet:[NSSet setWithArray:possibleRouteSubpaths]];
    }];

    /// 此时拥有有效子路径的过滤列表，只需要将它们转换回我们可以注册的字符串路由。
    NSArray <NSString *> *validSubpathRouteStrings = [validSubpathCombinations JLRoutes_map:^id(NSArray <JLRParsingUtilities_RouteSubpath *> *subpaths) {
        NSString *routePattern = @"/";
        for (JLRParsingUtilities_RouteSubpath *subpath in subpaths) {
            NSString *subpathString = [subpath.subpathComponents componentsJoinedByString:@"/"];
            routePattern = [routePattern stringByAppendingPathComponent:subpathString];
        }
        return routePattern;
    }];

    // 按长度对它们进行排序，
    validSubpathRouteStrings = [validSubpathRouteStrings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"length" ascending:NO selector:@selector(compare:)]]];
    return validSubpathRouteStrings;
}


+ (NSArray <JLRParsingUtilities_RouteSubpath *> *)_routeSubpathsForPattern:(NSString *)routePattern
{
    NSMutableArray <JLRParsingUtilities_RouteSubpath *> *subpaths = [NSMutableArray array];
    
    /** NSScanner : 用于在字符串中扫描指定的字符，尤其是把它们翻译/转换为数字和别的字符串；
     *  可以在创建 NSScaner 时指定它的 string 属性，然后scanner会按照你的要求从头到尾地扫描这个字符串的每个字符。
     *  默认的忽略字符是空格和回车字符
     *
     *  scanner.scanLocation 指定扫描开始的位置
     *  scanner.isAtEnd 是否扫描到末尾
     */
    NSScanner *scanner = [NSScanner scannerWithString:routePattern];
    while (![scanner isAtEnd]) {/// isAtEnd 是否扫描到末尾
        NSString *preOptionalSubpath = nil;
        
        /// 从当前的扫描位置开始扫描，扫描到和传入的字符串相同字符串时停止，指针指向的地址存储的是遇到传入字符串之前的内容
        /// 例如 scanner 的 string 内容为 123abc678,传入的字符串内容为abc，存储的内容为 123
        BOOL didScan = [scanner scanUpToString:@"(" intoString:&preOptionalSubpath];
        if (!didScan) {
            NSAssert([routePattern characterAtIndex:scanner.scanLocation] == '(', @"Unexpected character: %c", [routePattern characterAtIndex:scanner.scanLocation]);
        }
        
        if (!scanner.isAtEnd) {
            // 否则，跳过 '('
            scanner.scanLocation = scanner.scanLocation + 1;/// scanLocation 指定扫描开始的位置
        }
        
        if (preOptionalSubpath.length > 0 && ![preOptionalSubpath isEqualToString:@")"] && ![preOptionalSubpath isEqualToString:@"/"]) {
            // content before the start of an optional subpath
            JLRParsingUtilities_RouteSubpath *subpath = [[JLRParsingUtilities_RouteSubpath alloc] init];
            subpath.subpathComponents = [preOptionalSubpath JLRoutes_trimmedPathComponents];
            [subpaths addObject:subpath];
        }
        
        if (scanner.isAtEnd) {
            break;
        }
        
        NSString *optionalSubpath = nil;
        didScan = [scanner scanUpToString:@")" intoString:&optionalSubpath];
        NSAssert(didScan, @"Could not find closing parenthesis");
        
        scanner.scanLocation = scanner.scanLocation + 1;
        
        if (optionalSubpath.length > 0) {
            JLRParsingUtilities_RouteSubpath *subpath = [[JLRParsingUtilities_RouteSubpath alloc] init];
            subpath.isOptionalSubpath = YES;
            subpath.subpathComponents = [optionalSubpath JLRoutes_trimmedPathComponents];
            [subpaths addObject:subpath];
        }
    }
    return [subpaths copy];
}

@end


#pragma mark - Categories


@implementation NSArray (JLRoutes_Utilities)

/** 数组中所有元素的排列组合
 * 如：@[@"1",@"3",@"2"]
 *
 * ( (), (1), (3), (1,3), (2), (1,2), (3,2), (1,3,2) )
 *
 */
- (NSArray<NSArray *> *)JLRoutes_allOrderedCombinations
{
    NSInteger length = self.count;
    if (length == 0) {
        return [NSArray arrayWithObject:[NSArray array]];
    }
    
    id lastObject = [self lastObject];
    NSArray *subarray = [self subarrayWithRange:NSMakeRange(0, length - 1)];
    NSArray *subarrayCombinations = [subarray JLRoutes_allOrderedCombinations];
    NSMutableArray *combinations = [NSMutableArray arrayWithArray:subarrayCombinations];
    
    for (NSArray *subarrayCombos in subarrayCombinations) {
        [combinations addObject:[subarrayCombos arrayByAddingObject:lastObject]];
    }
    
    return [NSArray arrayWithArray:combinations];
}

- (NSArray *)JLRoutes_filter:(BOOL (^)(id object))filterBlock
{
    NSParameterAssert(filterBlock != nil);
    NSMutableArray *filteredArray = [NSMutableArray array];
    
    for (id object in self) {
        if (filterBlock(object)) {
            [filteredArray addObject:object];
        }
    }
    
    return [filteredArray copy];
}

- (NSArray *)JLRoutes_map:(id (^)(id object))mapBlock
{
    NSParameterAssert(mapBlock != nil);
    NSMutableArray *mappedArray = [NSMutableArray array];
    
    for (id object in self) {
        id mappedObject = mapBlock(object);
        [mappedArray addObject:mappedObject];
    }
    
    return [mappedArray copy];
}

@end


@implementation NSString (JLRoutes_Utilities)

/** 过滤掉字符串首尾的 ‘/’
 *  以‘/’ 分割字符串，获取一个数组
 */
- (NSArray <NSString *> *)JLRoutes_trimmedPathComponents
{
    // Trims leading and trailing slashes and then separates by slash
    return [[self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] componentsSeparatedByString:@"/"];
}

@end

