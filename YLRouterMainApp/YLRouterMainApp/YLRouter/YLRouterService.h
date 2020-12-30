//
//  YLRouterService.h
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//

#import <Foundation/Foundation.h>
#import "YLRouterConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface YLRouterService : NSObject

+ (BOOL)openURL:(NSString *)url;//调用 Router;
+ (BOOL)openURL:(NSString *)url parameters:(NSDictionary *)parameters;

+ (void)addRoute:(NSString* )route handler:(BOOL (^)(NSDictionary *parameters))handlerBlock;//注册 Router,调用 Router 时会触发回调;

@end


@interface YLRouterService (Handler)

@end

NS_ASSUME_NONNULL_END


/**
 
 
 1、JLRouts中有一个全局可变字典JLRGlobal_routeControllersMap, 该字典是以scheme为key，以JLRoutes对象为value；
 2、JLRoutes对象有一个可变数组mutableRoutes，里面存放着JLRRouteDefinition对象，该对象的scheme是JLRoutes的scheme，并且有一个优先级属性priority;
 3、mutableRoutes每次添加JLRRouteDefinition对象时都会进行插入排序，优先级从高到底。
 4、调用routesForScheme：方法时，会将scheme添加到JLRGlobal_routeControllersMap字典中。
 5、调用addRoute:方法时，会创建JLRRouteDefinition路由模型对象添加到mutableRoutes数组中。JLRRouteDefinition路由模型对象会保存addRoute:传递进来的handlerBlock。
 6、调用routeURL：方法时，会根据传递进来的参数创建JLRRouteRequest对象，并遍历mutableRoutes数组，找到与之匹配的JLRRouteResponse对象，处理handlerBlock。 
 */
