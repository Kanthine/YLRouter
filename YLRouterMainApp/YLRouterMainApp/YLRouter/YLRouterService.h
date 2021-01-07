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
