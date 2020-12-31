//
//  AppDelegate.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/26.
//


#import "AppDelegate.h"
#import "MainTabBarController.h"
#import <JLRoutes/JLRRouteRequest.h>
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window makeKeyAndVisible];
    
    MainTabBarController *mainTabBar = [[MainTabBarController alloc] init];
    self.window.rootViewController = mainTabBar;
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options{
    NSLog(@"url ==== %@",url);
    return YES;
    return [YLRouterService openURL:url.absoluteString];
}

@end
