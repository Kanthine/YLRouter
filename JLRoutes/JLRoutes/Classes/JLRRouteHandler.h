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


/** Deeplink，简单讲，就是你在手机上点击一个链接之后，可以直接链接到app内部的某个页面，而不是app正常打开时显示的首页。
 不似web，一个链接就可以直接打开web的内页，app的内页打开，必须用到deeplink技术
 */

@protocol JLRRouteHandlerTarget;


/** 封装了 Handler
 * 这对于你想要一个单独的对象或类作为 deeplink 路由的处理程序的情况特别有用
 * eg：一个视图控制器类，你想要实例化并呈现它以响应一个 deeplink 路由
 */
@interface JLRRouteHandler : NSObject

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable.
+ (instancetype)new NS_UNAVAILABLE;


/** 在弱目标对象上创建并返回一个调用 handleRouteWithParameters: 的块。
 
 The block returned from this method should be passed as the handler block of an addRoute: call.
 
 @param weakTarget The target object that should handle a matched route.
 
 @returns A new handler block for the provided weakTarget.
 
 @discussion There is no change of ownership of the target object, only a weak pointer (hence 'weakTarget') is captured in the block.
 If the object is deallocated, the handler will no longer be called (but the route will remain registered unless explicitly removed).
 */
// 创建并返回一个在weak属性目标对象上调用handleRouteWithParameters:方法的block。从此方法返回的block应该作为addRoute:的handler block。
// 参数weakTarget: 应该处理匹配路由的目标对象
// 返回值 提供的weakTarget的新处理块
// 讨论：目标对象的拥有者没有变化，只有一个弱指针在block中被捕获。如果该对象被重新分配，则handler将不再被调用(但路由将保持注册，除非明确移除)
+ (BOOL (^__nonnull)(NSDictionary<NSString *, id> *parameters))handlerBlockForWeakTarget:(__weak id <JLRRouteHandlerTarget>)weakTarget;


/**
 Creates and returns a block that creates a new instance of targetClass (which must conform to JLRRouteHandlerTarget), and then calls
 handleRouteWithParameters: on it. The created object is then passed as the parameter to the completion block.
 
 The block returned from this method should be passed as the handler block of an addRoute: call.
 
 @param targetClass The target class to create for handling the route request. Must conform to JLRRouteHandlerTarget.
 @param completionHandler The completion block to call after creating the new targetClass instance.
 
 @returns A new handler block for creating instances of targetClass.
 
 @discussion JLRoutes does not retain or own the created object. It's expected that the created object that is passed through the completion handler
 will be used and owned by the calling application.
 */

// 创建并返回一个创建新实例的targetClass(此targetClass必须遵守JLRRouteHandlerTarget协议)的block，然后在它上调用handleRouteWithParameters:方法。然后创建的对象作为参数传递给完成的block块。从此方法返回的block应该作为addRoute:的handler block。
// 参数targetClass: 要处理路由请求的目标类。必须遵守JLRRouteHandlerTarget协议。
// 参数completionHandler: 创建了一个新targetClass实例后调用的完成块。
// 返回值 用于创建targetClass实例的新的handler block。
// 讨论：JLRoutes不会保留或拥有此创建的对象。预计通过完成的回调传递的创建对象将被调用应用程序使用并拥有。
+ (BOOL (^__nonnull)(NSDictionary<NSString *, id> *parameters))handlerBlockForTargetClass:(Class)targetClass completion:(BOOL (^)(id <JLRRouteHandlerTarget> createdObject))completionHandler;

@end


/// 遵守此协议的类可以被用来作为路由处理目标
@protocol JLRRouteHandlerTarget <NSObject>

@optional

/** 从JLRoutes路由里通过传递匹配的路由参数初始化一个遵守此协议的类的实例
 * @param parameters 初始化对象时传递的匹配参数。这些都是从JLRoutes 的 handlerBlock 中传递的
 */
- (instancetype)initWithRouteParameters:(NSDictionary <NSString *, id> *)parameters;

/** 被匹配的路由调用
 * @param parameters 传递给 handlerBlock 的参数
 * @returns 如果路由已经处理则返回 YES，如果应该尝试匹配不同的路由则返回 NO
 */
- (BOOL)handleRouteWithParameters:(NSDictionary<NSString *, id> *)parameters;

@end


NS_ASSUME_NONNULL_END
