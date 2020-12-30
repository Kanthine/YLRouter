//
//  MainTabBarController.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/29.
//

#import "MainTabBarController.h"
#import "NewsHomeViewController.h"
#import "UserHomeViewController.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.whiteColor;
    
    NewsHomeViewController *newsVC = [[NewsHomeViewController alloc] init];
    UINavigationController *newsNav = [[UINavigationController alloc] initWithRootViewController:newsVC];
    newsNav.tabBarItem.title = @"新闻";
    
    UserHomeViewController *userVC = [[UserHomeViewController alloc] init];
    UINavigationController *usersNav = [[UINavigationController alloc] initWithRootViewController:userVC];
    usersNav.tabBarItem.title = @"个人";
    
    [self setViewControllers:@[newsNav,usersNav]];
}


+ (BOOL)setSelectedVC:(NSString *)name parameters:(NSDictionary *)parameters{
    MainTabBarController *tabBarController = (MainTabBarController *)UIApplication.sharedApplication.delegate.window.rootViewController;
    if (![tabBarController isKindOfClass:MainTabBarController.class]) {
        return NO;
    }
    
    ///返回最上级
    UINavigationController *nav = tabBarController.selectedViewController;
    [nav popToRootViewControllerAnimated:NO];
    
    if ([name isEqualToString:@"News"]) {
        tabBarController.selectedIndex = 0;
    }else if ([name isEqualToString:@"User"]) {
        tabBarController.selectedIndex = 1;
    }
    return NO;
}

@end
