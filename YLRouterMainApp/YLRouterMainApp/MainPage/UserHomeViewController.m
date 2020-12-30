//
//  UserHomeViewController.m
//  YLRouterMainApp
//
//  Created by long on 2020/12/29.
//

#import "UserHomeViewController.h"

@interface UserHomeViewController ()

@end

@implementation UserHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.blueColor;
    self.navigationItem.title = @"个人中心";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonClick)];
}

- (void)rightBarButtonClick{
    [YLRouterService openURL:kYLRouteURL_User_Set];
}

@end





@implementation UserSetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.yellowColor;
    self.navigationItem.title = @"个人设置";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"昵称设置" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonClick)];
}

- (void)rightBarButtonClick{
    [YLRouterService openURL:kYLRouteURL_User_Set_NickName];
}

@end




@implementation UserSetNickNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.blueColor;
    self.navigationItem.title = @"昵称设置";
}

@end
