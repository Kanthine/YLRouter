//
//  MainTabBarController.h
//  YLRouterMainApp
//
//  Created by long on 2020/12/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainTabBarController : UITabBarController
+ (BOOL)setSelectedVC:(NSString *)name parameters:(NSDictionary *)parameters;
@end

NS_ASSUME_NONNULL_END
